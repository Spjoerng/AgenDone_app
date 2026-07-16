import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:schedule_app/core/database/app_database.dart';
import 'package:schedule_app/features/tasks/data/task_repository.dart';
import 'package:schedule_app/features/tasks/domain/task_helpers.dart';
import 'package:schedule_app/features/tasks/domain/task_models.dart';

void main() {
  late AppDatabase database;
  late TaskRepository repository;
  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    repository = TaskRepository(database);
  });
  tearDown(() => database.close());

  TaskFormData form(
    String title, {
    DateTime? deadline,
    List<ChecklistDraft> items = const [],
  }) => TaskFormData(title: title, deadline: deadline, checklist: items);

  test('creates a task without checklist items', () async {
    final id = await repository.create(form('Task'));
    expect((await repository.getTask(id))?.title, 'Task');
    expect(await repository.fetchChecklist(id), isEmpty);
  });
  test('creates a task with ordered checklist items', () async {
    final id = await repository.create(
      form(
        'Task',
        items: const [
          ChecklistDraft(id: 'b', text: 'Second'),
          ChecklistDraft(id: 'a', text: 'First'),
        ],
      ),
    );
    expect((await repository.fetchChecklist(id)).map((e) => e.itemText), [
      'Second',
      'First',
    ]);
  });
  test('updates task fields and removes checklist items', () async {
    final id = await repository.create(
      form(
        'Old',
        items: const [
          ChecklistDraft(id: 'a', text: 'Keep'),
          ChecklistDraft(id: 'b', text: 'Remove'),
        ],
      ),
    );
    final task = (await repository.getTask(id))!;
    final deadline = DateTime(2027, 1, 2);
    await repository.updateTask(
      task,
      TaskFormData(
        title: 'New',
        description: 'Details',
        deadline: deadline,
        colorValue: 123,
        checklist: const [ChecklistDraft(id: 'a', text: 'Keep')],
      ),
    );
    final updated = (await repository.getTask(id))!;
    expect(
      [updated.title, updated.description, updated.colorValue],
      ['New', 'Details', 123],
    );
    expect(updated.deadline, deadline);
    expect(await repository.fetchChecklist(id), hasLength(1));
  });
  test('updates checklist text and completion', () async {
    final id = await repository.create(
      form(
        'Task',
        items: const [ChecklistDraft(id: 'a', text: 'Old')],
      ),
    );
    var item = (await repository.fetchChecklist(id)).single;
    await repository.updateChecklistText(item.id, 'New');
    item = (await repository.fetchChecklist(id)).single;
    expect(item.itemText, 'New');
    await repository.toggleChecklist(item);
    expect((await repository.fetchChecklist(id)).single.isCompleted, isTrue);
  });
  test('reorders checklist items contiguously', () async {
    final id = await repository.create(
      form(
        'Task',
        items: const [
          ChecklistDraft(id: 'a', text: 'A'),
          ChecklistDraft(id: 'b', text: 'B'),
        ],
      ),
    );
    final items = await repository.fetchChecklist(id);
    await repository.reorderChecklist(id, items.reversed.toList());
    final reordered = await repository.fetchChecklist(id);
    expect(reordered.map((e) => e.itemText), ['B', 'A']);
    expect(reordered.map((e) => e.position), [0, 1]);
  });
  test('cascade deletes checklist items', () async {
    final id = await repository.create(
      form(
        'Task',
        items: const [ChecklistDraft(id: 'a', text: 'A')],
      ),
    );
    await repository.deleteTask(id);
    expect(await repository.fetchChecklist(id), isEmpty);
  });
  test('complete and reopen set completedAt correctly', () async {
    final id = await repository.create(form('Task'));
    var task = (await repository.getTask(id))!;
    await repository.setCompleted(task, true);
    task = (await repository.getTask(id))!;
    expect(task.completedAt, isNotNull);
    await repository.setCompleted(task, false);
    expect((await repository.getTask(id))!.completedAt, isNull);
  });
  test('open tasks order by deadline with undated last', () async {
    await repository.create(form('Undated'));
    await repository.create(form('Later', deadline: DateTime(2027, 2)));
    await repository.create(form('Earlier', deadline: DateTime(2027, 1)));
    expect(
      (await repository.watchTasks(TaskFilter.open).first).map(
        (e) => e.task.title,
      ),
      ['Earlier', 'Later', 'Undated'],
    );
  });
  test('completed ordering uses most recent completedAt', () async {
    final a = await repository.create(form('Older'));
    final b = await repository.create(form('Newer'));
    await (database.update(
      database.tasks,
    )..where((row) => row.id.equals(a))).write(
      TasksCompanion(
        isCompleted: const Value(true),
        completedAt: Value(DateTime(2026, 1, 1)),
      ),
    );
    await (database.update(
      database.tasks,
    )..where((row) => row.id.equals(b))).write(
      TasksCompanion(
        isCompleted: const Value(true),
        completedAt: Value(DateTime(2026, 2, 1)),
      ),
    );
    expect(
      (await repository.watchTasks(TaskFilter.completed).first).map(
        (e) => e.task.title,
      ),
      ['Newer', 'Older'],
    );
  });
  test('all tasks place open before completed', () async {
    final done = await repository.create(form('Done'));
    await repository.setCompleted((await repository.getTask(done))!, true);
    await repository.create(form('Open'));
    expect(
      (await repository.watchTasks(TaskFilter.all).first).map(
        (e) => e.task.title,
      ),
      ['Open', 'Done'],
    );
  });
  test('date-only deadline uses local end of day', () {
    final value = dateOnlyDeadline(DateTime(2026, 7, 21));
    expect([value.hour, value.minute, value.second], [23, 59, 59]);
  });
  test('overdue excludes completed tasks', () {
    final past = DateTime(2026, 1, 1);
    final now = DateTime(2026, 1, 2);
    expect(isTaskOverdue(isCompleted: false, deadline: past, now: now), isTrue);
    expect(isTaskOverdue(isCompleted: true, deadline: past, now: now), isFalse);
  });
}
