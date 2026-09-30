import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:schedule_app/app/app_shell.dart';
import 'package:schedule_app/app/theme/app_theme.dart';
import 'package:schedule_app/core/database/app_database.dart';
import 'package:schedule_app/core/database/database_provider.dart';
import 'package:schedule_app/features/schedule/presentation/schedule_entry_form_screen.dart';
import 'package:schedule_app/features/tasks/presentation/task_form_screen.dart';

void main() {
  for (final size in [
    const Size(320, 740),
    const Size(390, 844),
    const Size(800, 1280),
    const Size(1280, 800),
    const Size(740, 360),
  ]) {
    for (final scale in [1.0, 1.6]) {
      testWidgets('screens fit $size at text scale $scale', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final database = AppDatabase.forTesting(NativeDatabase.memory());
        Future<void> pump(Widget home) async {
          await tester.pumpWidget(
            ProviderScope(
              overrides: [databaseProvider.overrideWithValue(database)],
              child: MaterialApp(
                theme: AppTheme.light,
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(textScaler: TextScaler.linear(scale)),
                  child: child!,
                ),
                home: home,
              ),
            ),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 500));
          expect(tester.takeException(), isNull);
        }

        await pump(const AppShell());
        expect(
          find.byType(NavigationRail),
          size.width >= 720 && size.height >= 480
              ? findsOneWidget
              : findsNothing,
        );
        for (final tab in ['Tasks', 'Calendar', 'Schedule']) {
          await tester.tap(find.text(tab).last);
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 500));
          expect(tester.takeException(), isNull);
        }
        await pump(const TaskFormScreen());
        await tester.drag(
          find.byType(CustomScrollView),
          const Offset(0, -1000),
        );
        await tester.pumpAndSettle();
        expect(find.text('Save task').hitTestable(), findsOneWidget);
        expect(tester.takeException(), isNull);
        await pump(const ScheduleEntryFormScreen(initialWeekday: 1));
        await tester.drag(find.byType(ListView), const Offset(0, -1000));
        await tester.pumpAndSettle();
        expect(find.text('Save entry').hitTestable(), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        await database.close();
      });
    }
  }
}
