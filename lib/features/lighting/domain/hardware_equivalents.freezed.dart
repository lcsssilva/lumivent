// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'hardware_equivalents.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$HardwareEquivalent {

/// For every fan group in Canvas.
 Alv2HardwareConfig get fans;/// For every motherboard zone, when the board is in Canvas; `null` when the
/// firmware has no equivalent for the zones (they stay in Canvas).
 BoardZoneConfig? get board;/// For the GPU, when the firmware has a matching effect; `null` leaves it
/// in Canvas (average color).
 GpuHardwareConfig? get gpu;
/// Create a copy of HardwareEquivalent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HardwareEquivalentCopyWith<HardwareEquivalent> get copyWith => _$HardwareEquivalentCopyWithImpl<HardwareEquivalent>(this as HardwareEquivalent, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as HardwareEquivalent;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HardwareEquivalent&&(identical(other.fans, _this.fans) || other.fans == _this.fans)&&(identical(other.board, _this.board) || other.board == _this.board)&&(identical(other.gpu, _this.gpu) || other.gpu == _this.gpu));
}


@override
int get hashCode {
  final _this = this as HardwareEquivalent;
  return Object.hash(runtimeType,_this.fans,_this.board,_this.gpu);
}

@override
String toString() {
  final _this = this as HardwareEquivalent;
  return 'HardwareEquivalent(fans: ${_this.fans}, board: ${_this.board}, gpu: ${_this.gpu})';
}


}

/// @nodoc
abstract mixin class $HardwareEquivalentCopyWith<$Res>  {
  factory $HardwareEquivalentCopyWith(HardwareEquivalent value, $Res Function(HardwareEquivalent) _then) = _$HardwareEquivalentCopyWithImpl;
@useResult
$Res call({
 Alv2HardwareConfig fans, BoardZoneConfig? board, GpuHardwareConfig? gpu
});


$Alv2HardwareConfigCopyWith<$Res> get fans;$BoardZoneConfigCopyWith<$Res>? get board;$GpuHardwareConfigCopyWith<$Res>? get gpu;

}
/// @nodoc
class _$HardwareEquivalentCopyWithImpl<$Res>
    implements $HardwareEquivalentCopyWith<$Res> {
  _$HardwareEquivalentCopyWithImpl(this._self, this._then);

  final HardwareEquivalent _self;
  final $Res Function(HardwareEquivalent) _then;

/// Create a copy of HardwareEquivalent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? fans = null,Object? board = freezed,Object? gpu = freezed,}) {
  return _then(HardwareEquivalent(
fans: null == fans ? _self.fans : fans // ignore: cast_nullable_to_non_nullable
as Alv2HardwareConfig,board: freezed == board ? _self.board : board // ignore: cast_nullable_to_non_nullable
as BoardZoneConfig?,gpu: freezed == gpu ? _self.gpu : gpu // ignore: cast_nullable_to_non_nullable
as GpuHardwareConfig?,
  ));
}
/// Create a copy of HardwareEquivalent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$Alv2HardwareConfigCopyWith<$Res> get fans {
  
  return $Alv2HardwareConfigCopyWith<$Res>(_self.fans, (value) {
    return _then(_self.copyWith(fans: value));
  });
}/// Create a copy of HardwareEquivalent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BoardZoneConfigCopyWith<$Res>? get board {
    if (_self.board == null) {
    return null;
  }

  return $BoardZoneConfigCopyWith<$Res>(_self.board!, (value) {
    return _then(_self.copyWith(board: value));
  });
}/// Create a copy of HardwareEquivalent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GpuHardwareConfigCopyWith<$Res>? get gpu {
    if (_self.gpu == null) {
    return null;
  }

  return $GpuHardwareConfigCopyWith<$Res>(_self.gpu!, (value) {
    return _then(_self.copyWith(gpu: value));
  });
}
}


