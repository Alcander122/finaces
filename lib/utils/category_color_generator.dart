// lib/core/utils/category_color_generator.dart
import 'package:flutter/material.dart';

class CategoryColorGenerator {
  static Color getColor(String category) {
    final hue = category.hashCode % 360;
    return HSLColor.fromAHSL(1.0, hue.toDouble(), 0.7, 0.6).toColor();
  }

  static Color getContrastTextColor(Color backgroundColor) {
    return backgroundColor.computeLuminance() > 0.5
        ? Colors.black
        : Colors.white;
  }
}
