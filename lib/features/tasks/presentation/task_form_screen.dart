import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../domain/task_colors.dart';
import '../domain/task_helpers.dart';
import '../domain/task_models.dart';
import '../providers/task_providers.dart';

class TaskFormScreen extends ConsumerStatefulWidget {
  const TaskFormScreen({super.key, this.existing, this.initialDeadline});
  final TaskWithChecklist? existing;
  final DateTime? initialDeadline;
  @override
  ConsumerState<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _DraftRow {
  _DraftRow({required this.id, required String text, this.completed = false})
    : controller = TextEditingController(text: text);
  final String id;
  final TextEditingController controller;
  final bool completed;
}

class _TaskFormScreenState extends ConsumerState<TaskFormScreen> {
  final _key = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _description;
  late List<_DraftRow> _rows;
  DateTime? _deadline;
  bool _deadlineHasTime = false;
  int? _color;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final data = widget.existing;
    _title = TextEditingController(text: data?.task.title);
    _description = TextEditingController(text: data?.task.description);
    _deadline = data?.task.deadline ?? widget.initialDeadline;
    _deadlineHasTime =
        _deadline != null &&
        !(_deadline!.hour == 23 &&
            _deadline!.minute == 59 &&
            _deadline!.second == 59);
    _color = data?.task.colorValue ?? TaskColors.values.first.toARGB32();
    _rows =
        data?.items
            .map(
              (item) => _DraftRow(
                id: item.id,
                text: item.itemText,
                completed: item.isCompleted,
              ),
            )
            .toList() ??
        [];
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    for (final row in _rows) {
      row.controller.dispose();
    }
    super.dispose();
  }

  void _addRow() =>
      setState(() => _rows.add(_DraftRow(id: const Uuid().v4(), text: '')));
  void _removeRow(int index) {
    final row = _rows.removeAt(index);
    row.controller.dispose();
    setState(() {});
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 20),
      initialDate: _deadline ?? now,
    );
    if (date != null && mounted) {
      setState(
        () => _deadline = _deadlineHasTime
            ? DateTime(
                date.year,
                date.month,
                date.day,
                _deadline?.hour ?? 9,
                _deadline?.minute ?? 0,
              )
            : dateOnlyDeadline(date),
      );
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _deadlineHasTime && _deadline != null
          ? TimeOfDay.fromDateTime(_deadline!)
          : const TimeOfDay(hour: 9, minute: 0),
    );
    if (picked != null && mounted) {
      final date = _deadline ?? DateTime.now();
      setState(() {
        _deadlineHasTime = true;
        _deadline = DateTime(
          date.year,
          date.month,
          date.day,
          picked.hour,
          picked.minute,
        );
      });
    }
  }

  Future<void> _save() async {
    if (!_key.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final checklist = _rows
          .where((row) => row.controller.text.trim().isNotEmpty)
          .map(
            (row) => ChecklistDraft(
              id: row.id,
              text: row.controller.text.trim(),
              isCompleted: row.completed,
            ),
          )
          .toList();
      final description = _description.text.trim();
      final data = TaskFormData(
        title: _title.text.trim(),
        description: description.isEmpty ? null : description,
        deadline: _deadline,
        colorValue: _color,
        checklist: checklist,
      );
      final repository = ref.read(taskRepositoryProvider);
      if (widget.existing == null) {
        await repository.create(data);
      } else {
        await repository.updateTask(widget.existing!.task, data);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not save this task. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.existing == null ? 'Add task' : 'Edit task'),
    ),
    body: SafeArea(
      top: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: Form(
            key: _key,
            child: CustomScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  sliver: SliverList.list(
                    children: [
                      TextFormField(
                        controller: _title,
                        autofocus: widget.existing == null,
                        decoration: const InputDecoration(labelText: 'Title'),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'Enter a title'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _description,
                        minLines: 3,
                        maxLines: 6,
                        decoration: const InputDecoration(
                          labelText: 'Description (optional)',
                          alignLabelWithHint: true,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _deadline == null
                                    ? 'No deadline'
                                    : formatTaskDeadline(context, _deadline!),
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              Wrap(
                                spacing: 8,
                                children: [
                                  TextButton.icon(
                                    onPressed: _pickDate,
                                    icon: const Icon(Icons.event),
                                    label: Text(
                                      _deadline == null
                                          ? 'Add date'
                                          : 'Change date',
                                    ),
                                  ),
                                  if (_deadline != null)
                                    TextButton.icon(
                                      onPressed: _pickTime,
                                      icon: const Icon(Icons.schedule),
                                      label: const Text('Add/change time'),
                                    ),
                                  if (_deadline != null)
                                    TextButton.icon(
                                      onPressed: () => setState(() {
                                        _deadline = null;
                                        _deadlineHasTime = false;
                                      }),
                                      icon: const Icon(Icons.close),
                                      label: const Text('Remove'),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Tile color',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 12,
                        children: TaskColors.values
                            .map(
                              (color) => Semantics(
                                label: 'Select task color',
                                selected: _color == color.toARGB32(),
                                child: InkWell(
                                  onTap: () =>
                                      setState(() => _color = color.toARGB32()),
                                  child: Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: color,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: _color == color.toARGB32()
                                            ? Theme.of(
                                                context,
                                              ).colorScheme.onSurface
                                            : Colors.transparent,
                                        width: 3,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Checklist',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: _addRow,
                            icon: const Icon(Icons.add),
                            label: const Text('Add item'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SliverReorderableList(
                  itemCount: _rows.length,
                  onReorderItem: (oldIndex, newIndex) => setState(() {
                    final row = _rows.removeAt(oldIndex);
                    _rows.insert(newIndex, row);
                  }),
                  itemBuilder: (context, index) {
                    final row = _rows[index];
                    return Material(
                      key: ValueKey(row.id),
                      color: Colors.transparent,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        child: Row(
                          children: [
                            ReorderableDragStartListener(
                              index: index,
                              child: const SizedBox(
                                width: 48,
                                height: 48,
                                child: Icon(Icons.drag_handle),
                              ),
                            ),
                            Expanded(
                              child: TextField(
                                controller: row.controller,
                                decoration: InputDecoration(
                                  labelText: 'Checklist item ${index + 1}',
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: 'Remove checklist item',
                              onPressed: () => _removeRow(index),
                              icon: const Icon(Icons.remove_circle_outline),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverToBoxAdapter(
                    child: FilledButton.icon(
                      onPressed: _saving ? null : _save,
                      icon: const Icon(Icons.save),
                      label: Text(
                        widget.existing == null ? 'Save task' : 'Save changes',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
