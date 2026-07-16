import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../domain/schedule_colors.dart';
import '../domain/schedule_formatters.dart';
import '../providers/schedule_providers.dart';
import 'schedule_entry_form_screen.dart';

class ScheduleEntryViewScreen extends ConsumerWidget {
  const ScheduleEntryViewScreen({super.key, required this.entryId});
  final String entryId;

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref,
    ScheduleEntry entry,
  ) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ScheduleEntryFormScreen(
          initialWeekday: entry.weekday,
          entry: entry,
        ),
      ),
    );
    if (changed == true) ref.invalidate(scheduleEntryProvider(entryId));
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    ScheduleEntry entry,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete entry?'),
        content: Text('Delete “${entry.title}”? This action cannot be undone.'),
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
      await ref.read(scheduleRepositoryProvider).delete(entry.id);
      if (!context.mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Schedule entry deleted.')));
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not delete this entry.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(scheduleEntryProvider(entryId))
      .when(
        loading: () =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (_, _) => Scaffold(
          appBar: AppBar(),
          body: const Center(child: Text('Could not load this entry.')),
        ),
        data: (entry) {
          if (entry == null) {
            return Scaffold(
              appBar: AppBar(),
              body: const Center(child: Text('This entry no longer exists.')),
            );
          }
          return Scaffold(
            appBar: AppBar(
              title: const Text('Entry details'),
              actions: [
                IconButton(
                  tooltip: 'Edit entry',
                  onPressed: () => _edit(context, ref, entry),
                  icon: const Icon(Icons.edit_outlined),
                ),
                IconButton(
                  tooltip: 'Delete entry',
                  onPressed: () => _delete(context, ref, entry),
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
            body: SafeArea(
              top: false,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 680),
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: ScheduleColors.resolve(entry.colorValue),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        entry.title,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 20),
                      _Detail(
                        icon: Icons.today,
                        label: 'Day',
                        value: weekdayName(entry.weekday),
                      ),
                      _Detail(
                        icon: Icons.schedule,
                        label: 'Time',
                        value: formatTimeRange(
                          context,
                          entry.startMinutes,
                          entry.endMinutes,
                        ),
                      ),
                      _Detail(
                        icon: Icons.timelapse,
                        label: 'Duration',
                        value: formatDuration(
                          entry.endMinutes - entry.startMinutes,
                        ),
                      ),
                      if (entry.location != null)
                        _Detail(
                          icon: Icons.place_outlined,
                          label: 'Location',
                          value: entry.location!,
                        ),
                      if (entry.notes != null)
                        _Detail(
                          icon: Icons.notes,
                          label: 'Notes',
                          value: entry.notes!,
                        ),
                      FutureBuilder<List<ScheduleEntry>>(
                        future: ref
                            .read(scheduleRepositoryProvider)
                            .findConflicts(
                              weekday: entry.weekday,
                              startMinutes: entry.startMinutes,
                              endMinutes: entry.endMinutes,
                              excludeId: entry.id,
                            ),
                        builder: (context, snapshot) =>
                            snapshot.hasData && snapshot.data!.isNotEmpty
                            ? const Card(
                                child: ListTile(
                                  leading: Icon(Icons.warning_amber_rounded),
                                  title: Text(
                                    'This entry overlaps another schedule item.',
                                  ),
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
}

class _Detail extends StatelessWidget {
  const _Detail({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 2),
              Text(value),
            ],
          ),
        ),
      ],
    ),
  );
}
