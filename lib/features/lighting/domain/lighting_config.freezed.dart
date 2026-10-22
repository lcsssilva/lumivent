// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'lighting_config.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Alv2HardwareConfig {

 Alv2Scope get scope; String get mode;/// Speed level, 0–4 (2 = normal).
 int get speed;/// Brightness level, 0–4 (4 = 100%).
 int get brightness; bool get directionLeft; List<Rgb> get colors;
/// Create a copy of Alv2HardwareConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$Alv2HardwareConfigCopyWith<Alv2HardwareConfig> get copyWith => _$Alv2HardwareConfigCopyWithImpl<Alv2HardwareConfig>(this as Alv2HardwareConfig, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as Alv2HardwareConfig;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Alv2HardwareConfig&&(identical(other.scope, _this.scope) || other.scope == _this.scope)&&(identical(other.mode, _this.mode) || other.mode == _this.mode)&&(identical(other.speed, _this.speed) || other.speed == _this.speed)&&(identical(other.brightness, _this.brightness) || other.brightness == _this.brightness)&&(identical(other.directionLeft, _this.directionLeft) || other.directionLeft == _this.directionLeft)&&const DeepCollectionEquality().equals(other.colors, _this.colors));
}


@override
int get hashCode {
  final _this = this as Alv2HardwareConfig;
  return Object.hash(runtimeType,_this.scope,_this.mode,_this.speed,_this.brightness,_this.directionLeft,const DeepCollectionEquality().hash(_this.colors));
}

@override
String toString() {
  final _this = this as Alv2HardwareConfig;
  return 'Alv2HardwareConfig(scope: ${_this.scope}, mode: ${_this.mode}, speed: ${_this.speed}, brightness: ${_this.brightness}, directionLeft: ${_this.directionLeft}, colors: ${_this.colors})';
}


}

/// @nodoc
abstract mixin class $Alv2HardwareConfigCopyWith<$Res>  {
  factory $Alv2HardwareConfigCopyWith(Alv2HardwareConfig value, $Res Function(Alv2HardwareConfig) _then) = _$Alv2HardwareConfigCopyWithImpl;
@useResult
$Res call({
 Alv2Scope scope, String mode, int speed, int brightness, bool directionLeft, List<Rgb> colors
});




}
/// @nodoc
class _$Alv2HardwareConfigCopyWithImpl<$Res>
    implements $Alv2HardwareConfigCopyWith<$Res> {
  _$Alv2HardwareConfigCopyWithImpl(this._self, this._then);

  final Alv2HardwareConfig _self;
  final $Res Function(Alv2HardwareConfig) _then;

/// Create a copy of Alv2HardwareConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? scope = null,Object? mode = null,Object? speed = null,Object? brightness = null,Object? directionLeft = null,Object? colors = null,}) {
  return _then(Alv2HardwareConfig(
scope: null == scope ? _self.scope : scope // ignore: cast_nullable_to_non_nullable
as Alv2Scope,mode: null == mode ? _self.mode : mode // ignore: cast_nullable_to_non_nullable
as String,speed: null == speed ? _self.speed : speed // ignore: cast_nullable_to_non_nullable
as int,brightness: null == brightness ? _self.brightness : brightness // ignore: cast_nullable_to_non_nullable
as int,directionLeft: null == directionLeft ? _self.directionLeft : directionLeft // ignore: cast_nullable_to_non_nullable
as bool,colors: null == colors ? _self.colors : colors // ignore: cast_nullable_to_non_nullable
as List<Rgb>,
  ));
}

}


