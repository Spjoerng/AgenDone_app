import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:schedule_app/core/database/app_database.dart';
import 'package:schedule_app/features/calendar/domain/calendar_grouping.dart';
import 'package:schedule_app/features/tasks/data/task_repository.dart';
import 'package:schedule_app/features/tasks/domain/task_helpers.dart';
import 'package:schedule_app/features/tasks/domain/task_models.dart';

void main() {
  TaskWithChecklist data(
    String id, {
    DateTime? deadline,
    bool completed = false,
  }) {
    final now = DateTime(2026, 7, 1);
    return TaskWithChecklist(
      Task(
        id: id,
        title: id,
        deadline: deadline,
        isCompleted: completed,
        createdAt: now,
        updatedAt: now,
        completedAt: completed ? now : null,
      ),
      const [],
    );
  }

  test('normalizes and groups different times on the same local date', () {
    final groups = groupTasksByDeadline([
      data('early', deadline: DateTime(2026, 7, 21, 0, 1)),
      data('late', deadline: DateTime(2026, 7, 21, 23, 59)),
    ]);
    expect(groups, hasLength(1));
    expect(groups[DateTime(2026, 7, 21)], hasLength(2));
  });
  test('adjacent dates remain separate and undated tasks are excluded', () {
    final groups = groupTasksByDeadline([
      data('one', deadline: DateTime(2026, 7, 21)),
      data('two', deadline: DateTime(2026, 7, 22)),
      data('none'),
    ]);
    expect(
      groups.keys,
      containsAll([DateTime(2026, 7, 21), DateTime(2026, 7, 22)]),
    );
    expect(groups.values.expand((e) => e), hasLength(2));
  });
  test('count per date is correct', () {
    final groups = groupTasksByDeadline([
      data('a', deadline: DateTime(2026, 8, 2)),
      data('b', deadline: DateTime(2026, 8, 2)),
    ]);
    expect(groups[DateTime(2026, 8, 2)]!.length, 2);
  });
  test('selected-day ordering places open before completed', () {
    final groups = groupTasksByDeadline([
      data('done', deadline: DateTime(2026, 8, 2, 9), completed: true),
      data('open', deadline: DateTime(2026, 8, 2, 10)),
    ]);
    expect(groups[DateTime(2026, 8, 2)]!.map((e) => e.task.title), [
      'open',
      'done',
    ]);
  });
  test('calendar overdue behavior matches task helper', () {
    expect(
      isTaskOverdue(
        isCompleted: false,
        deadline: DateTime(2026, 1),
        now: DateTime(2026, 2),
      ),
      isTrue,
    );
    expect(
      isTaskOverdue(
        isCompleted: true,
        deadline: DateTime(2026, 1),
        now: DateTime(2026, 2),
      ),
      isFalse,
    );
  });

  group('reactive deadline changes', () {
    late AppDatabase database;
    late TaskRepository repository;
    setUp(() {
      database = AppDatabase.forTesting(NativeDatabase.memory());
      repository = TaskRepository(database);
    });
    tearDown(() => database.close());

    test('adding a deadline task updates groups', () async {
      final stream = repository
          .watchTasks(TaskFilter.all)
          .map(groupTasksByDeadline);
      final update = stream.firstWhere(
        (groups) => groups.containsKey(DateTime(2026, 7, 21)),
      );
      await repository.create(
        TaskFormData(
          title: 'Task',
          deadline: dateOnlyDeadline(DateTime(2026, 7, 21)),
        ),
      );
      expect(await update, contains(DateTime(2026, 7, 21)));
    });
    test('moving a deadline moves its date group', () async {
      final id = await repository.create(
        TaskFormData(
          title: 'Task',
          deadline: dateOnlyDeadline(DateTime(2026, 7, 21)),
        ),
      );
      final task = (await repository.getTask(id))!;
      await repository.updateTask(
        task,
        TaskFormData(
          title: 'Task',
          deadline: dateOnlyDeadline(DateTime(2026, 7, 22)),
        ),
      );
      final groups = groupTasksByDeadline(
        await repository.watchTasks(TaskFilter.all).first,
      );
      expect(groups.containsKey(DateTime(2026, 7, 21)), isFalse);
      expect(groups.containsKey(DateTime(2026, 7, 22)), isTrue);
    });
    test('deleting removes deadline task', () async {
      final id = await repository.create(
        TaskFormData(
          title: 'Task',
          deadline: dateOnlyDeadline(DateTime(2026, 7, 21)),
        ),
      );
      await repository.deleteTask(id);
      expect(
        groupTasksByDeadline(await repository.watchTasks(TaskFilter.all).first),
        isEmpty,
      );
    });
    test('completion and reopening update grouped status', () async {
      final id = await repository.create(
        TaskFormData(
          title: 'Task',
          deadline: dateOnlyDeadline(DateTime(2026, 7, 21)),
        ),
      );
      var task = (await repository.getTask(id))!;
      await repository.setCompleted(task, true);
      var grouped = groupTasksByDeadline(
        await repository.watchTasks(TaskFilter.all).first,
      );
      expect(grouped.values.single.single.task.isCompleted, isTrue);
      task = (await repository.getTask(id))!;
      await repository.setCompleted(task, false);
      grouped = groupTasksByDeadline(
        await repository.watchTasks(TaskFilter.all).first,
      );
      expect(grouped.values.single.single.task.isCompleted, isFalse);
    });
  });
}
