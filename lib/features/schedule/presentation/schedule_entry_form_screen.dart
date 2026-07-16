import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../domain/schedule_colors.dart';
import '../domain/schedule_entry_form_data.dart';
import '../domain/schedule_formatters.dart';
import '../providers/schedule_providers.dart';

class ScheduleEntryFormScreen extends ConsumerStatefulWidget {
  const ScheduleEntryFormScreen({
    super.key,
    required this.initialWeekday,
    this.entry,
  });
  final int initialWeekday;
  final ScheduleEntry? entry;

  @override
  ConsumerState<ScheduleEntryFormScreen> createState() =>
      _ScheduleEntryFormScreenState();
}

class _ScheduleEntryFormScreenState
    extends ConsumerState<ScheduleEntryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _location;
  late final TextEditingController _notes;
  late int _weekday;
  late int _start;
  late int _end;
  int? _color;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final entry = widget.entry;
    _title = TextEditingController(text: entry?.title);
    _location = TextEditingController(text: entry?.location);
    _notes = TextEditingController(text: entry?.notes);
    _weekday = entry?.weekday ?? widget.initialWeekday;
    _start = entry?.startMinutes ?? 9 * 60;
    _end = entry?.endMinutes ?? 10 * 60;
    _color = entry?.colorValue ?? ScheduleColors.values.first.toARGB32();
  }

  @override
  void dispose() {
    _title.dispose();
    _location.dispose();
    _notes.dispose();
    super.dispose();
  }

  String? _optional(String value) => value.trim().isEmpty ? null : value.trim();

  Future<void> _pickTime({required bool start}) async {
    final current = start ? _start : _end;
    final picked = await showTimePicker(
      context: context,
      initialTime: minutesToTimeOfDay(current),
    );
    if (picked != null && mounted) {
      setState(
        () => start
            ? _start = timeOfDayToMinutes(picked)
            : _end = timeOfDayToMinutes(picked),
      );
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_start >= _end) {
      setState(() {});
      return;
    }
    setState(() => _saving = true);
    try {
      final repository = ref.read(scheduleRepositoryProvider);
      final conflicts = await repository.findConflicts(
        weekday: _weekday,
        startMinutes: _start,
        endMinutes: _end,
        excludeId: widget.entry?.id,
      );
      if (!mounted) return;
      if (conflicts.isNotEmpty) {
        final proceed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Schedule conflict'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('This entry overlaps another schedule item:'),
                const SizedBox(height: 12),
                ...conflicts.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      '• ${entry.title} — ${formatTimeRange(context, entry.startMinutes, entry.endMinutes)}',
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Go Back'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Save Anyway'),
              ),
            ],
          ),
        );
        if (proceed != true) return;
      }
      final data = ScheduleEntryFormData(
        title: _title.text.trim(),
        weekday: _weekday,
        startMinutes: _start,
        endMinutes: _end,
        location: _optional(_location.text),
        notes: _optional(_notes.text),
        colorValue: _color,
      );
      if (widget.entry == null) {
        await repository.insert(data);
      } else {
        await repository.updateEntry(widget.entry!, data);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not save this entry. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.entry != null;
    return Scaffold(
      appBar: AppBar(title: Text(editing ? 'Edit entry' : 'Add entry')),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Form(
              key: _formKey,
              child: ListView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.all(16),
                children: [
                  TextFormField(
                    controller: _title,
                    autofocus: !editing,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      prefixIcon: Icon(Icons.title),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Enter a title'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    initialValue: _weekday,
                    decoration: const InputDecoration(
                      labelText: 'Day',
                      prefixIcon: Icon(Icons.today),
                    ),
                    items: List.generate(
                      7,
                      (index) => DropdownMenuItem(
                        value: index + 1,
                        child: Text(weekdayNames[index]),
                      ),
                    ),
                    onChanged: (value) => setState(() => _weekday = value!),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _TimeField(
                          label: 'Start time',
                          minutes: _start,
                          onTap: () => _pickTime(start: true),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _TimeField(
                          label: 'End time',
                          minutes: _end,
                          onTap: () => _pickTime(start: false),
                        ),
                      ),
                    ],
                  ),
                  if (_start >= _end)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        'End time must be after start time',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _location,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Location (optional)',
                      prefixIcon: Icon(Icons.place_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _notes,
                    minLines: 3,
                    maxLines: 6,
                    decoration: const InputDecoration(
                      labelText: 'Notes (optional)',
                      alignLabelWithHint: true,
                      prefixIcon: Icon(Icons.notes),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('Color', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: ScheduleColors.values.map((color) {
                      final selected = _color == color.toARGB32();
                      return Semantics(
                        label: 'Select entry color',
                        selected: selected,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(24),
                          onTap: () =>
                              setState(() => _color = color.toARGB32()),
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: selected
                                    ? Theme.of(context).colorScheme.onSurface
                                    : Colors.transparent,
                                width: 3,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 28),
                  FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save),
                    label: Text(editing ? 'Save changes' : 'Save entry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TimeField extends StatelessWidget {
  const _TimeField({
    required this.label,
    required this.minutes,
    required this.onTap,
  });
  final String label;
  final int minutes;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.schedule),
      ),
      child: Text(formatMinutes(context, minutes)),
    ),
  );
}