/// Adds pattern-matching-related methods to [Alv2HardwareConfig].
extension Alv2HardwareConfigPatterns on Alv2HardwareConfig {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Alv2HardwareConfig value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Alv2HardwareConfig() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Alv2HardwareConfig value)  $default,){
final _that = this;
switch (_that) {
case _Alv2HardwareConfig():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Alv2HardwareConfig value)?  $default,){
final _that = this;
switch (_that) {
case _Alv2HardwareConfig() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Alv2Scope scope,  String mode,  int speed,  int brightness,  bool directionLeft,  List<Rgb> colors)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Alv2HardwareConfig() when $default != null:
return $default(_that.scope,_that.mode,_that.speed,_that.brightness,_that.directionLeft,_that.colors);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Alv2Scope scope,  String mode,  int speed,  int brightness,  bool directionLeft,  List<Rgb> colors)  $default,) {final _that = this;
switch (_that) {
case _Alv2HardwareConfig():
return $default(_that.scope,_that.mode,_that.speed,_that.brightness,_that.directionLeft,_that.colors);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Alv2Scope scope,  String mode,  int speed,  int brightness,  bool directionLeft,  List<Rgb> colors)?  $default,) {final _that = this;
switch (_that) {
case _Alv2HardwareConfig() when $default != null:
return $default(_that.scope,_that.mode,_that.speed,_that.brightness,_that.directionLeft,_that.colors);case _:
  return null;

}
}

}

/// @nodoc


class _Alv2HardwareConfig implements Alv2HardwareConfig {
  const _Alv2HardwareConfig({this.scope = Alv2Scope.whole, this.mode = 'StaticColor', this.speed = 2, this.brightness = 4, this.directionLeft = false,  List<Rgb> colors = _alv2DefaultColors}): _colors = colors;
  

@override@JsonKey() final  Alv2Scope scope;
@override@JsonKey() final  String mode;
/// Speed level, 0–4 (2 = normal).
@override@JsonKey() final  int speed;
/// Brightness level, 0–4 (4 = 100%).
@override@JsonKey() final  int brightness;
@override@JsonKey() final  bool directionLeft;
 final  List<Rgb> _colors;
@override@JsonKey() List<Rgb> get colors {
  if (_colors is EqualUnmodifiableListView) return _colors;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_colors);
}


/// Create a copy of Alv2HardwareConfig
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$Alv2HardwareConfigCopyWith<_Alv2HardwareConfig> get copyWith => __$Alv2HardwareConfigCopyWithImpl<_Alv2HardwareConfig>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Alv2HardwareConfig&&(identical(other.scope, scope) || other.scope == scope)&&(identical(other.mode, mode) || other.mode == mode)&&(identical(other.speed, speed) || other.speed == speed)&&(identical(other.brightness, brightness) || other.brightness == brightness)&&(identical(other.directionLeft, directionLeft) || other.directionLeft == directionLeft)&&const DeepCollectionEquality().equals(other.colors, _colors));
}


@override
int get hashCode {
    return Object.hash(runtimeType,scope,mode,speed,brightness,directionLeft,const DeepCollectionEquality().hash(_colors));
}

@override
String toString() {
    return 'Alv2HardwareConfig(scope: $scope, mode: $mode, speed: $speed, brightness: $brightness, directionLeft: $directionLeft, colors: $colors)';
}


}

