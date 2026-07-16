import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../domain/schedule_entry_form_data.dart';

class ScheduleRepository {
  ScheduleRepository(this.database);

  final AppDatabase database;

  Stream<List<ScheduleEntry>> watchAll() =>
      (database.select(database.scheduleEntries)..orderBy([
            (row) => OrderingTerm.asc(row.weekday),
            (row) => OrderingTerm.asc(row.startMinutes),
          ]))
          .watch();

  Stream<List<ScheduleEntry>> watchForWeekday(int weekday) =>
      (database.select(database.scheduleEntries)
            ..where((row) => row.weekday.equals(weekday))
            ..orderBy([(row) => OrderingTerm.asc(row.startMinutes)]))
          .watch();

  Future<ScheduleEntry?> getById(String id) => (database.select(
    database.scheduleEntries,
  )..where((row) => row.id.equals(id))).getSingleOrNull();

  Future<String> insert(ScheduleEntryFormData data) async {
    final now = DateTime.now();
    final id = const Uuid().v4();
    await database
        .into(database.scheduleEntries)
        .insert(_companion(data, id: id, createdAt: now, updatedAt: now));
    return id;
  }

  Future<void> updateEntry(
    ScheduleEntry entry,
    ScheduleEntryFormData data,
  ) async {
    await database
        .update(database.scheduleEntries)
        .replace(
          entry.copyWith(
            title: data.title,
            weekday: data.weekday,
            startMinutes: data.startMinutes,
            endMinutes: data.endMinutes,
            location: Value(data.location),
            notes: Value(data.notes),
            colorValue: Value(data.colorValue),
            updatedAt: DateTime.now(),
          ),
        );
  }

  Future<void> delete(String id) async {
    await (database.delete(
      database.scheduleEntries,
    )..where((row) => row.id.equals(id))).go();
  }

  Future<List<ScheduleEntry>> findConflicts({
    required int weekday,
    required int startMinutes,
    required int endMinutes,
    String? excludeId,
  }) {
    final query = database.select(database.scheduleEntries)
      ..where(
        (row) =>
            row.weekday.equals(weekday) &
            row.startMinutes.isSmallerThanValue(endMinutes) &
            row.endMinutes.isBiggerThanValue(startMinutes),
      );
    if (excludeId != null) query.where((row) => row.id.equals(excludeId).not());
    query.orderBy([(row) => OrderingTerm.asc(row.startMinutes)]);
    return query.get();
  }

  ScheduleEntriesCompanion _companion(
    ScheduleEntryFormData data, {
    required String id,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) => ScheduleEntriesCompanion.insert(
    id: id,
    title: data.title,
    weekday: data.weekday,
    startMinutes: data.startMinutes,
    endMinutes: data.endMinutes,
    location: Value(data.location),
    notes: Value(data.notes),
    colorValue: Value(data.colorValue),
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}
