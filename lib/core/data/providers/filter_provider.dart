import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finances/core/data/models/filter.dart';
import 'package:finances/core/data/utils/date_utils.dart';

final filterProvider = StateProvider<Filter>((ref) {
  final now = DateTime.now();
  return Filter(
    type: FilterType.monthly,
    startDate: DateUtils.getStartOfMonth(now),
    endDate: DateUtils.getEndOfMonth(now),
  );
});