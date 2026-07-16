import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/task_colors.dart';
import '../domain/task_helpers.dart';
import '../domain/task_models.dart';
import '../providers/task_providers.dart';
import 'task_form_screen.dart';

class TaskDetailScreen extends ConsumerWidget {
  const TaskDetailScreen({super.key, required this.taskId});
  final String taskId;

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    TaskWithChecklist data,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete task?'),
        content: Text(
          'Delete “${data.task.title}” and all of its checklist items? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await ref.read(taskRepositoryProvider).deleteTask(data.task.id);
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Task deleted.')));
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not delete this task.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(taskWithChecklistProvider(taskId))
      .when(
        loading: () =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (_, _) => Scaffold(
          appBar: AppBar(),
          body: const Center(child: Text('Could not load this task.')),
        ),
        data: (data) {
          if (data == null) {
            return Scaffold(
              appBar: AppBar(),
              body: const Center(child: Text('This task no longer exists.')),
            );
          }
          final task = data.task;
          final overdue = isTaskOverdue(
            isCompleted: task.isCompleted,
            deadline: task.deadline,
          );
          return Scaffold(
            appBar: AppBar(
              title: const Text('Task details'),
              actions: [
                IconButton(
                  tooltip: 'Edit task',
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TaskFormScreen(existing: data),
                    ),
                  ),
                  icon: const Icon(Icons.edit_outlined),
                ),
                IconButton(
                  tooltip: 'Delete task',
                  onPressed: () => _delete(context, ref, data),
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
            body: SafeArea(
              top: false,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 700),
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: TaskColors.resolve(task.colorValue),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        task.title,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      if (task.description != null) ...[
                        const SizedBox(height: 12),
                        Text(task.description!),
                      ],
                      const SizedBox(height: 16),
                      if (task.deadline != null)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            overdue ? Icons.warning_amber : Icons.event,
                          ),
                          title: Text(
                            formatTaskDeadline(context, task.deadline!),
                          ),
                          subtitle: overdue ? const Text('Overdue') : null,
                        ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          task.isCompleted
                              ? Icons.check_circle
                              : Icons.pending_outlined,
                        ),
                        title: Text(task.isCompleted ? 'Completed' : 'Open'),
                      ),
                      FilledButton.icon(
                        onPressed: () async {
                          await ref
                              .read(taskRepositoryProvider)
                              .setCompleted(task, !task.isCompleted);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  task.isCompleted
                                      ? 'Task reopened.'
                                      : 'Task completed.',
                                ),
                              ),
                            );
                          }
                        },
                        icon: Icon(
                          task.isCompleted ? Icons.refresh : Icons.check,
                        ),
                        label: Text(
                          task.isCompleted ? 'Reopen task' : 'Mark complete',
                        ),
                      ),
                      if (data.items.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        Text(
                          'Checklist',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${data.completedCount} of ${data.totalCount} complete',
                        ),
                        LinearProgressIndicator(
                          value: data.totalCount == 0
                              ? 0
                              : data.completedCount / data.totalCount,
                        ),
                        const SizedBox(height: 8),
                        ...data.items.map(
                          (item) => CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            value: item.isCompleted,
                            controlAffinity: ListTileControlAffinity.leading,
                            title: Text(
                              item.itemText,
                              style: TextStyle(
                                decoration: item.isCompleted
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                            onChanged: (_) async {
                              try {
                                await ref
                                    .read(taskRepositoryProvider)
                                    .toggleChecklist(item);
                              } catch (_) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Could not update checklist item.',
                                      ),
                                    ),
                                  );
                                }
                              }
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
}
