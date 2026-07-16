import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:schedule_app/app/theme/app_theme.dart';
import 'package:schedule_app/core/database/app_database.dart';
import 'package:schedule_app/core/database/database_provider.dart';
import 'package:schedule_app/features/tasks/data/task_repository.dart';
import 'package:schedule_app/features/tasks/domain/task_models.dart';
import 'package:schedule_app/features/tasks/presentation/task_board_screen.dart';
import 'package:schedule_app/features/tasks/presentation/task_detail_screen.dart';
import 'package:schedule_app/features/tasks/presentation/task_form_screen.dart';

void main() {
  late AppDatabase database;
  setUp(() => database = AppDatabase.forTesting(NativeDatabase.memory()));

  Future<void> pump(WidgetTester tester, Widget home) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(database)],
        child: MaterialApp(theme: AppTheme.light, home: home),
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

  testWidgets('switches filters and shows their empty states', (tester) async {
    await pump(tester, const TaskBoardScreen());
    expect(find.text('Nothing to do.'), findsOneWidget);
    await tester.tap(find.text('Open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('No open tasks'), findsOneWidget);
    await tester.tap(find.text('Completed'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('No completed tasks'), findsOneWidget);
    await dispose(tester);
  });
  testWidgets('opens add form and validates title', (tester) async {
    await pump(tester, const TaskBoardScreen());
    await tester.tap(find.byTooltip('Add task'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.widgetWithText(AppBar, 'Add task'), findsOneWidget);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -600));
    await tester.pump();
    await tester.tap(find.text('Save task'));
    await tester.pump();
    expect(find.text('Enter a title'), findsOneWidget);
    await dispose(tester);
  });
  testWidgets('adds and removes checklist rows', (tester) async {
    await pump(tester, const TaskFormScreen());
    await tester.tap(find.text('Add item'));
    await tester.pump();
    expect(find.text('Checklist item 1'), findsOneWidget);
    await tester.tap(find.byTooltip('Remove checklist item'));
    await tester.pump();
    expect(find.text('Checklist item 1'), findsNothing);
    await dispose(tester);
  });
  testWidgets('opens task detail and toggles checklist and completion', (
    tester,
  ) async {
    final repository = TaskRepository(database);
    final id = await repository.create(
      const TaskFormData(
        title: 'Project',
        checklist: [ChecklistDraft(id: 'one', text: 'Step one')],
      ),
    );
    await pump(tester, TaskDetailScreen(taskId: id));
    expect(find.text('Project'), findsOneWidget);
    await tester.tap(find.byType(Checkbox));
    await tester.pump(const Duration(milliseconds: 300));
    expect((await repository.fetchChecklist(id)).single.isCompleted, isTrue);
    await tester.tap(find.text('Mark complete'));
    await tester.pump(const Duration(milliseconds: 300));
    expect((await repository.getTask(id))!.isCompleted, isTrue);
    await tester.tap(find.text('Reopen task'));
    await tester.pump(const Duration(milliseconds: 300));
    expect((await repository.getTask(id))!.isCompleted, isFalse);
    await dispose(tester);
  });
  testWidgets('shows delete confirmation', (tester) async {
    final id = await TaskRepository(
      database,
    ).create(const TaskFormData(title: 'Delete me'));
    await pump(tester, TaskDetailScreen(taskId: id));
    await tester.tap(find.byTooltip('Delete task'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Delete task?'), findsOneWidget);
    expect(find.textContaining('checklist items'), findsOneWidget);
    await dispose(tester);
  });
}
