import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

DateTime dateOnlyDeadline(DateTime date) =>
    DateTime(date.year, date.month, date.day, 23, 59, 59);

bool isTaskOverdue({
  required bool isCompleted,
  required DateTime? deadline,
  DateTime? now,
}) =>
    !isCompleted &&
    deadline != null &&
    deadline.isBefore(now ?? DateTime.now());

String formatTaskDeadline(BuildContext context, DateTime deadline) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(deadline.year, deadline.month, deadline.day);
  final dateLabel = day == today
      ? 'Today'
      : day == today.add(const Duration(days: 1))
      ? 'Tomorrow'
      : DateFormat(
          deadline.year == now.year ? 'MMM d' : 'MMM d, y',
        ).format(deadline);
  final dateOnly =
      deadline.hour == 23 && deadline.minute == 59 && deadline.second == 59;
  return dateOnly
      ? dateLabel
      : '$dateLabel, ${TimeOfDay.fromDateTime(deadline).format(context)}';
}
