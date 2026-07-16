import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../data/schedule_repository.dart';

final scheduleRepositoryProvider = Provider<ScheduleRepository>(
  (ref) => ScheduleRepository(ref.watch(databaseProvider)),
);
final allScheduleEntriesProvider = StreamProvider<List<ScheduleEntry>>(
  (ref) => ref.watch(scheduleRepositoryProvider).watchAll(),
);
final scheduleEntriesForDayProvider =
    StreamProvider.family<List<ScheduleEntry>, int>(
      (ref, weekday) =>
          ref.watch(scheduleRepositoryProvider).watchForWeekday(weekday),
    );
final scheduleEntryProvider = FutureProvider.family<ScheduleEntry?, String>(
  (ref, id) => ref.watch(scheduleRepositoryProvider).getById(id),
);
