// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recurrence.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Recurrence _$RecurrenceFromJson(Map<String, dynamic> json) => _Recurrence(
      unit: $enumDecodeNullable(_$FrequencyUnitEnumMap, json['unit']) ??
          FrequencyUnit.none,
      interval: (json['interval'] as num?)?.toInt() ?? 0,
      totalInstallments: (json['totalInstallments'] as num?)?.toInt(),
      currentInstallment: (json['currentInstallment'] as num?)?.toInt(),
    );

Map<String, dynamic> _$RecurrenceToJson(_Recurrence instance) =>
    <String, dynamic>{
      'unit': _$FrequencyUnitEnumMap[instance.unit]!,
      'interval': instance.interval,
      'totalInstallments': instance.totalInstallments,
      'currentInstallment': instance.currentInstallment,
    };

const _$FrequencyUnitEnumMap = {
  FrequencyUnit.none: 'none',
  FrequencyUnit.days: 'days',
  FrequencyUnit.weeks: 'weeks',
  FrequencyUnit.months: 'months',
  FrequencyUnit.years: 'years',
};
