import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../app/theme/app_colors.dart';
import '../../tasks/domain/task_colors.dart';
import '../../tasks/domain/task_helpers.dart';
import '../../tasks/domain/task_models.dart';
import '../../tasks/presentation/task_detail_screen.dart';
import '../../tasks/presentation/task_form_screen.dart';
import '../domain/calendar_grouping.dart';
import '../providers/calendar_providers.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});
  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  late DateTime _focusedDay;
  late DateTime _selectedDay;
  late final DateTime _firstDay;
  late final DateTime _lastDay;

  @override
  void initState() {
    super.initState();
    final today = normalizeLocalDate(DateTime.now());
    _focusedDay = today;
    _selectedDay = today;
    _firstDay = DateTime(today.year - 10);
    _lastDay = DateTime(today.year + 21, 1, 0);
  }

  void _goToMonth(int offset) {
    final next = DateTime(_focusedDay.year, _focusedDay.month + offset, 1);
    setState(
      () => _focusedDay = next.isBefore(_firstDay)
          ? _firstDay
          : next.isAfter(_lastDay)
          ? _lastDay
          : next,
    );
  }

  void _today() {
    final today = normalizeLocalDate(DateTime.now());
    setState(() {
      _focusedDay = today;
      _selectedDay = today;
    });
  }

  Future<void> _addTask() => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) =>
          TaskFormScreen(initialDeadline: dateOnlyDeadline(_selectedDay)),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final groupsValue = ref.watch(calendarTaskGroupsProvider);
    final groups =
        groupsValue.value ?? const <DateTime, List<TaskWithChecklist>>{};
    final selectedTasks =
        groups[normalizeLocalDate(_selectedDay)] ?? const <TaskWithChecklist>[];
    final calendar = Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
        child: Column(
          children: [
            Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      tooltip: 'Previous month',
                      onPressed: () => _goToMonth(-1),
                      icon: const Icon(Icons.chevron_left),
                    ),
                    Expanded(
                      child: Text(
                        DateFormat('MMMM y').format(_focusedDay),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Next month',
                      onPressed: () => _goToMonth(1),
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _today,
                    child: const Text('Today'),
                  ),
                ),
              ],
            ),
            TableCalendar<TaskWithChecklist>(
              firstDay: _firstDay,
              lastDay: _lastDay,
              focusedDay: _focusedDay,
              calendarFormat: CalendarFormat.month,
              headerVisible: false,
              rowHeight:
                  52 *
                  MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.5),
              daysOfWeekHeight: 28 * MediaQuery.textScalerOf(context).scale(1),

              availableCalendarFormats: const {CalendarFormat.month: 'Month'},
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              eventLoader: (day) => groups[normalizeLocalDate(day)] ?? const [],
              onDaySelected: (selectedDay, focusedDay) => setState(() {
                _selectedDay = normalizeLocalDate(selectedDay);
                _focusedDay = focusedDay;
              }),
              onPageChanged: (focusedDay) =>
                  setState(() => _focusedDay = focusedDay),
              daysOfWeekStyle: const DaysOfWeekStyle(
                weekdayStyle: TextStyle(
                  color: AppColors.deepPlum,
                  fontWeight: FontWeight.w600,
                ),
                weekendStyle: TextStyle(
                  color: AppColors.crimson,
                  fontWeight: FontWeight.w600,
                ),
              ),
              calendarStyle: const CalendarStyle(
                cellMargin: EdgeInsets.all(6),

                outsideTextStyle: TextStyle(color: AppColors.mutedText),
                weekendTextStyle: TextStyle(color: AppColors.crimson),
                todayDecoration: BoxDecoration(
                  color: AppColors.terracotta,
                  shape: BoxShape.circle,
                ),
                todayTextStyle: TextStyle(
                  color: AppColors.darkText,
                  fontWeight: FontWeight.w700,
                ),
                selectedDecoration: BoxDecoration(
                  color: AppColors.deepPlum,
                  shape: BoxShape.circle,
                ),
                selectedTextStyle: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
                defaultTextStyle: TextStyle(color: AppColors.darkText),
                markersMaxCount: 1,
              ),
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, day, events) {
                  if (events.isEmpty) return null;
                  return Positioned(
                    right: 2,
                    bottom: 1,
                    child: Semantics(
                      label:
                          '${events.length} ${events.length == 1 ? 'task' : 'tasks'} due',
                      child: Container(
                        key: ValueKey(
                          'calendar-marker-${day.year}-${day.month}-${day.day}',
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: events.every((event) => event.task.isCompleted)
                              ? AppColors.outline
                              : AppColors.crimson,
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(color: AppColors.paleCream),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${events.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
    final agenda = <Widget>[
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 16),
          child: Text(
            _selectedHeading(_selectedDay),
            key: const Key('selected-date-heading'),
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
      ),
      ..._taskSlivers(groupsValue, selectedTasks),
      const SliverPadding(padding: EdgeInsets.only(bottom: 96)),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Calendar')),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide =
                constraints.maxWidth >= 960 &&
                MediaQuery.textScalerOf(context).scale(1) <= 1.3;
            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: wide ? 1200 : 720),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: constraints.maxWidth < 600 ? 16 : 24,
                  ),
                  child: wide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 6,
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.only(bottom: 24),
                                child: calendar,
                              ),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              flex: 5,
                              child: CustomScrollView(
                                key: const PageStorageKey('calendar-agenda'),
                                slivers: agenda,
                              ),
                            ),
                          ],
                        )
                      : CustomScrollView(
                          key: const PageStorageKey('calendar-scroll'),
                          slivers: [
                            SliverToBoxAdapter(child: calendar),
                            ...agenda,
                          ],
                        ),
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'calendar_add_task',
        tooltip: 'Add task for selected date',
        onPressed: _addTask,
        child: const Icon(Icons.add_task),
      ),
    );
  }

  List<Widget> _taskSlivers(
    AsyncValue<Map<DateTime, List<TaskWithChecklist>>> groupsValue,
    List<TaskWithChecklist> selectedTasks,
  ) => groupsValue.when(
    loading: () => const [
      SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: CircularProgressIndicator(),
          ),
        ),
      ),
    ],
    error: (_, _) => [
      SliverToBoxAdapter(
        child: Center(
          child: OutlinedButton.icon(
            onPressed: () => ref.invalidate(deadlineTasksProvider),
            icon: const Icon(Icons.refresh),
            label: const Text('Retry loading deadlines'),
          ),
        ),
      ),
    ],
    data: (groups) {
      if (selectedTasks.isEmpty) {
        final message = groups.isEmpty
            ? 'Tasks with deadlines will appear here.'
            : 'No deadlines for this day.';
        return [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.event_available_outlined,
                        size: 32,
                        color: AppColors.deepPlum,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.mutedText),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: _addTask,
                        icon: const Icon(Icons.add),
                        label: const Text('Add task'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ];
      }
      return [
        SliverPadding(
          padding: EdgeInsets.zero,
          sliver: SliverList.builder(
            itemCount: selectedTasks.length,
            itemBuilder: (context, index) =>
                _CalendarTaskRow(data: selectedTasks[index]),
          ),
        ),
      ];
    },
  );
}

