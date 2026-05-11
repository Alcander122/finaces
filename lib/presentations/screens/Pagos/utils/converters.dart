import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:timezone/timezone.dart' as tz;

class TZDateTimeConverter implements JsonConverter<tz.TZDateTime, Timestamp> {
  const TZDateTimeConverter();

  @override
  tz.TZDateTime fromJson(Timestamp timestamp) {
    return tz.TZDateTime.from(timestamp.toDate(), tz.local);
  }

  @override
  Timestamp toJson(tz.TZDateTime date) {
    return Timestamp.fromDate(date);
  }
}

class NullableTZDateTimeConverter implements JsonConverter<tz.TZDateTime?, Timestamp?> {
  const NullableTZDateTimeConverter();

  @override
  tz.TZDateTime? fromJson(Timestamp? timestamp) {
    if (timestamp == null) return null;
    return tz.TZDateTime.from(timestamp.toDate(), tz.local);
  }

  @override
  Timestamp? toJson(tz.TZDateTime? date) {
    if (date == null) return null;
    return Timestamp.fromDate(date);
  }
}
