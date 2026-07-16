import 'dart:async';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../domain/task_models.dart';

class TaskRepository {
  TaskRepository(this.database);
  final AppDatabase database;

  Stream<List<TaskWithChecklist>> watchTasks(TaskFilter filter) {
    final query = database.select(database.tasks);
    if (filter == TaskFilter.open) {
      query.where((row) => row.isCompleted.equals(false));
    }
    if (filter == TaskFilter.completed) {
      query.where((row) => row.isCompleted.equals(true));
    }
    return _merge(
      query.watch().map<void>((_) {}),
      database.select(database.checklistItems).watch().map<void>((_) {}),
    ).asyncMap((_) async {
      final tasks = await query.get();
      final results = <TaskWithChecklist>[];
      for (final task in tasks) {
        results.add(TaskWithChecklist(task, await fetchChecklist(task.id)));
      }
      results.sort(_compare);
      return results;
    });
  }

  Stream<TaskWithChecklist?> watchTask(String id) {
    final taskQuery = database.select(database.tasks)
      ..where((row) => row.id.equals(id));
    final itemQuery = database.select(database.checklistItems)
      ..where((row) => row.taskId.equals(id));
    return _merge(
      taskQuery.watch().map<void>((_) {}),
      itemQuery.watch().map<void>((_) {}),
    ).asyncMap((_) async {
      final task = await taskQuery.getSingleOrNull();
      return task == null
          ? null
          : TaskWithChecklist(task, await fetchChecklist(id));
    });
  }

  Stream<void> _merge(Stream<void> first, Stream<void> second) {
    late StreamController<void> controller;
    StreamSubscription<void>? a;
    StreamSubscription<void>? b;
    controller = StreamController<void>(
      onListen: () {
        a = first.listen(controller.add, onError: controller.addError);
        b = second.listen(controller.add, onError: controller.addError);
      },
      onCancel: () async {
        await a?.cancel();
        await b?.cancel();
      },
    );
    return controller.stream;
  }

  Future<Task?> getTask(String id) => (database.select(
    database.tasks,
  )..where((row) => row.id.equals(id))).getSingleOrNull();
  Stream<List<ChecklistItem>> watchChecklist(String taskId) =>
      (database.select(database.checklistItems)
            ..where((row) => row.taskId.equals(taskId))
            ..orderBy([(row) => OrderingTerm.asc(row.position)]))
          .watch();
  Future<List<ChecklistItem>> fetchChecklist(String taskId) =>
      (database.select(database.checklistItems)
            ..where((row) => row.taskId.equals(taskId))
            ..orderBy([(row) => OrderingTerm.asc(row.position)]))
          .get();

  Future<String> create(TaskFormData data) => database.transaction(() async {
    final id = const Uuid().v4();
    final now = DateTime.now();
    await database
        .into(database.tasks)
        .insert(
          TasksCompanion.insert(
            id: id,
            title: data.title,
            description: Value(data.description),
            deadline: Value(data.deadline),
            colorValue: Value(data.colorValue),
            createdAt: now,
            updatedAt: now,
          ),
        );
    await _replaceChecklist(id, data.checklist, now);
    return id;
  });

  Future<void> updateTask(Task task, TaskFormData data) =>
      database.transaction(() async {
        await database
            .update(database.tasks)
            .replace(
              task.copyWith(
                title: data.title,
                description: Value(data.description),
                deadline: Value(data.deadline),
                colorValue: Value(data.colorValue),
                updatedAt: DateTime.now(),
              ),
            );
        await (database.delete(
          database.checklistItems,
        )..where((row) => row.taskId.equals(task.id))).go();
        await _replaceChecklist(task.id, data.checklist, DateTime.now());
      });

  Future<void> _replaceChecklist(
    String taskId,
    List<ChecklistDraft> items,
    DateTime now,
  ) async {
    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      await database
          .into(database.checklistItems)
          .insert(
            ChecklistItemsCompanion.insert(
              id: item.id,
              taskId: taskId,
              itemText: item.text,
              isCompleted: Value(item.isCompleted),
              position: i,
              createdAt: now,
              updatedAt: now,
            ),
          );
    }
  }

  Future<void> updateChecklistText(String id, String text) =>
      (database.update(
        database.checklistItems,
      )..where((row) => row.id.equals(id))).write(
        ChecklistItemsCompanion(
          itemText: Value(text.trim()),
          updatedAt: Value(DateTime.now()),
        ),
      );
  Future<void> toggleChecklist(ChecklistItem item) =>
      (database.update(
        database.checklistItems,
      )..where((row) => row.id.equals(item.id))).write(
        ChecklistItemsCompanion(
          isCompleted: Value(!item.isCompleted),
          updatedAt: Value(DateTime.now()),
        ),
      );
  Future<void> deleteChecklist(String id) => (database.delete(
    database.checklistItems,
  )..where((row) => row.id.equals(id))).go();
  Future<void> reorderChecklist(String taskId, List<ChecklistItem> items) =>
      database.transaction(() async {
        await (database.delete(
          database.checklistItems,
        )..where((row) => row.taskId.equals(taskId))).go();
        await _replaceChecklist(
          taskId,
          items
              .map(
                (e) => ChecklistDraft(
                  id: e.id,
                  text: e.itemText,
                  isCompleted: e.isCompleted,
                ),
              )
              .toList(),
          DateTime.now(),
        );
      });
  Future<void> deleteTask(String id) =>
      (database.delete(database.tasks)..where((row) => row.id.equals(id))).go();
  Future<void> setCompleted(Task task, bool completed) =>
      (database.update(
        database.tasks,
      )..where((row) => row.id.equals(task.id))).write(
        TasksCompanion(
          isCompleted: Value(completed),
          completedAt: Value(completed ? DateTime.now() : null),
          updatedAt: Value(DateTime.now()),
        ),
      );

  int _compare(TaskWithChecklist a, TaskWithChecklist b) {
    final x = a.task, y = b.task;
    if (x.isCompleted != y.isCompleted) return x.isCompleted ? 1 : -1;
    if (x.isCompleted) {
      return (y.completedAt ?? y.updatedAt).compareTo(
        x.completedAt ?? x.updatedAt,
      );
    }
    if (x.deadline == null && y.deadline != null) return 1;
    if (x.deadline != null && y.deadline == null) return -1;
    if (x.deadline != null && y.deadline != null) {
      final value = x.deadline!.compareTo(y.deadline!);
      if (value != 0) return value;
    }
    return y.updatedAt.compareTo(x.updatedAt);
  }
}
