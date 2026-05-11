// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Payment _$PaymentFromJson(Map<String, dynamic> json) => _Payment(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      title: json['title'] as String? ?? 'Sin título',
      description: json['descripcion'] as String? ?? '',
      totalAmount: (json['monto'] as num?)?.toDouble() ?? 0.0,
      paidAmount: (json['paidAmount'] as num?)?.toDouble() ?? 0.0,
      nextDueDate: _$JsonConverterFromJson<Timestamp, TZDateTime>(
          json['fechaVencimiento'], const TZDateTimeConverter().fromJson),
      recurrence: json['recurrence'] == null
          ? const Recurrence()
          : _recurrenceFromJson(json['recurrence'] as Map<String, dynamic>),
      notifyDaysBefore: (json['notifyDaysBefore'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          const [],
      notificationTimeOfDay: const NullableTZDateTimeConverter()
          .fromJson(json['notificationTimeOfDay'] as Timestamp?),
      status: $enumDecodeNullable(_$PaymentStatusEnumMap, json['status']) ??
          PaymentStatus.pending,
      fcmTokens: (json['fcmTokens'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );

Map<String, dynamic> _$PaymentToJson(_Payment instance) => <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'title': instance.title,
      'descripcion': instance.description,
      'monto': instance.totalAmount,
      'paidAmount': instance.paidAmount,
      'fechaVencimiento': _$JsonConverterToJson<Timestamp, TZDateTime>(
          instance.nextDueDate, const TZDateTimeConverter().toJson),
      'recurrence': _recurrenceToJson(instance.recurrence),
      'notifyDaysBefore': instance.notifyDaysBefore,
      'notificationTimeOfDay': const NullableTZDateTimeConverter()
          .toJson(instance.notificationTimeOfDay),
      'status': _$PaymentStatusEnumMap[instance.status]!,
      'fcmTokens': instance.fcmTokens,
    };

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) =>
    json == null ? null : fromJson(json as Json);

const _$PaymentStatusEnumMap = {
  PaymentStatus.pending: 'pending',
  PaymentStatus.paid: 'paid',
  PaymentStatus.partial: 'partial',
  PaymentStatus.overdue: 'overdue',
  PaymentStatus.paused: 'paused',
};

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) =>
    value == null ? null : toJson(value);
