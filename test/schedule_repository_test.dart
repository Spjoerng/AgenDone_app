import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:schedule_app/core/database/app_database.dart';
import 'package:schedule_app/features/schedule/data/schedule_repository.dart';
import 'package:schedule_app/features/schedule/domain/schedule_entry_form_data.dart';
import 'package:schedule_app/features/schedule/domain/schedule_formatters.dart';

void main() {
  late AppDatabase database;
  late ScheduleRepository repository;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    repository = ScheduleRepository(database);
  });

  tearDown(() => database.close());

  ScheduleEntryFormData data(
    String title,
    int start,
    int end, {
    int weekday = 1,
  }) => ScheduleEntryFormData(
    title: title,
    weekday: weekday,
    startMinutes: start,
    endMinutes: end,
  );

  test('inserts and retrieves an entry', () async {
    final id = await repository.insert(data('Focus time', 540, 600));
    expect((await repository.getById(id))?.title, 'Focus time');
  });

  test('orders entries by start time', () async {
    await repository.insert(data('Later', 660, 720));
    await repository.insert(data('Earlier', 480, 540));
    final entries = await repository.watchForWeekday(1).first;
    expect(entries.map((entry) => entry.title), ['Earlier', 'Later']);
  });

  test('updates an entry while preserving its id and creation time', () async {
    final id = await repository.insert(data('Old', 540, 600));
    final before = (await repository.getById(id))!;
    await repository.updateEntry(before, data('New', 600, 660));
    final after = (await repository.getById(id))!;
    expect(after.title, 'New');
    expect(after.id, before.id);
    expect(after.createdAt, before.createdAt);
  });

  test('deletes an entry', () async {
    final id = await repository.insert(data('Delete me', 540, 600));
    await repository.delete(id);
    expect(await repository.getById(id), isNull);
  });

  test('detects partial overlap', () async {
    await repository.insert(data('Existing', 540, 630));
    expect(
      await repository.findConflicts(
        weekday: 1,
        startMinutes: 600,
        endMinutes: 660,
      ),
      hasLength(1),
    );
  });

  test('detects complete containment', () async {
    await repository.insert(data('Existing', 480, 720));
    expect(
      await repository.findConflicts(
        weekday: 1,
        startMinutes: 540,
        endMinutes: 600,
      ),
      hasLength(1),
    );
  });

  test('adjacent entries do not conflict', () async {
    await repository.insert(data('Existing', 540, 600));
    expect(
      await repository.findConflicts(
        weekday: 1,
        startMinutes: 600,
        endMinutes: 660,
      ),
      isEmpty,
    );
  });

  test('editing excludes the current entry', () async {
    final id = await repository.insert(data('Existing', 540, 600));
    expect(
      await repository.findConflicts(
        weekday: 1,
        startMinutes: 540,
        endMinutes: 600,
        excludeId: id,
      ),
      isEmpty,
    );
  });

  test('converts TimeOfDay and minutes', () {
    expect(timeOfDayToMinutes(const TimeOfDay(hour: 13, minute: 45)), 825);
    expect(minutesToTimeOfDay(825), const TimeOfDay(hour: 13, minute: 45));
    expect(minutesToTimeOfDay(1440), const TimeOfDay(hour: 0, minute: 0));
  });

  test('formats durations', () {
    expect(formatDuration(45), '45 min');
    expect(formatDuration(60), '1 hr');
    expect(formatDuration(90), '1 hr 30 min');
  });
}
