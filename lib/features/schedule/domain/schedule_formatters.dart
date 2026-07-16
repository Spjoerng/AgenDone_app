import 'package:flutter/material.dart';

import 'schedule_entry_form_data.dart';

const weekdayNames = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];
const weekdayShortNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

String weekdayName(int weekday) => weekdayNames[weekday - 1];

String formatMinutes(BuildContext context, int minutes) {
  if (minutes == 1440) return '12:00 AM';
  return minutesToTimeOfDay(minutes).format(context);
}

String formatTimeRange(BuildContext context, int start, int end) =>
    '${formatMinutes(context, start)} – ${formatMinutes(context, end)}';

String formatDuration(int minutes) {
  final hours = minutes ~/ 60;
  final remainder = minutes % 60;
  if (hours == 0) return '$remainder min';
  if (remainder == 0) return '$hours hr';
  return '$hours hr $remainder min';
}
