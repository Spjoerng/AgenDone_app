import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:schedule_app/app/app_shell.dart';
import 'package:schedule_app/app/theme/app_theme.dart';
import 'package:schedule_app/core/database/app_database.dart';
import 'package:schedule_app/core/database/database_provider.dart';
import 'package:schedule_app/features/schedule/data/schedule_repository.dart';
import 'package:schedule_app/features/schedule/domain/schedule_entry_form_data.dart';
import 'package:schedule_app/features/schedule/presentation/schedule_entry_form_screen.dart';
import 'package:schedule_app/features/schedule/presentation/schedule_entry_view_screen.dart';

void main() {
  late AppDatabase database;

  setUp(() => database = AppDatabase.forTesting(NativeDatabase.memory()));

  Future<void> pumpApp(
    WidgetTester tester, {
    Widget home = const AppShell(),
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(database)],
        child: MaterialApp(theme: AppTheme.light, home: home),
      ),
    );
  }

  Future<void> disposeApp(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump(const Duration(milliseconds: 1));
    await database.close();
  }

  testWidgets('main navigation switches to the Tasks screen', (tester) async {
    await pumpApp(tester);
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Schedule'), findsAtLeastNWidgets(1));
    expect(find.text('Tasks'), findsOneWidget);
    expect(find.text('Calendar'), findsOneWidget);
    await tester.tap(find.text('Tasks'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Nothing to do.'), findsOneWidget);
    expect(find.widgetWithText(AppBar, 'Tasks'), findsOneWidget);
    await disposeApp(tester);
  });

  testWidgets('switches between Day and Week views', (tester) async {
    await pumpApp(tester);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text('Week'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Monday'), findsOneWidget);
    expect(find.text('No entries'), findsWidgets);
    await disposeApp(tester);
  });

  testWidgets('opens the add-entry form', (tester) async {
    await pumpApp(tester);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.widgetWithText(OutlinedButton, 'Add entry'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(TextFormField), findsNWidgets(3));
    await disposeApp(tester);
  });

  testWidgets('validates the required title', (tester) async {
    await pumpApp(
      tester,
      home: const ScheduleEntryFormScreen(initialWeekday: 1),
    );
    await tester.pump(const Duration(milliseconds: 500));
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pump();
    await tester.tap(find.text('Save entry'));
    await tester.pump();
    expect(find.text('Enter a title'), findsOneWidget);
    await disposeApp(tester);
  });

  testWidgets('shows invalid time validation', (tester) async {
    final now = DateTime(2026);
    await pumpApp(
      tester,
      home: ScheduleEntryFormScreen(
        initialWeekday: 1,
        entry: ScheduleEntry(
          id: 'invalid-time',
          title: 'Meeting',
          weekday: 1,
          startMinutes: 540,
          endMinutes: 540,
          createdAt: now,
          updatedAt: now,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('End time must be after start time'), findsOneWidget);
    await disposeApp(tester);
  });

  testWidgets(
    'opens an existing entry in view mode and shows delete confirmation',
    (tester) async {
      final id = await ScheduleRepository(database).insert(
        const ScheduleEntryFormData(
          title: 'Planning',
          weekday: 1,
          startMinutes: 540,
          endMinutes: 600,
        ),
      );
      await pumpApp(tester, home: ScheduleEntryViewScreen(entryId: id));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Planning'), findsOneWidget);
      expect(find.byType(TextFormField), findsNothing);
      await tester.tap(find.byTooltip('Delete entry'));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Delete entry?'), findsOneWidget);
      expect(find.textContaining('cannot be undone'), findsOneWidget);
      await disposeApp(tester);
    },
  );
}
