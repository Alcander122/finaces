// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'payment.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Payment {
  String get id;
  String get userId;
  String get parentPaymentId;
  @JsonKey(name: 'title')
  String get title;
  @JsonKey(name: 'descripcion')
  String get description;
  @JsonKey(name: 'monto')
  double get totalAmount;
  double
      get paidAmount; // Usamos el convertidor que me pasaste para hablar con Firestore
  @TZDateTimeConverter()
  @JsonKey(name: 'fechaVencimiento')
  tz.TZDateTime? get nextDueDate;
  @JsonKey(fromJson: _recurrenceFromJson, toJson: _recurrenceToJson)
  Recurrence get recurrence;
  List<int> get notifyDaysBefore;
  @NullableTZDateTimeConverter()
  tz.TZDateTime? get notificationTimeOfDay;
  PaymentStatus get status;
  List<String> get fcmTokens;

  /// Create a copy of Payment
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $PaymentCopyWith<Payment> get copyWith =>
      _$PaymentCopyWithImpl<Payment>(this as Payment, _$identity);

  /// Serializes this Payment to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is Payment &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.parentPaymentId, parentPaymentId) ||
                other.parentPaymentId == parentPaymentId) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.totalAmount, totalAmount) ||
                other.totalAmount == totalAmount) &&
            (identical(other.paidAmount, paidAmount) ||
                other.paidAmount == paidAmount) &&
            (identical(other.nextDueDate, nextDueDate) ||
                other.nextDueDate == nextDueDate) &&
            (identical(other.recurrence, recurrence) ||
                other.recurrence == recurrence) &&
            const DeepCollectionEquality()
                .equals(other.notifyDaysBefore, notifyDaysBefore) &&
            (identical(other.notificationTimeOfDay, notificationTimeOfDay) ||
                other.notificationTimeOfDay == notificationTimeOfDay) &&
            (identical(other.status, status) || other.status == status) &&
            const DeepCollectionEquality().equals(other.fcmTokens, fcmTokens));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      userId,
      parentPaymentId,
      title,
      description,
      totalAmount,
      paidAmount,
      nextDueDate,
      recurrence,
      const DeepCollectionEquality().hash(notifyDaysBefore),
      notificationTimeOfDay,
      status,
      const DeepCollectionEquality().hash(fcmTokens));

  @override
  String toString() {
    return 'Payment(id: $id, userId: $userId, parentPaymentId: $parentPaymentId, title: $title, description: $description, totalAmount: $totalAmount, paidAmount: $paidAmount, nextDueDate: $nextDueDate, recurrence: $recurrence, notifyDaysBefore: $notifyDaysBefore, notificationTimeOfDay: $notificationTimeOfDay, status: $status, fcmTokens: $fcmTokens)';
  }
}

/// @nodoc
abstract mixin class $PaymentCopyWith<$Res> {
  factory $PaymentCopyWith(Payment value, $Res Function(Payment) _then) =
      _$PaymentCopyWithImpl;
  @useResult
  $Res call(
      {String id,
      String userId,
      String parentPaymentId,
      @JsonKey(name: 'title') String title,
      @JsonKey(name: 'descripcion') String description,
      @JsonKey(name: 'monto') double totalAmount,
      double paidAmount,
      @TZDateTimeConverter()
      @JsonKey(name: 'fechaVencimiento')
      tz.TZDateTime? nextDueDate,
      @JsonKey(fromJson: _recurrenceFromJson, toJson: _recurrenceToJson)
      Recurrence recurrence,
      List<int> notifyDaysBefore,
      @NullableTZDateTimeConverter() tz.TZDateTime? notificationTimeOfDay,
      PaymentStatus status,
      List<String> fcmTokens});

  $RecurrenceCopyWith<$Res> get recurrence;
}

/// @nodoc
class _$PaymentCopyWithImpl<$Res> implements $PaymentCopyWith<$Res> {
  _$PaymentCopyWithImpl(this._self, this._then);

  final Payment _self;
  final $Res Function(Payment) _then;

