import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';

abstract final class ScheduleColors {
  static const values = [
    AppColors.deepPlum,
    AppColors.crimson,
    AppColors.terracotta,
    Color(0xFF8A5A75),
    Color(0xFFC86B52),
    Color(0xFFB08A62),
  ];

  static Color resolve(int? value) =>
      value == null ? AppColors.deepPlum : Color(value);
}
