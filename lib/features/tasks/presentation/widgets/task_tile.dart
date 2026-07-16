import 'package:flutter/material.dart';

import '../../domain/task_colors.dart';
import '../../domain/task_helpers.dart';
import '../../domain/task_models.dart';

class TaskTile extends StatelessWidget {
  const TaskTile({
    super.key,
    required this.data,
    required this.overdue,
    required this.onTap,
    required this.onToggle,
  });

  final TaskWithChecklist data;
  final bool overdue;
  final VoidCallback onTap;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final task = data.task;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: task.isCompleted ? .72 : 1,
      child: Card(
        color: TaskColors.resolve(task.colorValue),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        task.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              decoration: task.isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                      ),
                    ),
                    IconButton(
                      tooltip: task.isCompleted
                          ? 'Reopen task'
                          : 'Mark task complete',
                      onPressed: onToggle,
                      icon: Icon(
                        task.isCompleted
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                      ),
                    ),
                  ],
                ),
                if (task.description != null)
                  Text(
                    task.description!,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (task.deadline != null) ...[
                  const SizedBox(height: 8),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: overdue
                          ? Theme.of(
                              context,
                            ).colorScheme.error.withValues(alpha: .1)
                          : Theme.of(
                              context,
                            ).colorScheme.surface.withValues(alpha: .55),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            overdue
                                ? Icons.warning_amber_rounded
                                : Icons.event_outlined,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '${overdue ? 'Overdue • ' : ''}${formatTaskDeadline(context, task.deadline!)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                if (data.items.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  ...data.items
                      .take(3)
                      .map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              Icon(
                                item.isCompleted
                                    ? Icons.check_box
                                    : Icons.check_box_outline_blank,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  item.itemText,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  if (data.items.length > 3)
                    Text(
                      '+${data.items.length - 3} more',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  const SizedBox(height: 8),
                  Text(
                    '${data.completedCount} of ${data.totalCount} complete',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                if (task.isCompleted) ...[
                  const SizedBox(height: 8),
                  const Row(
                    children: [
                      Icon(Icons.check_circle_outline, size: 18),
                      SizedBox(width: 6),
                      Text(
                        'Completed',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