  /// Create a copy of Payment
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? parentPaymentId = null,
    Object? title = null,
    Object? description = null,
    Object? totalAmount = null,
    Object? paidAmount = null,
    Object? nextDueDate = freezed,
    Object? recurrence = null,
    Object? notifyDaysBefore = null,
    Object? notificationTimeOfDay = freezed,
    Object? status = null,
    Object? fcmTokens = null,
  }) {
    return _then(_self.copyWith(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _self.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      parentPaymentId: null == parentPaymentId
          ? _self.parentPaymentId
          : parentPaymentId // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _self.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _self.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      totalAmount: null == totalAmount
          ? _self.totalAmount
          : totalAmount // ignore: cast_nullable_to_non_nullable
              as double,
      paidAmount: null == paidAmount
          ? _self.paidAmount
          : paidAmount // ignore: cast_nullable_to_non_nullable
              as double,
      nextDueDate: freezed == nextDueDate
          ? _self.nextDueDate
          : nextDueDate // ignore: cast_nullable_to_non_nullable
              as tz.TZDateTime?,
      recurrence: null == recurrence
          ? _self.recurrence
          : recurrence // ignore: cast_nullable_to_non_nullable
              as Recurrence,
      notifyDaysBefore: null == notifyDaysBefore
          ? _self.notifyDaysBefore
          : notifyDaysBefore // ignore: cast_nullable_to_non_nullable
              as List<int>,
      notificationTimeOfDay: freezed == notificationTimeOfDay
          ? _self.notificationTimeOfDay
          : notificationTimeOfDay // ignore: cast_nullable_to_non_nullable
              as tz.TZDateTime?,
      status: null == status
          ? _self.status
          : status // ignore: cast_nullable_to_non_nullable
              as PaymentStatus,
      fcmTokens: null == fcmTokens
          ? _self.fcmTokens
          : fcmTokens // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ));
  }

  /// Create a copy of Payment
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $RecurrenceCopyWith<$Res> get recurrence {
    return $RecurrenceCopyWith<$Res>(_self.recurrence, (value) {
      return _then(_self.copyWith(recurrence: value));
    });
  }
}

/// Adds pattern-matching-related methods to [Payment].
extension PaymentPatterns on Payment {
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
    TResult Function(_Payment value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _Payment() when $default != null:
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
    TResult Function(_Payment value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Payment():
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
    TResult? Function(_Payment value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Payment() when $default != null:
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
    TResult Function(
            String id,
            String userId,
            String parentPaymentId,
            @JsonKey(name: 'title') String title,
            @JsonKey(name: 'descripcion') String description,
            @JsonKey(name: 'monto') double totalAmount,
            double paidAmount,
            @TZDateTimeConverter()
            @JsonKey(name: 'fechaVencimiento')
            tz.TZDateTime? nextDueDate,
            @JsonKey(fromJson: _recurrenceFromJson, toJson: _recurrenceToJson)
            Recurrence recurrence,
            List<int> notifyDaysBefore,
            @NullableTZDateTimeConverter() tz.TZDateTime? notificationTimeOfDay,
            PaymentStatus status,
            List<String> fcmTokens)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _Payment() when $default != null:
        return $default(
            _that.id,
            _that.userId,
            _that.parentPaymentId,
            _that.title,
            _that.description,
            _that.totalAmount,
            _that.paidAmount,
            _that.nextDueDate,
            _that.recurrence,
            _that.notifyDaysBefore,
            _that.notificationTimeOfDay,
            _that.status,
            _that.fcmTokens);
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
    TResult Function(
            String id,
            String userId,
            String parentPaymentId,
            @JsonKey(name: 'title') String title,
            @JsonKey(name: 'descripcion') String description,
            @JsonKey(name: 'monto') double totalAmount,
            double paidAmount,
            @TZDateTimeConverter()
            @JsonKey(name: 'fechaVencimiento')
            tz.TZDateTime? nextDueDate,
            @JsonKey(fromJson: _recurrenceFromJson, toJson: _recurrenceToJson)
            Recurrence recurrence,
            List<int> notifyDaysBefore,
            @NullableTZDateTimeConverter() tz.TZDateTime? notificationTimeOfDay,
            PaymentStatus status,
            List<String> fcmTokens)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Payment():
        return $default(
            _that.id,
            _that.userId,
            _that.parentPaymentId,
            _that.title,
            _that.description,
            _that.totalAmount,
            _that.paidAmount,
            _that.nextDueDate,
            _that.recurrence,
            _that.notifyDaysBefore,
            _that.notificationTimeOfDay,
            _that.status,
            _that.fcmTokens);
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
    TResult? Function(
            String id,
            String userId,
            String parentPaymentId,
            @JsonKey(name: 'title') String title,
            @JsonKey(name: 'descripcion') String description,
            @JsonKey(name: 'monto') double totalAmount,
            double paidAmount,
            @TZDateTimeConverter()
            @JsonKey(name: 'fechaVencimiento')
            tz.TZDateTime? nextDueDate,
            @JsonKey(fromJson: _recurrenceFromJson, toJson: _recurrenceToJson)
            Recurrence recurrence,
            List<int> notifyDaysBefore,
            @NullableTZDateTimeConverter() tz.TZDateTime? notificationTimeOfDay,
            PaymentStatus status,
            List<String> fcmTokens)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Payment() when $default != null:
        return $default(
            _that.id,
            _that.userId,
            _that.parentPaymentId,
            _that.title,
            _that.description,
            _that.totalAmount,
            _that.paidAmount,
            _that.nextDueDate,
            _that.recurrence,
            _that.notifyDaysBefore,
            _that.notificationTimeOfDay,
            _that.status,
            _that.fcmTokens);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _Payment extends Payment {
  const _Payment(
      {this.id = '',
      this.userId = '',
      this.parentPaymentId = '',
      @JsonKey(name: 'title') this.title = 'Sin título',
      @JsonKey(name: 'descripcion') this.description = '',
      @JsonKey(name: 'monto') this.totalAmount = 0.0,
      this.paidAmount = 0.0,
      @TZDateTimeConverter()
      @JsonKey(name: 'fechaVencimiento')
      this.nextDueDate,
      @JsonKey(fromJson: _recurrenceFromJson, toJson: _recurrenceToJson)
      this.recurrence = const Recurrence(),
      final List<int> notifyDaysBefore = const [],
      @NullableTZDateTimeConverter() this.notificationTimeOfDay,
      this.status = PaymentStatus.pending,
      final List<String> fcmTokens = const []})
      : _notifyDaysBefore = notifyDaysBefore,
        _fcmTokens = fcmTokens,
        super._();
  factory _Payment.fromJson(Map<String, dynamic> json) =>
      _$PaymentFromJson(json);

  @override
  @JsonKey()
  final String id;
  @override
  @JsonKey()
  final String userId;
  @override
  @JsonKey()
  final String parentPaymentId;
  @override
  @JsonKey(name: 'title')
  final String title;
  @override
  @JsonKey(name: 'descripcion')
  final String description;
  @override
  @JsonKey(name: 'monto')
  final double totalAmount;
  @override
  @JsonKey()
  final double paidAmount;
// Usamos el convertidor que me pasaste para hablar con Firestore
  @override
  @TZDateTimeConverter()
  @JsonKey(name: 'fechaVencimiento')
  final tz.TZDateTime? nextDueDate;
  @override
  @JsonKey(fromJson: _recurrenceFromJson, toJson: _recurrenceToJson)
  final Recurrence recurrence;
  final List<int> _notifyDaysBefore;
  @override
  @JsonKey()
  List<int> get notifyDaysBefore {
    if (_notifyDaysBefore is EqualUnmodifiableListView)
      return _notifyDaysBefore;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_notifyDaysBefore);
  }

  @override
  @NullableTZDateTimeConverter()
  final tz.TZDateTime? notificationTimeOfDay;
  @override
  @JsonKey()
  final PaymentStatus status;
  final List<String> _fcmTokens;
  @override
  @JsonKey()
  List<String> get fcmTokens {
    if (_fcmTokens is EqualUnmodifiableListView) return _fcmTokens;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_fcmTokens);
  }

  /// Create a copy of Payment
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$PaymentCopyWith<_Payment> get copyWith =>
      __$PaymentCopyWithImpl<_Payment>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$PaymentToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _Payment &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.parentPaymentId, parentPaymentId) ||
                other.parentPaymentId == parentPaymentId) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.totalAmount, totalAmount) ||
                other.totalAmount == totalAmount) &&
            (identical(other.paidAmount, paidAmount) ||
                other.paidAmount == paidAmount) &&
            (identical(other.nextDueDate, nextDueDate) ||
                other.nextDueDate == nextDueDate) &&
            (identical(other.recurrence, recurrence) ||
                other.recurrence == recurrence) &&
            const DeepCollectionEquality()
                .equals(other._notifyDaysBefore, _notifyDaysBefore) &&
            (identical(other.notificationTimeOfDay, notificationTimeOfDay) ||
                other.notificationTimeOfDay == notificationTimeOfDay) &&
            (identical(other.status, status) || other.status == status) &&
            const DeepCollectionEquality()
                .equals(other._fcmTokens, _fcmTokens));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      userId,
      parentPaymentId,
      title,
      description,
      totalAmount,
      paidAmount,
      nextDueDate,
      recurrence,
      const DeepCollectionEquality().hash(_notifyDaysBefore),
      notificationTimeOfDay,
      status,
      const DeepCollectionEquality().hash(_fcmTokens));

  @override
  String toString() {
    return 'Payment(id: $id, userId: $userId, parentPaymentId: $parentPaymentId, title: $title, description: $description, totalAmount: $totalAmount, paidAmount: $paidAmount, nextDueDate: $nextDueDate, recurrence: $recurrence, notifyDaysBefore: $notifyDaysBefore, notificationTimeOfDay: $notificationTimeOfDay, status: $status, fcmTokens: $fcmTokens)';
  }
}