/// @nodoc
abstract mixin class _$Alv2HardwareConfigCopyWith<$Res> implements $Alv2HardwareConfigCopyWith<$Res> {
  factory _$Alv2HardwareConfigCopyWith(_Alv2HardwareConfig value, $Res Function(_Alv2HardwareConfig) _then) = __$Alv2HardwareConfigCopyWithImpl;
@override @useResult
$Res call({
 Alv2Scope scope, String mode, int speed, int brightness, bool directionLeft, List<Rgb> colors
});




}
/// @nodoc
class __$Alv2HardwareConfigCopyWithImpl<$Res>
    implements _$Alv2HardwareConfigCopyWith<$Res> {
  __$Alv2HardwareConfigCopyWithImpl(this._self, this._then);

  final _Alv2HardwareConfig _self;
  final $Res Function(_Alv2HardwareConfig) _then;

/// Create a copy of Alv2HardwareConfig
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? scope = null,Object? mode = null,Object? speed = null,Object? brightness = null,Object? directionLeft = null,Object? colors = null,}) {
  return _then(_Alv2HardwareConfig(
scope: null == scope ? _self.scope : scope // ignore: cast_nullable_to_non_nullable
as Alv2Scope,mode: null == mode ? _self.mode : mode // ignore: cast_nullable_to_non_nullable
as String,speed: null == speed ? _self.speed : speed // ignore: cast_nullable_to_non_nullable
as int,brightness: null == brightness ? _self.brightness : brightness // ignore: cast_nullable_to_non_nullable
as int,directionLeft: null == directionLeft ? _self.directionLeft : directionLeft // ignore: cast_nullable_to_non_nullable
as bool,colors: null == colors ? _self._colors : colors // ignore: cast_nullable_to_non_nullable
as List<Rgb>,
  ));
}


}

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
  const _GpuHardwareConfig({this.effect = GpuEffect.pulse, this.speed = 5, this.brightness = 10, this.color = Rgb.white,  List<Rgb> colors = _alv2DefaultColors}): _colors = colors;
  

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

/// @nodoc
mixin _$DeviceLightConfig {

 bool get enabled; LightMode get mode; Rgb get fixedColor; CanvasRect get placement;
/// Create a copy of DeviceLightConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DeviceLightConfigCopyWith<DeviceLightConfig> get copyWith => _$DeviceLightConfigCopyWithImpl<DeviceLightConfig>(this as DeviceLightConfig, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as DeviceLightConfig;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DeviceLightConfig&&(identical(other.enabled, _this.enabled) || other.enabled == _this.enabled)&&(identical(other.mode, _this.mode) || other.mode == _this.mode)&&(identical(other.fixedColor, _this.fixedColor) || other.fixedColor == _this.fixedColor)&&(identical(other.placement, _this.placement) || other.placement == _this.placement));
}


@override
int get hashCode {
  final _this = this as DeviceLightConfig;
  return Object.hash(runtimeType,_this.enabled,_this.mode,_this.fixedColor,_this.placement);
}

@override
String toString() {
  final _this = this as DeviceLightConfig;
  return 'DeviceLightConfig(enabled: ${_this.enabled}, mode: ${_this.mode}, fixedColor: ${_this.fixedColor}, placement: ${_this.placement})';
}


}

/// @nodoc
abstract mixin class $DeviceLightConfigCopyWith<$Res>  {
  factory $DeviceLightConfigCopyWith(DeviceLightConfig value, $Res Function(DeviceLightConfig) _then) = _$DeviceLightConfigCopyWithImpl;
@useResult
$Res call({
 bool enabled, LightMode mode, Rgb fixedColor, CanvasRect placement
});




}
/// @nodoc
class _$DeviceLightConfigCopyWithImpl<$Res>
    implements $DeviceLightConfigCopyWith<$Res> {
  _$DeviceLightConfigCopyWithImpl(this._self, this._then);

  final DeviceLightConfig _self;
  final $Res Function(DeviceLightConfig) _then;

/// Create a copy of DeviceLightConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? enabled = null,Object? mode = null,Object? fixedColor = null,Object? placement = null,}) {
  return _then(DeviceLightConfig(
enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,mode: null == mode ? _self.mode : mode // ignore: cast_nullable_to_non_nullable
as LightMode,fixedColor: null == fixedColor ? _self.fixedColor : fixedColor // ignore: cast_nullable_to_non_nullable
as Rgb,placement: null == placement ? _self.placement : placement // ignore: cast_nullable_to_non_nullable
as CanvasRect,
  ));
}

}


