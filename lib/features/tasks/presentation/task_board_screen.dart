import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/task_helpers.dart';
import '../domain/task_models.dart';
import '../providers/task_providers.dart';
import 'task_detail_screen.dart';
import 'task_form_screen.dart';
import 'widgets/task_tile.dart';

class TaskBoardScreen extends ConsumerStatefulWidget {
  const TaskBoardScreen({super.key});
  @override
  ConsumerState<TaskBoardScreen> createState() => _TaskBoardScreenState();
}

class _TaskBoardScreenState extends ConsumerState<TaskBoardScreen> {
  TaskFilter _filter = TaskFilter.all;

  Future<void> _add() => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const TaskFormScreen()),
  );

  @override
  Widget build(BuildContext context) {
    final tasks = ref.watch(filteredTasksProvider(_filter));
    return Scaffold(
      appBar: AppBar(title: const Text('Tasks')),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 4, 24, 16),
                  child: SegmentedButton<TaskFilter>(
                    showSelectedIcon: false,
                    expandedInsets: EdgeInsets.zero,
                    segments: const [
                      ButtonSegment(value: TaskFilter.all, label: Text('All')),
                      ButtonSegment(
                        value: TaskFilter.open,
                        label: Text('Open'),
                      ),
                      ButtonSegment(
                        value: TaskFilter.completed,
                        label: Text('Completed'),
                      ),
                    ],
                    selected: {_filter},
                    onSelectionChanged: (value) =>
                        setState(() => _filter = value.first),
                  ),
                ),
                Expanded(
                  child: tasks.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (_, _) => Center(
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            ref.invalidate(filteredTasksProvider(_filter)),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry loading tasks'),
                      ),
                    ),
                    data: (items) => items.isEmpty
                        ? _EmptyTasks(filter: _filter, onAdd: _add)
                        : LayoutBuilder(
                            builder: (context, constraints) {
                              final scale = MediaQuery.textScalerOf(
                                context,
                              ).scale(1);
                              final columns =
                                  constraints.maxWidth < 420 || scale > 1.3
                                  ? 1
                                  : constraints.maxWidth < 750
                                  ? 2
                                  : 3;
                              final tileWidth =
                                  (constraints.maxWidth -
                                      48 -
                                      (columns - 1) * 8) /
                                  columns;
                              return SingleChildScrollView(
                                key: const PageStorageKey('task-board'),
                                padding: const EdgeInsets.fromLTRB(
                                  24,
                                  4,
                                  24,
                                  96,
                                ),
                                child: Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: items.map((item) {
                                    return SizedBox(
                                      width: tileWidth,
                                      child: TaskTile(
                                        data: item,
                                        overdue: isTaskOverdue(
                                          isCompleted: item.task.isCompleted,
                                          deadline: item.task.deadline,
                                        ),
                                        onTap: () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => TaskDetailScreen(
                                              taskId: item.task.id,
                                            ),
                                          ),
                                        ),
                                        onToggle: () => ref
                                            .read(taskRepositoryProvider)
                                            .setCompleted(
                                              item.task,
                                              !item.task.isCompleted,
                                            ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              );
                            },
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'task_add',
        tooltip: 'Add task',
        onPressed: _add,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _EmptyTasks extends StatelessWidget {
  const _EmptyTasks({required this.filter, required this.onAdd});
  final TaskFilter filter;
  final VoidCallback onAdd;
  @override
  Widget build(BuildContext context) {
    final title = switch (filter) {
      TaskFilter.all => 'Nothing to do.',
      TaskFilter.open => 'No open tasks',
      TaskFilter.completed => 'No completed tasks',
    };
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.task_alt, size: 48),
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              filter == TaskFilter.completed
                  ? 'Completed tasks will collect here.'
                  : 'Create a task to get started.',
              textAlign: TextAlign.center,
            ),
            if (filter != TaskFilter.completed) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add),
                label: const Text('Add task'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
