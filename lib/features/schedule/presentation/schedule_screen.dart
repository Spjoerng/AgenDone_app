import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../domain/schedule_formatters.dart';
import '../providers/schedule_providers.dart';
import 'schedule_entry_form_screen.dart';
import 'schedule_entry_view_screen.dart';
import 'widgets/schedule_entry_card.dart';

enum ScheduleViewMode { day, week }

class ScheduleScreen extends ConsumerStatefulWidget {
  const ScheduleScreen({super.key});

  @override
  ConsumerState<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends ConsumerState<ScheduleScreen> {
  late int _weekday;
  ScheduleViewMode _mode = ScheduleViewMode.day;

  @override
  void initState() {
    super.initState();
    _weekday = DateTime.now().weekday;
  }

  Future<void> _add() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ScheduleEntryFormScreen(initialWeekday: _weekday),
      ),
    );
  }

  void _open(ScheduleEntry entry) => Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => ScheduleEntryViewScreen(entryId: entry.id),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Schedule')),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 4, 24, 16),
                  child: SegmentedButton<ScheduleViewMode>(
                    segments: const [
                      ButtonSegment(
                        value: ScheduleViewMode.day,
                        label: Text('Day'),
                        icon: Icon(Icons.view_day_outlined),
                      ),
                      ButtonSegment(
                        value: ScheduleViewMode.week,
                        label: Text('Week'),
                        icon: Icon(Icons.view_week_outlined),
                      ),
                    ],
                    selected: {_mode},
                    onSelectionChanged: (value) =>
                        setState(() => _mode = value.first),
                  ),
                ),
                if (_mode == ScheduleViewMode.day)
                  _DaySelector(
                    selected: _weekday,
                    onSelected: (day) => setState(() => _weekday = day),
                  ),
                Expanded(
                  child: _mode == ScheduleViewMode.day
                      ? _DayView(weekday: _weekday, onOpen: _open, onAdd: _add)
                      : _WeekView(onOpen: _open),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'schedule_add',
        tooltip: 'Add schedule entry',
        onPressed: _add,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _DaySelector extends StatelessWidget {
  const _DaySelector({required this.selected, required this.onSelected});
  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    padding: const EdgeInsets.symmetric(horizontal: 24),
    child: Row(
      children: List.generate(7, (index) {
        final day = index + 1;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ChoiceChip(
            label: Text(weekdayShortNames[index]),
            selected: selected == day,
            avatar: DateTime.now().weekday == day
                ? const Icon(Icons.circle, size: 8)
                : null,
            onSelected: (_) => onSelected(day),
          ),
        );
      }),
    ),
  );
}

class _DayView extends ConsumerWidget {
  const _DayView({
    required this.weekday,
    required this.onOpen,
    required this.onAdd,
  });
  final int weekday;
  final ValueChanged<ScheduleEntry> onOpen;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(scheduleEntriesForDayProvider(weekday))
      .when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => _QueryError(
          onRetry: () => ref.invalidate(scheduleEntriesForDayProvider(weekday)),
        ),
        data: (entries) {
          if (entries.isEmpty) {
            return _EmptyDay(day: weekdayName(weekday), onAdd: onAdd);
          }
          return ListView.builder(
            key: PageStorageKey('schedule-day-$weekday'),
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 96),
            itemCount: entries.length,
            itemBuilder: (context, index) => ScheduleEntryCard(
              entry: entries[index],
              hasConflict: _hasConflict(entries[index], entries),
              onTap: () => onOpen(entries[index]),
            ),
          );
        },
      );
}

class _WeekView extends ConsumerWidget {
  const _WeekView({required this.onOpen});
  final ValueChanged<ScheduleEntry> onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(allScheduleEntriesProvider)
      .when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => _QueryError(
          onRetry: () => ref.invalidate(allScheduleEntriesProvider),
        ),
        data: (entries) => ListView.builder(
          key: const PageStorageKey('schedule-week'),
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 96),
          itemCount: 7,
          itemBuilder: (context, index) {
            final day = index + 1;
            final dayEntries = entries
                .where((entry) => entry.weekday == day)
                .toList();
            final current = day == DateTime.now().weekday;
            return Card(
              color: current
                  ? Theme.of(
                      context,
                    ).colorScheme.secondary.withValues(alpha: .18)
                  : null,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      weekdayName(day),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    if (dayEntries.isEmpty)
                      const Text('No entries')
                    else
                      ...dayEntries.map(
                        (entry) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          leading: const Icon(Icons.schedule, size: 20),
                          title: Text(
                            entry.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            '${formatTimeRange(context, entry.startMinutes, entry.endMinutes)}${entry.location == null ? '' : ' · ${entry.location}'}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: _hasConflict(entry, entries)
                              ? const Icon(
                                  Icons.warning_amber_rounded,
                                  semanticLabel: 'Conflicts with another entry',
                                )
                              : null,
                          onTap: () => onOpen(entry),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      );
}

bool _hasConflict(ScheduleEntry entry, List<ScheduleEntry> entries) =>
    entries.any(
      (other) =>
          other.id != entry.id &&
          other.weekday == entry.weekday &&
          other.startMinutes < entry.endMinutes &&
          other.endMinutes > entry.startMinutes,
    );

class _EmptyDay extends StatelessWidget {
  const _EmptyDay({required this.day, required this.onAdd});
  final String day;
  final VoidCallback onAdd;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.event_available, size: 48),
          const SizedBox(height: 12),
          Text(
            'Your $day is clear.',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap + to add your first schedule entry.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Add entry'),
          ),
        ],
      ),
    ),
  );
}

class _QueryError extends StatelessWidget {
  const _QueryError({required this.onRetry});
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('Could not load your schedule.'),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
          label: const Text('Retry'),
        ),
      ],
    ),
  );
}
