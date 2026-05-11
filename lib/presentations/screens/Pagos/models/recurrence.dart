import 'package:freezed_annotation/freezed_annotation.dart';
import 'payment_enums.dart';

part 'recurrence.freezed.dart';
part 'recurrence.g.dart';

@freezed
abstract class Recurrence with _$Recurrence {
  const factory Recurrence({
    @Default(FrequencyUnit.none) FrequencyUnit unit,
    @Default(0) int interval,
    int? totalInstallments,
    int? currentInstallment,
  }) = _Recurrence;

  factory Recurrence.fromJson(Map<String, dynamic> json) =>
      _$RecurrenceFromJson(json);
}
