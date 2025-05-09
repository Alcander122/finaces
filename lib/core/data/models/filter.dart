enum FilterType { monthly, quarterly, annual, custom }

class Filter {
  final FilterType type;
  final DateTime? startDate;
  final DateTime? endDate;

  const Filter({
    required this.type,
    this.startDate,
    this.endDate,
  });

  Filter copyWith({
    FilterType? type,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return Filter(
      type: type ?? this.type,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }
}