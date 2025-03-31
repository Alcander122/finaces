import 'dart:math';

import 'package:flutter/material.dart';

class CategoryColorGenerator {
  static Random _random = Random();

  static Color getColor(String id) {
    final seed = id.hashCode;
    _random = Random(seed);
    return Color.fromARGB(
      255,
      _random.nextInt(256),
      _random.nextInt(256),
      _random.nextInt(256),
    );
  }
}
