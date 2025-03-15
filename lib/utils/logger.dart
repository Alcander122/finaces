// lib/utils/logger.dart
import 'package:logger/logger.dart';

final logger = Logger(
  printer: PrettyPrinter(
    colors: true,
    printEmojis: true,
    printTime: true,
    methodCount: 0,
    lineLength: 80,
  ),
  filter: ProductionFilter(),
);
