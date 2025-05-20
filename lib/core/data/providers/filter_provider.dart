import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finances/core/data/models/filter.dart';

final filterProvider = StateProvider<Filter>((ref) {
  return const Filter(type: FilterType.monthly);
});