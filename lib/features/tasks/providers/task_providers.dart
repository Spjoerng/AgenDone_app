import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database_provider.dart';
import '../data/task_repository.dart';
import '../domain/task_models.dart';

final taskRepositoryProvider = Provider<TaskRepository>(
  (ref) => TaskRepository(ref.watch(databaseProvider)),
);
final filteredTasksProvider =
    StreamProvider.family<List<TaskWithChecklist>, TaskFilter>(
      (ref, filter) => ref.watch(taskRepositoryProvider).watchTasks(filter),
    );
final taskWithChecklistProvider =
    StreamProvider.family<TaskWithChecklist?, String>(
      (ref, id) => ref.watch(taskRepositoryProvider).watchTask(id),
    );
