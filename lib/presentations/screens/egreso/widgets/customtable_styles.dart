import 'package:flutter/material.dart';

class CustomTableStyles {
  static const headerTextStyle = TextStyle(
    color: Colors.white,
    fontWeight: FontWeight.bold,
  );
  static const rowDecoration = BoxDecoration(
    color: Colors.white,
    border: Border(
      bottom: BorderSide(color: Colors.grey, width: 0.5),
    ),
  );

  static const headerPadding = EdgeInsets.symmetric(
    vertical: 16.0,
    horizontal: 8.0,
  );

  static const headerDecoration = BoxDecoration();
}
