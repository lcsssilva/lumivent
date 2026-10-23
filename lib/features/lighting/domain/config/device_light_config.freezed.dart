// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'device_light_config.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
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

// dart format on
