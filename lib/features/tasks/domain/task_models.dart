import '../../../core/database/app_database.dart';

enum TaskFilter { all, open, completed }

class TaskWithChecklist {
  const TaskWithChecklist(this.task, this.items);
  final Task task;
  final List<ChecklistItem> items;
  int get completedCount => items.where((item) => item.isCompleted).length;
  int get totalCount => items.length;
}

class ChecklistDraft {
  const ChecklistDraft({
    required this.id,
    required this.text,
    this.isCompleted = false,
  });
  final String id;
  final String text;
  final bool isCompleted;
}

class TaskFormData {
  const TaskFormData({
    required this.title,
    this.description,
    this.deadline,
    this.colorValue,
    this.checklist = const [],
  });
  final String title;
  final String? description;
  final DateTime? deadline;
  final int? colorValue;
  final List<ChecklistDraft> checklist;
}
