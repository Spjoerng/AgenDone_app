import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/database/database_provider.dart';
import 'app_shell.dart';
import 'theme/app_theme.dart';

class ScheduleApp extends StatelessWidget {
  const ScheduleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AgenDone',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const _DatabaseGate(),
    );
  }
}

class _DatabaseGate extends ConsumerWidget {
  const _DatabaseGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(databaseInitializationProvider)
        .when(
          data: (_) => const AppShell(),
          loading: () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (error, _) => Scaffold(
            body: SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.storage_rounded, size: 48),
                      const SizedBox(height: 16),
                      Text(
                        'Could not open local storage',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Your data remains on this device. Try opening the app again.',
                      ),
                      const SizedBox(height: 20),
                      FilledButton.icon(
                        onPressed: () =>
                            ref.invalidate(databaseInitializationProvider),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Try again'),
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
