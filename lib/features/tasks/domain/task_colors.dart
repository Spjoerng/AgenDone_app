import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';

abstract final class TaskColors {
  static const values = [
    AppColors.paleCream,
    AppColors.warmCream,
    Color(0xFFD8B8D0),
    Color(0xFFE8B0BD),
    Color(0xFFF2B99D),
    Color(0xFFD8C0A0),
  ];
  static Color resolve(int? value) =>
      value == null ? AppColors.warmCream : Color(value);
}
