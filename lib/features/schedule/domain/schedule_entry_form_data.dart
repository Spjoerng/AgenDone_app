import 'package:flutter/material.dart';

class ScheduleEntryFormData {
  const ScheduleEntryFormData({
    required this.title,
    required this.weekday,
    required this.startMinutes,
    required this.endMinutes,
    this.location,
    this.notes,
    this.colorValue,
  });

  final String title;
  final int weekday;
  final int startMinutes;
  final int endMinutes;
  final String? location;
  final String? notes;
  final int? colorValue;
}

int timeOfDayToMinutes(TimeOfDay time) => time.hour * 60 + time.minute;

TimeOfDay minutesToTimeOfDay(int minutes) {
  final normalized = minutes == 1440 ? 0 : minutes;
  return TimeOfDay(hour: normalized ~/ 60, minute: normalized % 60);
}
