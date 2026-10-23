// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'gpu_hardware_config.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$GpuHardwareConfig {

 GpuEffect get effect;/// 0–10.
 int get speed;/// 0–10.
 int get brightness;/// Single color of effects without a palette.
 Rgb get color; List<Rgb> get colors;
/// Create a copy of GpuHardwareConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GpuHardwareConfigCopyWith<GpuHardwareConfig> get copyWith => _$GpuHardwareConfigCopyWithImpl<GpuHardwareConfig>(this as GpuHardwareConfig, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as GpuHardwareConfig;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GpuHardwareConfig&&(identical(other.effect, _this.effect) || other.effect == _this.effect)&&(identical(other.speed, _this.speed) || other.speed == _this.speed)&&(identical(other.brightness, _this.brightness) || other.brightness == _this.brightness)&&(identical(other.color, _this.color) || other.color == _this.color)&&const DeepCollectionEquality().equals(other.colors, _this.colors));
}


@override
int get hashCode {
  final _this = this as GpuHardwareConfig;
  return Object.hash(runtimeType,_this.effect,_this.speed,_this.brightness,_this.color,const DeepCollectionEquality().hash(_this.colors));
}

@override
String toString() {
  final _this = this as GpuHardwareConfig;
  return 'GpuHardwareConfig(effect: ${_this.effect}, speed: ${_this.speed}, brightness: ${_this.brightness}, color: ${_this.color}, colors: ${_this.colors})';
}


}

/// @nodoc
abstract mixin class $GpuHardwareConfigCopyWith<$Res>  {
  factory $GpuHardwareConfigCopyWith(GpuHardwareConfig value, $Res Function(GpuHardwareConfig) _then) = _$GpuHardwareConfigCopyWithImpl;
@useResult
$Res call({
 GpuEffect effect, int speed, int brightness, Rgb color, List<Rgb> colors
});




}
/// @nodoc
class _$GpuHardwareConfigCopyWithImpl<$Res>
    implements $GpuHardwareConfigCopyWith<$Res> {
  _$GpuHardwareConfigCopyWithImpl(this._self, this._then);

  final GpuHardwareConfig _self;
  final $Res Function(GpuHardwareConfig) _then;

/// Create a copy of GpuHardwareConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? effect = null,Object? speed = null,Object? brightness = null,Object? color = null,Object? colors = null,}) {
  return _then(GpuHardwareConfig(
effect: null == effect ? _self.effect : effect // ignore: cast_nullable_to_non_nullable
as GpuEffect,speed: null == speed ? _self.speed : speed // ignore: cast_nullable_to_non_nullable
as int,brightness: null == brightness ? _self.brightness : brightness // ignore: cast_nullable_to_non_nullable
as int,color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as Rgb,colors: null == colors ? _self.colors : colors // ignore: cast_nullable_to_non_nullable
as List<Rgb>,
  ));
}

}


/// Adds pattern-matching-related methods to [GpuHardwareConfig].
extension GpuHardwareConfigPatterns on GpuHardwareConfig {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GpuHardwareConfig value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GpuHardwareConfig() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GpuHardwareConfig value)  $default,){
final _that = this;
switch (_that) {
case _GpuHardwareConfig():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GpuHardwareConfig value)?  $default,){
final _that = this;
switch (_that) {
case _GpuHardwareConfig() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( GpuEffect effect,  int speed,  int brightness,  Rgb color,  List<Rgb> colors)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GpuHardwareConfig() when $default != null:
return $default(_that.effect,_that.speed,_that.brightness,_that.color,_that.colors);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( GpuEffect effect,  int speed,  int brightness,  Rgb color,  List<Rgb> colors)  $default,) {final _that = this;
switch (_that) {
case _GpuHardwareConfig():
return $default(_that.effect,_that.speed,_that.brightness,_that.color,_that.colors);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( GpuEffect effect,  int speed,  int brightness,  Rgb color,  List<Rgb> colors)?  $default,) {final _that = this;
switch (_that) {
case _GpuHardwareConfig() when $default != null:
return $default(_that.effect,_that.speed,_that.brightness,_that.color,_that.colors);case _:
  return null;

}
}

}

/// @nodoc


class _GpuHardwareConfig implements GpuHardwareConfig {
  const _GpuHardwareConfig({this.effect = GpuEffect.pulse, this.speed = 5, this.brightness = 10, this.color = Rgb.white,  List<Rgb> colors = _gpuDefaultColors}): _colors = colors;
  

@override@JsonKey() final  GpuEffect effect;
/// 0–10.
@override@JsonKey() final  int speed;
/// 0–10.
@override@JsonKey() final  int brightness;
/// Single color of effects without a palette.
@override@JsonKey() final  Rgb color;
 final  List<Rgb> _colors;
@override@JsonKey() List<Rgb> get colors {
  if (_colors is EqualUnmodifiableListView) return _colors;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_colors);
}


/// Create a copy of GpuHardwareConfig
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GpuHardwareConfigCopyWith<_GpuHardwareConfig> get copyWith => __$GpuHardwareConfigCopyWithImpl<_GpuHardwareConfig>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _GpuHardwareConfig&&(identical(other.effect, effect) || other.effect == effect)&&(identical(other.speed, speed) || other.speed == speed)&&(identical(other.brightness, brightness) || other.brightness == brightness)&&(identical(other.color, color) || other.color == color)&&const DeepCollectionEquality().equals(other.colors, _colors));
}


@override
int get hashCode {
    return Object.hash(runtimeType,effect,speed,brightness,color,const DeepCollectionEquality().hash(_colors));
}

@override
String toString() {
    return 'GpuHardwareConfig(effect: $effect, speed: $speed, brightness: $brightness, color: $color, colors: $colors)';
}


}

/// @nodoc
abstract mixin class _$GpuHardwareConfigCopyWith<$Res> implements $GpuHardwareConfigCopyWith<$Res> {
  factory _$GpuHardwareConfigCopyWith(_GpuHardwareConfig value, $Res Function(_GpuHardwareConfig) _then) = __$GpuHardwareConfigCopyWithImpl;
@override @useResult
$Res call({
 GpuEffect effect, int speed, int brightness, Rgb color, List<Rgb> colors
});




}
/// @nodoc
class __$GpuHardwareConfigCopyWithImpl<$Res>
    implements _$GpuHardwareConfigCopyWith<$Res> {
  __$GpuHardwareConfigCopyWithImpl(this._self, this._then);

  final _GpuHardwareConfig _self;
  final $Res Function(_GpuHardwareConfig) _then;

/// Create a copy of GpuHardwareConfig
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? effect = null,Object? speed = null,Object? brightness = null,Object? color = null,Object? colors = null,}) {
  return _then(_GpuHardwareConfig(
effect: null == effect ? _self.effect : effect // ignore: cast_nullable_to_non_nullable
as GpuEffect,speed: null == speed ? _self.speed : speed // ignore: cast_nullable_to_non_nullable
as int,brightness: null == brightness ? _self.brightness : brightness // ignore: cast_nullable_to_non_nullable
as int,color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as Rgb,colors: null == colors ? _self._colors : colors // ignore: cast_nullable_to_non_nullable
as List<Rgb>,
  ));
}


}

// dart format on