/// Adds pattern-matching-related methods to [DeviceLightConfig].
extension DeviceLightConfigPatterns on DeviceLightConfig {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DeviceLightConfig value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DeviceLightConfig() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DeviceLightConfig value)  $default,){
final _that = this;
switch (_that) {
case _DeviceLightConfig():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DeviceLightConfig value)?  $default,){
final _that = this;
switch (_that) {
case _DeviceLightConfig() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool enabled,  LightMode mode,  Rgb fixedColor,  CanvasRect placement)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DeviceLightConfig() when $default != null:
return $default(_that.enabled,_that.mode,_that.fixedColor,_that.placement);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool enabled,  LightMode mode,  Rgb fixedColor,  CanvasRect placement)  $default,) {final _that = this;
switch (_that) {
case _DeviceLightConfig():
return $default(_that.enabled,_that.mode,_that.fixedColor,_that.placement);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool enabled,  LightMode mode,  Rgb fixedColor,  CanvasRect placement)?  $default,) {final _that = this;
switch (_that) {
case _DeviceLightConfig() when $default != null:
return $default(_that.enabled,_that.mode,_that.fixedColor,_that.placement);case _:
  return null;

}
}

}

/// @nodoc


class _DeviceLightConfig implements DeviceLightConfig {
  const _DeviceLightConfig({this.enabled = true, this.mode = LightMode.canvas, this.fixedColor = Rgb.white, required this.placement});
  

@override@JsonKey() final  bool enabled;
@override@JsonKey() final  LightMode mode;
@override@JsonKey() final  Rgb fixedColor;
@override final  CanvasRect placement;

/// Create a copy of DeviceLightConfig
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DeviceLightConfigCopyWith<_DeviceLightConfig> get copyWith => __$DeviceLightConfigCopyWithImpl<_DeviceLightConfig>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _DeviceLightConfig&&(identical(other.enabled, enabled) || other.enabled == enabled)&&(identical(other.mode, mode) || other.mode == mode)&&(identical(other.fixedColor, fixedColor) || other.fixedColor == fixedColor)&&(identical(other.placement, placement) || other.placement == placement));
}


@override
int get hashCode {
    return Object.hash(runtimeType,enabled,mode,fixedColor,placement);
}

@override
String toString() {
    return 'DeviceLightConfig(enabled: $enabled, mode: $mode, fixedColor: $fixedColor, placement: $placement)';
}


}

/// @nodoc
abstract mixin class _$DeviceLightConfigCopyWith<$Res> implements $DeviceLightConfigCopyWith<$Res> {
  factory _$DeviceLightConfigCopyWith(_DeviceLightConfig value, $Res Function(_DeviceLightConfig) _then) = __$DeviceLightConfigCopyWithImpl;
@override @useResult
$Res call({
 bool enabled, LightMode mode, Rgb fixedColor, CanvasRect placement
});




}
/// @nodoc
class __$DeviceLightConfigCopyWithImpl<$Res>
    implements _$DeviceLightConfigCopyWith<$Res> {
  __$DeviceLightConfigCopyWithImpl(this._self, this._then);

  final _DeviceLightConfig _self;
  final $Res Function(_DeviceLightConfig) _then;

/// Create a copy of DeviceLightConfig
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? enabled = null,Object? mode = null,Object? fixedColor = null,Object? placement = null,}) {
  return _then(_DeviceLightConfig(
enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,mode: null == mode ? _self.mode : mode // ignore: cast_nullable_to_non_nullable
as LightMode,fixedColor: null == fixedColor ? _self.fixedColor : fixedColor // ignore: cast_nullable_to_non_nullable
as Rgb,placement: null == placement ? _self.placement : placement // ignore: cast_nullable_to_non_nullable
as CanvasRect,
  ));
}


}

