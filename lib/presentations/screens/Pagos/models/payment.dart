import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timezone/timezone.dart' as tz;

import '../utils/converters.dart';
import 'payment_enums.dart';
import 'recurrence.dart';

part 'payment.freezed.dart';
part 'payment.g.dart';

typedef TZDateTime = tz.TZDateTime;

Map<String, dynamic> _recurrenceToJson(Recurrence recurrence) =>
    recurrence.toJson();
Recurrence _recurrenceFromJson(Map<String, dynamic> json) =>
    Recurrence.fromJson(json);

@freezed
abstract class Payment with _$Payment {
  const Payment._(); // Required for custom getters

  const factory Payment({
    @Default('') String id,
    @Default('') String userId,
    @JsonKey(name: 'title') @Default('Sin título') String title,
    @JsonKey(name: 'descripcion') @Default('') String description,
    @JsonKey(name: 'monto') @Default(0.0) double totalAmount,
    @Default(0.0) double paidAmount,

    // Usamos el convertidor que me pasaste para hablar con Firestore
    @TZDateTimeConverter()
    @JsonKey(name: 'fechaVencimiento')
    tz.TZDateTime? nextDueDate,
    @JsonKey(fromJson: _recurrenceFromJson, toJson: _recurrenceToJson)
    @Default(Recurrence())
    Recurrence recurrence,
    @Default([]) List<int> notifyDaysBefore,
    @NullableTZDateTimeConverter() tz.TZDateTime? notificationTimeOfDay,
    @Default(PaymentStatus.pending) PaymentStatus status,
    @Default([]) List<String> fcmTokens,
  }) = _Payment;

  factory Payment.fromJson(Map<String, dynamic> json) =>
      _$PaymentFromJson(json);

  String get notificationHash {
    final dateStr = nextDueDate?.toIso8601String() ?? 'no-date';
    return '${id}_${dateStr}_${status.name}';
  }
}
