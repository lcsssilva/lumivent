// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'alv2_hardware_config.dart';

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

// dart format on