/// Adds pattern-matching-related methods to [HardwareEquivalent].
extension HardwareEquivalentPatterns on HardwareEquivalent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HardwareEquivalent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HardwareEquivalent() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HardwareEquivalent value)  $default,){
final _that = this;
switch (_that) {
case _HardwareEquivalent():
return $default(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HardwareEquivalent value)?  $default,){
final _that = this;
switch (_that) {
case _HardwareEquivalent() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Alv2HardwareConfig fans,  BoardZoneConfig? board,  GpuHardwareConfig? gpu)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HardwareEquivalent() when $default != null:
return $default(_that.fans,_that.board,_that.gpu);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Alv2HardwareConfig fans,  BoardZoneConfig? board,  GpuHardwareConfig? gpu)  $default,) {final _that = this;
switch (_that) {
case _HardwareEquivalent():
return $default(_that.fans,_that.board,_that.gpu);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Alv2HardwareConfig fans,  BoardZoneConfig? board,  GpuHardwareConfig? gpu)?  $default,) {final _that = this;
switch (_that) {
case _HardwareEquivalent() when $default != null:
return $default(_that.fans,_that.board,_that.gpu);case _:
  return null;

}
}

}

/// @nodoc


class _HardwareEquivalent implements HardwareEquivalent {
  const _HardwareEquivalent({required this.fans, required this.board, this.gpu});
  

/// For every fan group in Canvas.
@override final  Alv2HardwareConfig fans;
/// For every motherboard zone, when the board is in Canvas; `null` when the
/// firmware has no equivalent for the zones (they stay in Canvas).
@override final  BoardZoneConfig? board;
/// For the GPU, when the firmware has a matching effect; `null` leaves it
/// in Canvas (average color).
@override final  GpuHardwareConfig? gpu;

/// Create a copy of HardwareEquivalent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HardwareEquivalentCopyWith<_HardwareEquivalent> get copyWith => __$HardwareEquivalentCopyWithImpl<_HardwareEquivalent>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _HardwareEquivalent&&(identical(other.fans, fans) || other.fans == fans)&&(identical(other.board, board) || other.board == board)&&(identical(other.gpu, gpu) || other.gpu == gpu));
}


@override
int get hashCode {
    return Object.hash(runtimeType,fans,board,gpu);
}

@override
String toString() {
    return 'HardwareEquivalent(fans: $fans, board: $board, gpu: $gpu)';
}


}

/// @nodoc
abstract mixin class _$HardwareEquivalentCopyWith<$Res> implements $HardwareEquivalentCopyWith<$Res> {
  factory _$HardwareEquivalentCopyWith(_HardwareEquivalent value, $Res Function(_HardwareEquivalent) _then) = __$HardwareEquivalentCopyWithImpl;
@override @useResult
$Res call({
 Alv2HardwareConfig fans, BoardZoneConfig? board, GpuHardwareConfig? gpu
});


@override $Alv2HardwareConfigCopyWith<$Res> get fans;@override $BoardZoneConfigCopyWith<$Res>? get board;@override $GpuHardwareConfigCopyWith<$Res>? get gpu;

}
/// @nodoc
class __$HardwareEquivalentCopyWithImpl<$Res>
    implements _$HardwareEquivalentCopyWith<$Res> {
  __$HardwareEquivalentCopyWithImpl(this._self, this._then);

  final _HardwareEquivalent _self;
  final $Res Function(_HardwareEquivalent) _then;

/// Create a copy of HardwareEquivalent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? fans = null,Object? board = freezed,Object? gpu = freezed,}) {
  return _then(_HardwareEquivalent(
fans: null == fans ? _self.fans : fans // ignore: cast_nullable_to_non_nullable
as Alv2HardwareConfig,board: freezed == board ? _self.board : board // ignore: cast_nullable_to_non_nullable
as BoardZoneConfig?,gpu: freezed == gpu ? _self.gpu : gpu // ignore: cast_nullable_to_non_nullable
as GpuHardwareConfig?,
  ));
}

/// Create a copy of HardwareEquivalent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$Alv2HardwareConfigCopyWith<$Res> get fans {
  
  return $Alv2HardwareConfigCopyWith<$Res>(_self.fans, (value) {
    return _then(_self.copyWith(fans: value));
  });
}/// Create a copy of HardwareEquivalent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BoardZoneConfigCopyWith<$Res>? get board {
    if (_self.board == null) {
    return null;
  }

  return $BoardZoneConfigCopyWith<$Res>(_self.board!, (value) {
    return _then(_self.copyWith(board: value));
  });
}/// Create a copy of HardwareEquivalent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GpuHardwareConfigCopyWith<$Res>? get gpu {
    if (_self.gpu == null) {
    return null;
  }

  return $GpuHardwareConfigCopyWith<$Res>(_self.gpu!, (value) {
    return _then(_self.copyWith(gpu: value));
  });
}
}

// dart format on