/// @nodoc
abstract mixin class _$PaymentCopyWith<$Res> implements $PaymentCopyWith<$Res> {
  factory _$PaymentCopyWith(_Payment value, $Res Function(_Payment) _then) =
      __$PaymentCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String id,
      String userId,
      String parentPaymentId,
      @JsonKey(name: 'title') String title,
      @JsonKey(name: 'descripcion') String description,
      @JsonKey(name: 'monto') double totalAmount,
      double paidAmount,
      @TZDateTimeConverter()
      @JsonKey(name: 'fechaVencimiento')
      tz.TZDateTime? nextDueDate,
      @JsonKey(fromJson: _recurrenceFromJson, toJson: _recurrenceToJson)
      Recurrence recurrence,
      List<int> notifyDaysBefore,
      @NullableTZDateTimeConverter() tz.TZDateTime? notificationTimeOfDay,
      PaymentStatus status,
      List<String> fcmTokens});

  @override
  $RecurrenceCopyWith<$Res> get recurrence;
}

/// @nodoc
class __$PaymentCopyWithImpl<$Res> implements _$PaymentCopyWith<$Res> {
  __$PaymentCopyWithImpl(this._self, this._then);

  final _Payment _self;
  final $Res Function(_Payment) _then;

  /// Create a copy of Payment
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? parentPaymentId = null,
    Object? title = null,
    Object? description = null,
    Object? totalAmount = null,
    Object? paidAmount = null,
    Object? nextDueDate = freezed,
    Object? recurrence = null,
    Object? notifyDaysBefore = null,
    Object? notificationTimeOfDay = freezed,
    Object? status = null,
    Object? fcmTokens = null,
  }) {
    return _then(_Payment(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _self.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      parentPaymentId: null == parentPaymentId
          ? _self.parentPaymentId
          : parentPaymentId // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _self.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _self.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      totalAmount: null == totalAmount
          ? _self.totalAmount
          : totalAmount // ignore: cast_nullable_to_non_nullable
              as double,
      paidAmount: null == paidAmount
          ? _self.paidAmount
          : paidAmount // ignore: cast_nullable_to_non_nullable
              as double,
      nextDueDate: freezed == nextDueDate
          ? _self.nextDueDate
          : nextDueDate // ignore: cast_nullable_to_non_nullable
              as tz.TZDateTime?,
      recurrence: null == recurrence
          ? _self.recurrence
          : recurrence // ignore: cast_nullable_to_non_nullable
              as Recurrence,
      notifyDaysBefore: null == notifyDaysBefore
          ? _self._notifyDaysBefore
          : notifyDaysBefore // ignore: cast_nullable_to_non_nullable
              as List<int>,
      notificationTimeOfDay: freezed == notificationTimeOfDay
          ? _self.notificationTimeOfDay
          : notificationTimeOfDay // ignore: cast_nullable_to_non_nullable
              as tz.TZDateTime?,
      status: null == status
          ? _self.status
          : status // ignore: cast_nullable_to_non_nullable
              as PaymentStatus,
      fcmTokens: null == fcmTokens
          ? _self._fcmTokens
          : fcmTokens // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ));
  }

  /// Create a copy of Payment
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $RecurrenceCopyWith<$Res> get recurrence {
    return $RecurrenceCopyWith<$Res>(_self.recurrence, (value) {
      return _then(_self.copyWith(recurrence: value));
    });
  }
}

// dart format on
