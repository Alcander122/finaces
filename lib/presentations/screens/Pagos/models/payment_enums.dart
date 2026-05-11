import 'package:freezed_annotation/freezed_annotation.dart';

enum PaymentStatus {
  pending,
  paid,
  partial,
  overdue,
  paused,
}

enum FrequencyUnit {
  none,
  days,
  weeks,
  months,
  years,
}
