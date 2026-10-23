// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'board_zone_config.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$BoardZoneConfig {

 BoardEffectMode get mode; Rgb get color;/// 0–9.
 int get speed;/// 0–9.
 int get brightness;
/// Create a copy of BoardZoneConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BoardZoneConfigCopyWith<BoardZoneConfig> get copyWith => _$BoardZoneConfigCopyWithImpl<BoardZoneConfig>(this as BoardZoneConfig, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as BoardZoneConfig;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BoardZoneConfig&&(identical(other.mode, _this.mode) || other.mode == _this.mode)&&(identical(other.color, _this.color) || other.color == _this.color)&&(identical(other.speed, _this.speed) || other.speed == _this.speed)&&(identical(other.brightness, _this.brightness) || other.brightness == _this.brightness));
}


@override
int get hashCode {
  final _this = this as BoardZoneConfig;
  return Object.hash(runtimeType,_this.mode,_this.color,_this.speed,_this.brightness);
}

@override
String toString() {
  final _this = this as BoardZoneConfig;
  return 'BoardZoneConfig(mode: ${_this.mode}, color: ${_this.color}, speed: ${_this.speed}, brightness: ${_this.brightness})';
}


}

/// @nodoc
abstract mixin class $BoardZoneConfigCopyWith<$Res>  {
  factory $BoardZoneConfigCopyWith(BoardZoneConfig value, $Res Function(BoardZoneConfig) _then) = _$BoardZoneConfigCopyWithImpl;
@useResult
$Res call({
 BoardEffectMode mode, Rgb color, int speed, int brightness
});




}
/// @nodoc
class _$BoardZoneConfigCopyWithImpl<$Res>
    implements $BoardZoneConfigCopyWith<$Res> {
  _$BoardZoneConfigCopyWithImpl(this._self, this._then);

  final BoardZoneConfig _self;
  final $Res Function(BoardZoneConfig) _then;

/// Create a copy of BoardZoneConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? mode = null,Object? color = null,Object? speed = null,Object? brightness = null,}) {
  return _then(BoardZoneConfig(
mode: null == mode ? _self.mode : mode // ignore: cast_nullable_to_non_nullable
as BoardEffectMode,color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as Rgb,speed: null == speed ? _self.speed : speed // ignore: cast_nullable_to_non_nullable
as int,brightness: null == brightness ? _self.brightness : brightness // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [BoardZoneConfig].
extension BoardZoneConfigPatterns on BoardZoneConfig {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BoardZoneConfig value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BoardZoneConfig() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BoardZoneConfig value)  $default,){
final _that = this;
switch (_that) {
case _BoardZoneConfig():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BoardZoneConfig value)?  $default,){
final _that = this;
switch (_that) {
case _BoardZoneConfig() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( BoardEffectMode mode,  Rgb color,  int speed,  int brightness)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BoardZoneConfig() when $default != null:
return $default(_that.mode,_that.color,_that.speed,_that.brightness);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( BoardEffectMode mode,  Rgb color,  int speed,  int brightness)  $default,) {final _that = this;
switch (_that) {
case _BoardZoneConfig():
return $default(_that.mode,_that.color,_that.speed,_that.brightness);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( BoardEffectMode mode,  Rgb color,  int speed,  int brightness)?  $default,) {final _that = this;
switch (_that) {
case _BoardZoneConfig() when $default != null:
return $default(_that.mode,_that.color,_that.speed,_that.brightness);case _:
  return null;

}
}

}

/// @nodoc


class _BoardZoneConfig implements BoardZoneConfig {
  const _BoardZoneConfig({this.mode = BoardEffectMode.static, this.color = Rgb.white, this.speed = 5, this.brightness = 9});
  

@override@JsonKey() final  BoardEffectMode mode;
@override@JsonKey() final  Rgb color;
/// 0–9.
@override@JsonKey() final  int speed;
/// 0–9.
@override@JsonKey() final  int brightness;

/// Create a copy of BoardZoneConfig
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BoardZoneConfigCopyWith<_BoardZoneConfig> get copyWith => __$BoardZoneConfigCopyWithImpl<_BoardZoneConfig>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BoardZoneConfig&&(identical(other.mode, mode) || other.mode == mode)&&(identical(other.color, color) || other.color == color)&&(identical(other.speed, speed) || other.speed == speed)&&(identical(other.brightness, brightness) || other.brightness == brightness));
}


@override
int get hashCode {
    return Object.hash(runtimeType,mode,color,speed,brightness);
}

@override
String toString() {
    return 'BoardZoneConfig(mode: $mode, color: $color, speed: $speed, brightness: $brightness)';
}


}

/// @nodoc
abstract mixin class _$BoardZoneConfigCopyWith<$Res> implements $BoardZoneConfigCopyWith<$Res> {
  factory _$BoardZoneConfigCopyWith(_BoardZoneConfig value, $Res Function(_BoardZoneConfig) _then) = __$BoardZoneConfigCopyWithImpl;
@override @useResult
$Res call({
 BoardEffectMode mode, Rgb color, int speed, int brightness
});




}
/// @nodoc
class __$BoardZoneConfigCopyWithImpl<$Res>
    implements _$BoardZoneConfigCopyWith<$Res> {
  __$BoardZoneConfigCopyWithImpl(this._self, this._then);

  final _BoardZoneConfig _self;
  final $Res Function(_BoardZoneConfig) _then;

/// Create a copy of BoardZoneConfig
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? mode = null,Object? color = null,Object? speed = null,Object? brightness = null,}) {
  return _then(_BoardZoneConfig(
mode: null == mode ? _self.mode : mode // ignore: cast_nullable_to_non_nullable
as BoardEffectMode,color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as Rgb,speed: null == speed ? _self.speed : speed // ignore: cast_nullable_to_non_nullable
as int,brightness: null == brightness ? _self.brightness : brightness // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