/// @nodoc
mixin _$LightingConfig {

 bool get argbOff; double get brightness; bool get offOnSleep; bool get autoHardware; String get effectId; Map<String, Map<String, Object?>> get effectValues; Map<LightDeviceId, DeviceLightConfig> get devices; List<int> get fanQuantity; List<Alv2HardwareConfig> get alv2Hardware; bool get alv2Merge; String get alv2MergeMode; List<int> get alv2MergeOrder; Map<int, BoardZoneConfig> get boardZones; GpuHardwareConfig get gpuHardware;



@override
bool operator ==(Object other) {
  final _this = this as LightingConfig;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LightingConfig&&(identical(other.argbOff, _this.argbOff) || other.argbOff == _this.argbOff)&&(identical(other.brightness, _this.brightness) || other.brightness == _this.brightness)&&(identical(other.offOnSleep, _this.offOnSleep) || other.offOnSleep == _this.offOnSleep)&&(identical(other.autoHardware, _this.autoHardware) || other.autoHardware == _this.autoHardware)&&(identical(other.effectId, _this.effectId) || other.effectId == _this.effectId)&&const DeepCollectionEquality().equals(other.effectValues, _this.effectValues)&&const DeepCollectionEquality().equals(other.devices, _this.devices)&&const DeepCollectionEquality().equals(other.fanQuantity, _this.fanQuantity)&&const DeepCollectionEquality().equals(other.alv2Hardware, _this.alv2Hardware)&&(identical(other.alv2Merge, _this.alv2Merge) || other.alv2Merge == _this.alv2Merge)&&(identical(other.alv2MergeMode, _this.alv2MergeMode) || other.alv2MergeMode == _this.alv2MergeMode)&&const DeepCollectionEquality().equals(other.alv2MergeOrder, _this.alv2MergeOrder)&&const DeepCollectionEquality().equals(other.boardZones, _this.boardZones)&&(identical(other.gpuHardware, _this.gpuHardware) || other.gpuHardware == _this.gpuHardware));
}


@override
int get hashCode {
  final _this = this as LightingConfig;
  return Object.hash(runtimeType,_this.argbOff,_this.brightness,_this.offOnSleep,_this.autoHardware,_this.effectId,const DeepCollectionEquality().hash(_this.effectValues),const DeepCollectionEquality().hash(_this.devices),const DeepCollectionEquality().hash(_this.fanQuantity),const DeepCollectionEquality().hash(_this.alv2Hardware),_this.alv2Merge,_this.alv2MergeMode,const DeepCollectionEquality().hash(_this.alv2MergeOrder),const DeepCollectionEquality().hash(_this.boardZones),_this.gpuHardware);
}

@override
String toString() {
  final _this = this as LightingConfig;
  return 'LightingConfig(argbOff: ${_this.argbOff}, brightness: ${_this.brightness}, offOnSleep: ${_this.offOnSleep}, autoHardware: ${_this.autoHardware}, effectId: ${_this.effectId}, effectValues: ${_this.effectValues}, devices: ${_this.devices}, fanQuantity: ${_this.fanQuantity}, alv2Hardware: ${_this.alv2Hardware}, alv2Merge: ${_this.alv2Merge}, alv2MergeMode: ${_this.alv2MergeMode}, alv2MergeOrder: ${_this.alv2MergeOrder}, boardZones: ${_this.boardZones}, gpuHardware: ${_this.gpuHardware})';
}


}




