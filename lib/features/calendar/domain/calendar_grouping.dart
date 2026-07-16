import '../../tasks/domain/task_models.dart';

DateTime normalizeLocalDate(DateTime value) =>
    DateTime(value.year, value.month, value.day);

Map<DateTime, List<TaskWithChecklist>> groupTasksByDeadline(
  Iterable<TaskWithChecklist> tasks,
) {
  final groups = <DateTime, List<TaskWithChecklist>>{};
  for (final data in tasks) {
    final deadline = data.task.deadline;
    if (deadline == null) continue;
    groups.putIfAbsent(normalizeLocalDate(deadline), () => []).add(data);
  }
  for (final entries in groups.values) {
    entries.sort(compareCalendarTasks);
  }
  return groups;
}

int compareCalendarTasks(TaskWithChecklist a, TaskWithChecklist b) {
  if (a.task.isCompleted != b.task.isCompleted) {
    return a.task.isCompleted ? 1 : -1;
  }
  final deadlineComparison = a.task.deadline!.compareTo(b.task.deadline!);
  if (deadlineComparison != 0) return deadlineComparison;
  if (a.task.isCompleted && b.task.isCompleted) {
    return (b.task.completedAt ?? b.task.updatedAt).compareTo(
      a.task.completedAt ?? a.task.updatedAt,
    );
  }
  return b.task.updatedAt.compareTo(a.task.updatedAt);
}
