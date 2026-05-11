// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'recurrence.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Recurrence {
  FrequencyUnit get unit;
  int get interval;
  int? get totalInstallments;
  int? get currentInstallment;

  /// Create a copy of Recurrence
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $RecurrenceCopyWith<Recurrence> get copyWith =>
      _$RecurrenceCopyWithImpl<Recurrence>(this as Recurrence, _$identity);

  /// Serializes this Recurrence to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is Recurrence &&
            (identical(other.unit, unit) || other.unit == unit) &&
            (identical(other.interval, interval) ||
                other.interval == interval) &&
            (identical(other.totalInstallments, totalInstallments) ||
                other.totalInstallments == totalInstallments) &&
            (identical(other.currentInstallment, currentInstallment) ||
                other.currentInstallment == currentInstallment));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, unit, interval, totalInstallments, currentInstallment);

  @override
  String toString() {
    return 'Recurrence(unit: $unit, interval: $interval, totalInstallments: $totalInstallments, currentInstallment: $currentInstallment)';
  }
}

/// @nodoc
abstract mixin class $RecurrenceCopyWith<$Res> {
  factory $RecurrenceCopyWith(
          Recurrence value, $Res Function(Recurrence) _then) =
      _$RecurrenceCopyWithImpl;
  @useResult
  $Res call(
      {FrequencyUnit unit,
      int interval,
      int? totalInstallments,
      int? currentInstallment});
}

/// @nodoc
class _$RecurrenceCopyWithImpl<$Res> implements $RecurrenceCopyWith<$Res> {
  _$RecurrenceCopyWithImpl(this._self, this._then);

  final Recurrence _self;
  final $Res Function(Recurrence) _then;

  /// Create a copy of Recurrence
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? unit = null,
    Object? interval = null,
    Object? totalInstallments = freezed,
    Object? currentInstallment = freezed,
  }) {
    return _then(_self.copyWith(
      unit: null == unit
          ? _self.unit
          : unit // ignore: cast_nullable_to_non_nullable
              as FrequencyUnit,
      interval: null == interval
          ? _self.interval
          : interval // ignore: cast_nullable_to_non_nullable
              as int,
      totalInstallments: freezed == totalInstallments
          ? _self.totalInstallments
          : totalInstallments // ignore: cast_nullable_to_non_nullable
              as int?,
      currentInstallment: freezed == currentInstallment
          ? _self.currentInstallment
          : currentInstallment // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

/// Adds pattern-matching-related methods to [Recurrence].
extension RecurrencePatterns on Recurrence {
  /// A variant of `map` that fallback to returning `orElse`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_Recurrence value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _Recurrence() when $default != null:
        return $default(_that);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// Callbacks receives the raw object, upcasted.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case final Subclass2 value:
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_Recurrence value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Recurrence():
        return $default(_that);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `map` that fallback to returning `null`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_Recurrence value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Recurrence() when $default != null:
        return $default(_that);
      case _:
        return null;
    }
  }

  /// A variant of `when` that fallback to an `orElse` callback.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>(
    TResult Function(FrequencyUnit unit, int interval, int? totalInstallments,
            int? currentInstallment)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _Recurrence() when $default != null:
        return $default(_that.unit, _that.interval, _that.totalInstallments,
            _that.currentInstallment);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// As opposed to `map`, this offers destructuring.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case Subclass2(:final field2):
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult when<TResult extends Object?>(
    TResult Function(FrequencyUnit unit, int interval, int? totalInstallments,
            int? currentInstallment)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Recurrence():
        return $default(_that.unit, _that.interval, _that.totalInstallments,
            _that.currentInstallment);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `when` that fallback to returning `null`
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>(
    TResult? Function(FrequencyUnit unit, int interval, int? totalInstallments,
            int? currentInstallment)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Recurrence() when $default != null:
        return $default(_that.unit, _that.interval, _that.totalInstallments,
            _that.currentInstallment);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _Recurrence implements Recurrence {
  const _Recurrence(
      {this.unit = FrequencyUnit.none,
      this.interval = 0,
      this.totalInstallments,
      this.currentInstallment});
  factory _Recurrence.fromJson(Map<String, dynamic> json) =>
      _$RecurrenceFromJson(json);

  @override
  @JsonKey()
  final FrequencyUnit unit;
  @override
  @JsonKey()
  final int interval;
  @override
  final int? totalInstallments;
  @override
  final int? currentInstallment;

  /// Create a copy of Recurrence
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$RecurrenceCopyWith<_Recurrence> get copyWith =>
      __$RecurrenceCopyWithImpl<_Recurrence>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$RecurrenceToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _Recurrence &&
            (identical(other.unit, unit) || other.unit == unit) &&
            (identical(other.interval, interval) ||
                other.interval == interval) &&
            (identical(other.totalInstallments, totalInstallments) ||
                other.totalInstallments == totalInstallments) &&
            (identical(other.currentInstallment, currentInstallment) ||
                other.currentInstallment == currentInstallment));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, unit, interval, totalInstallments, currentInstallment);

  @override
  String toString() {
    return 'Recurrence(unit: $unit, interval: $interval, totalInstallments: $totalInstallments, currentInstallment: $currentInstallment)';
  }
}

/// @nodoc
abstract mixin class _$RecurrenceCopyWith<$Res>
    implements $RecurrenceCopyWith<$Res> {
  factory _$RecurrenceCopyWith(
          _Recurrence value, $Res Function(_Recurrence) _then) =
      __$RecurrenceCopyWithImpl;
  @override
  @useResult
  $Res call(
      {FrequencyUnit unit,
      int interval,
      int? totalInstallments,
      int? currentInstallment});
}

/// @nodoc
class __$RecurrenceCopyWithImpl<$Res> implements _$RecurrenceCopyWith<$Res> {
  __$RecurrenceCopyWithImpl(this._self, this._then);

  final _Recurrence _self;
  final $Res Function(_Recurrence) _then;

  /// Create a copy of Recurrence
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? unit = null,
    Object? interval = null,
    Object? totalInstallments = freezed,
    Object? currentInstallment = freezed,
  }) {
    return _then(_Recurrence(
      unit: null == unit
          ? _self.unit
          : unit // ignore: cast_nullable_to_non_nullable
              as FrequencyUnit,
      interval: null == interval
          ? _self.interval
          : interval // ignore: cast_nullable_to_non_nullable
              as int,
      totalInstallments: freezed == totalInstallments
          ? _self.totalInstallments
          : totalInstallments // ignore: cast_nullable_to_non_nullable
              as int?,
      currentInstallment: freezed == currentInstallment
          ? _self.currentInstallment
          : currentInstallment // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

// dart format on