/// Adds pattern-matching-related methods to [LightingConfig].
extension LightingConfigPatterns on LightingConfig {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( _LightingConfig value)?  raw,required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LightingConfig() when raw != null:
return raw(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( _LightingConfig value)  raw,}){
final _that = this;
switch (_that) {
case _LightingConfig():
return raw(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( _LightingConfig value)?  raw,}){
final _that = this;
switch (_that) {
case _LightingConfig() when raw != null:
return raw(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( bool argbOff,  double brightness,  bool offOnSleep,  bool autoHardware,  String effectId,  Map<String, Map<String, Object?>> effectValues,  Map<LightDeviceId, DeviceLightConfig> devices,  List<int> fanQuantity,  List<Alv2HardwareConfig> alv2Hardware,  bool alv2Merge,  String alv2MergeMode,  List<int> alv2MergeOrder,  Map<int, BoardZoneConfig> boardZones,  GpuHardwareConfig gpuHardware)?  raw,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LightingConfig() when raw != null:
return raw(_that.argbOff,_that.brightness,_that.offOnSleep,_that.autoHardware,_that.effectId,_that.effectValues,_that.devices,_that.fanQuantity,_that.alv2Hardware,_that.alv2Merge,_that.alv2MergeMode,_that.alv2MergeOrder,_that.boardZones,_that.gpuHardware);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( bool argbOff,  double brightness,  bool offOnSleep,  bool autoHardware,  String effectId,  Map<String, Map<String, Object?>> effectValues,  Map<LightDeviceId, DeviceLightConfig> devices,  List<int> fanQuantity,  List<Alv2HardwareConfig> alv2Hardware,  bool alv2Merge,  String alv2MergeMode,  List<int> alv2MergeOrder,  Map<int, BoardZoneConfig> boardZones,  GpuHardwareConfig gpuHardware)  raw,}) {final _that = this;
switch (_that) {
case _LightingConfig():
return raw(_that.argbOff,_that.brightness,_that.offOnSleep,_that.autoHardware,_that.effectId,_that.effectValues,_that.devices,_that.fanQuantity,_that.alv2Hardware,_that.alv2Merge,_that.alv2MergeMode,_that.alv2MergeOrder,_that.boardZones,_that.gpuHardware);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( bool argbOff,  double brightness,  bool offOnSleep,  bool autoHardware,  String effectId,  Map<String, Map<String, Object?>> effectValues,  Map<LightDeviceId, DeviceLightConfig> devices,  List<int> fanQuantity,  List<Alv2HardwareConfig> alv2Hardware,  bool alv2Merge,  String alv2MergeMode,  List<int> alv2MergeOrder,  Map<int, BoardZoneConfig> boardZones,  GpuHardwareConfig gpuHardware)?  raw,}) {final _that = this;
switch (_that) {
case _LightingConfig() when raw != null:
return raw(_that.argbOff,_that.brightness,_that.offOnSleep,_that.autoHardware,_that.effectId,_that.effectValues,_that.devices,_that.fanQuantity,_that.alv2Hardware,_that.alv2Merge,_that.alv2MergeMode,_that.alv2MergeOrder,_that.boardZones,_that.gpuHardware);case _:
  return null;

}
}

}

/// @nodoc


class _LightingConfig implements LightingConfig {
  const _LightingConfig({this.argbOff = false, this.brightness = 1, this.offOnSleep = true, this.autoHardware = true, this.effectId = defaultEffectId,  Map<String, Map<String, Object?>> effectValues = const <String, Map<String, Object?>>{},  Map<LightDeviceId, DeviceLightConfig> devices = const <LightDeviceId, DeviceLightConfig>{},  List<int> fanQuantity = _defaultFanQuantity,  List<Alv2HardwareConfig> alv2Hardware = _defaultAlv2Hardware, this.alv2Merge = false, this.alv2MergeMode = 'Runway',  List<int> alv2MergeOrder = _defaultMergeOrder,  Map<int, BoardZoneConfig> boardZones = _defaultBoardZones, this.gpuHardware = _defaultGpuHardware}): _effectValues = effectValues,_devices = devices,_fanQuantity = fanQuantity,_alv2Hardware = alv2Hardware,_alv2MergeOrder = alv2MergeOrder,_boardZones = boardZones;
  

@override@JsonKey() final  bool argbOff;
@override@JsonKey() final  double brightness;
@override@JsonKey() final  bool offOnSleep;
@override@JsonKey() final  bool autoHardware;
@override@JsonKey() final  String effectId;
 final  Map<String, Map<String, Object?>> _effectValues;
@override@JsonKey() Map<String, Map<String, Object?>> get effectValues {
  if (_effectValues is EqualUnmodifiableMapView) return _effectValues;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_effectValues);
}

 final  Map<LightDeviceId, DeviceLightConfig> _devices;
@override@JsonKey() Map<LightDeviceId, DeviceLightConfig> get devices {
  if (_devices is EqualUnmodifiableMapView) return _devices;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_devices);
}

 final  List<int> _fanQuantity;