String _selectedHeading(DateTime day) {
  final today = normalizeLocalDate(DateTime.now());
  if (day == today) return 'Today';
  if (day == today.add(const Duration(days: 1))) return 'Tomorrow';
  return DateFormat(
    day.year == today.year ? 'EEEE, MMMM d' : 'EEEE, MMMM d, y',
  ).format(day);
}

class _CalendarTaskRow extends StatelessWidget {
  const _CalendarTaskRow({required this.data});
  final TaskWithChecklist data;
  @override
  Widget build(BuildContext context) {
    final task = data.task;
    final overdue = isTaskOverdue(
      isCompleted: task.isCompleted,
      deadline: task.deadline,
    );
    final dateOnly =
        task.deadline!.hour == 23 &&
        task.deadline!.minute == 59 &&
        task.deadline!.second == 59;
    return Card(
      color: TaskColors.resolve(task.colorValue),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => TaskDetailScreen(taskId: task.id)),
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(
                width: 6,
                color: task.isCompleted
                    ? AppColors.outline
                    : overdue
                    ? AppColors.crimson
                    : AppColors.deepPlum,
              ),
              Expanded(
                child: ListTile(
                  title: Text(
                    task.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      decoration: task.isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.isCompleted
                            ? 'Completed'
                            : overdue
                            ? 'Overdue'
                            : 'Open',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: overdue
                              ? AppColors.crimson
                              : AppColors.darkText,
                        ),
                      ),
                      if (!dateOnly)
                        Text(
                          TimeOfDay.fromDateTime(
                            task.deadline!,
                          ).format(context),
                        ),
                      if (data.totalCount > 0)
                        Text(
                          '${data.completedCount} of ${data.totalCount} checklist items',
                        ),
                    ],
                  ),
                  trailing: Icon(
                    task.isCompleted
                        ? Icons.check_circle
                        : overdue
                        ? Icons.warning_amber_rounded
                        : Icons.chevron_right,
                    semanticLabel: task.isCompleted
                        ? 'Completed'
                        : overdue
                        ? 'Overdue'
                        : 'Open task',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
