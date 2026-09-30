import 'package:flutter/material.dart';

import '../features/calendar/presentation/calendar_screen.dart';
import '../features/schedule/presentation/schedule_screen.dart';
import '../features/tasks/presentation/task_board_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  static const _screens = [
    ScheduleScreen(),
    TaskBoardScreen(),
    CalendarScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final wide =
        MediaQuery.sizeOf(context).width >= 720 &&
        MediaQuery.sizeOf(context).height >= 480;
    final content = IndexedStack(index: _selectedIndex, children: _screens);
    return Scaffold(
      body: wide
          ? Row(
              children: [
                SafeArea(
                  child: NavigationRail(
                    labelType: NavigationRailLabelType.all,
                    selectedIndex: _selectedIndex,
                    onDestinationSelected: (index) =>
                        setState(() => _selectedIndex = index),
                    destinations: const [
                      NavigationRailDestination(
                        icon: Icon(Icons.calendar_view_week_outlined),
                        selectedIcon: Icon(Icons.calendar_view_week),
                        label: Text('Schedule'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.check_box_outlined),
                        selectedIcon: Icon(Icons.check_box),
                        label: Text('Tasks'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.calendar_month_outlined),
                        selectedIcon: Icon(Icons.calendar_month),
                        label: Text('Calendar'),
                      ),
                    ],
                  ),
                ),
                const VerticalDivider(width: 1),
                Expanded(child: content),
              ],
            )
          : content,
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) =>
                  setState(() => _selectedIndex = index),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.calendar_view_week_outlined),
                  selectedIcon: Icon(Icons.calendar_view_week),
                  label: 'Schedule',
                ),
                NavigationDestination(
                  icon: Icon(Icons.check_box_outlined),
                  selectedIcon: Icon(Icons.check_box),
                  label: 'Tasks',
                ),
                NavigationDestination(
                  icon: Icon(Icons.calendar_month_outlined),
                  selectedIcon: Icon(Icons.calendar_month),
                  label: 'Calendar',
                ),
              ],
            ),
    );
  }
}
