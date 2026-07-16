import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:schedule_app/app/theme/app_theme.dart';
import 'package:schedule_app/core/database/app_database.dart';
import 'package:schedule_app/core/database/database_provider.dart';
import 'package:schedule_app/features/calendar/presentation/calendar_screen.dart';
import 'package:schedule_app/features/tasks/data/task_repository.dart';
import 'package:schedule_app/features/tasks/domain/task_helpers.dart';
import 'package:schedule_app/features/tasks/domain/task_models.dart';

void main() {
  late AppDatabase database;
  setUp(() => database = AppDatabase.forTesting(NativeDatabase.memory()));

  Future<void> pumpCalendar(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(database)],
        child: MaterialApp(theme: AppTheme.light, home: const CalendarScreen()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  Future<void> dispose(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump(const Duration(milliseconds: 1));
    await database.close();
  }

  testWidgets('initially selects today and shows empty state', (tester) async {
    await pumpCalendar(tester);
    expect(find.byKey(const Key('selected-date-heading')), findsOneWidget);
    expect(find.text('Today'), findsWidgets);
    expect(find.text('Tasks with deadlines will appear here.'), findsOneWidget);
    await dispose(tester);
  });
  testWidgets('deadline count and selected-day task are displayed', (
    tester,
  ) async {
    final today = DateTime.now();
    await TaskRepository(database).create(
      TaskFormData(title: 'Due today', deadline: dateOnlyDeadline(today)),
    );
    await pumpCalendar(tester);
    expect(
      find.byKey(
        ValueKey('calendar-marker-${today.year}-${today.month}-${today.day}'),
      ),
      findsOneWidget,
    );
    expect(find.text('Due today'), findsOneWidget);
    await dispose(tester);
  });
  testWidgets('tapping a listed task opens reusable detail screen', (
    tester,
  ) async {
    await TaskRepository(database).create(
      TaskFormData(
        title: 'Open details',
        deadline: dateOnlyDeadline(DateTime.now()),
      ),
    );
    await pumpCalendar(tester);
    await tester.tap(find.text('Open details'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.widgetWithText(AppBar, 'Task details'), findsOneWidget);
    await dispose(tester);
  });
  testWidgets('completed and overdue statuses are visible', (tester) async {
    final repository = TaskRepository(database);
    final now = DateTime.now();
    final completedId = await repository.create(
      TaskFormData(
        title: 'Finished',
        deadline: DateTime(now.year, now.month, now.day, now.hour, now.minute),
      ),
    );
    await repository.setCompleted(
      (await repository.getTask(completedId))!,
      true,
    );
    await repository.create(
      TaskFormData(
        title: 'Late',
        deadline: now.subtract(const Duration(hours: 1)),
      ),
    );
    await pumpCalendar(tester);
    expect(find.text('Completed'), findsOneWidget);
    expect(find.text('Overdue'), findsOneWidget);
    await dispose(tester);
  });
  testWidgets('month controls navigate and Today returns', (tester) async {
    await pumpCalendar(tester);
    final currentMonth = DateFormat('MMMM y').format(DateTime.now());
    await tester.tap(find.byTooltip('Next month'));
    await tester.pump();
    expect(find.text(currentMonth), findsNothing);
    await tester.tap(find.widgetWithText(TextButton, 'Today'));
    await tester.pump();
    expect(find.text(currentMonth), findsOneWidget);
    expect(find.byKey(const Key('selected-date-heading')), findsOneWidget);
    await dispose(tester);
  });
  testWidgets('Add Task preselects selected date', (tester) async {
    await pumpCalendar(tester);
    await tester.tap(find.byTooltip('Add task for selected date'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.widgetWithText(AppBar, 'Add task'), findsOneWidget);
    expect(find.text('Today'), findsAtLeastNWidgets(1));
    await dispose(tester);
  });
}
