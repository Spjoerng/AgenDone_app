import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../tasks/domain/task_models.dart';
import '../../tasks/providers/task_providers.dart';
import '../domain/calendar_grouping.dart';

final deadlineTasksProvider = StreamProvider<List<TaskWithChecklist>>(
  (ref) => ref
      .watch(taskRepositoryProvider)
      .watchTasks(TaskFilter.all)
      .map(
        (tasks) => tasks.where((data) => data.task.deadline != null).toList(),
      ),
);

final calendarTaskGroupsProvider =
    Provider<AsyncValue<Map<DateTime, List<TaskWithChecklist>>>>(
      (ref) => ref.watch(deadlineTasksProvider).whenData(groupTasksByDeadline),
    );