@override@JsonKey() List<int> get fanQuantity {
  if (_fanQuantity is EqualUnmodifiableListView) return _fanQuantity;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_fanQuantity);
}

 final  List<Alv2HardwareConfig> _alv2Hardware;
@override@JsonKey() List<Alv2HardwareConfig> get alv2Hardware {
  if (_alv2Hardware is EqualUnmodifiableListView) return _alv2Hardware;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_alv2Hardware);
}

@override@JsonKey() final  bool alv2Merge;
@override@JsonKey() final  String alv2MergeMode;
 final  List<int> _alv2MergeOrder;
@override@JsonKey() List<int> get alv2MergeOrder {
  if (_alv2MergeOrder is EqualUnmodifiableListView) return _alv2MergeOrder;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_alv2MergeOrder);
}

 final  Map<int, BoardZoneConfig> _boardZones;
@override@JsonKey() Map<int, BoardZoneConfig> get boardZones {
  if (_boardZones is EqualUnmodifiableMapView) return _boardZones;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_boardZones);
}

@override@JsonKey() final  GpuHardwareConfig gpuHardware;




@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _LightingConfig&&(identical(other.argbOff, argbOff) || other.argbOff == argbOff)&&(identical(other.brightness, brightness) || other.brightness == brightness)&&(identical(other.offOnSleep, offOnSleep) || other.offOnSleep == offOnSleep)&&(identical(other.autoHardware, autoHardware) || other.autoHardware == autoHardware)&&(identical(other.effectId, effectId) || other.effectId == effectId)&&const DeepCollectionEquality().equals(other.effectValues, _effectValues)&&const DeepCollectionEquality().equals(other.devices, _devices)&&const DeepCollectionEquality().equals(other.fanQuantity, _fanQuantity)&&const DeepCollectionEquality().equals(other.alv2Hardware, _alv2Hardware)&&(identical(other.alv2Merge, alv2Merge) || other.alv2Merge == alv2Merge)&&(identical(other.alv2MergeMode, alv2MergeMode) || other.alv2MergeMode == alv2MergeMode)&&const DeepCollectionEquality().equals(other.alv2MergeOrder, _alv2MergeOrder)&&const DeepCollectionEquality().equals(other.boardZones, _boardZones)&&(identical(other.gpuHardware, gpuHardware) || other.gpuHardware == gpuHardware));
}


@override
int get hashCode {
    return Object.hash(runtimeType,argbOff,brightness,offOnSleep,autoHardware,effectId,const DeepCollectionEquality().hash(_effectValues),const DeepCollectionEquality().hash(_devices),const DeepCollectionEquality().hash(_fanQuantity),const DeepCollectionEquality().hash(_alv2Hardware),alv2Merge,alv2MergeMode,const DeepCollectionEquality().hash(_alv2MergeOrder),const DeepCollectionEquality().hash(_boardZones),gpuHardware);
}

@override
String toString() {
    return 'LightingConfig.raw(argbOff: $argbOff, brightness: $brightness, offOnSleep: $offOnSleep, autoHardware: $autoHardware, effectId: $effectId, effectValues: $effectValues, devices: $devices, fanQuantity: $fanQuantity, alv2Hardware: $alv2Hardware, alv2Merge: $alv2Merge, alv2MergeMode: $alv2MergeMode, alv2MergeOrder: $alv2MergeOrder, boardZones: $boardZones, gpuHardware: $gpuHardware)';
}


}




// dart format on
