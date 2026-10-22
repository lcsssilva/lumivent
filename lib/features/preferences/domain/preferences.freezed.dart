// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'preferences.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Preferences {

/// Closing the window only hides it; the app remains in the system tray.
 bool get closeToTray; TemperatureUnit get temperatureUnit;/// Frames per second for the LED loop (the AL V2 is limited to ~15).
 int get effectsFps;/// UI language; missing or unknown values fall back to English.
 AppLanguage get language;
/// Create a copy of Preferences
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PreferencesCopyWith<Preferences> get copyWith => _$PreferencesCopyWithImpl<Preferences>(this as Preferences, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as Preferences;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Preferences&&(identical(other.closeToTray, _this.closeToTray) || other.closeToTray == _this.closeToTray)&&(identical(other.temperatureUnit, _this.temperatureUnit) || other.temperatureUnit == _this.temperatureUnit)&&(identical(other.effectsFps, _this.effectsFps) || other.effectsFps == _this.effectsFps)&&(identical(other.language, _this.language) || other.language == _this.language));
}


@override
int get hashCode {
  final _this = this as Preferences;
  return Object.hash(runtimeType,_this.closeToTray,_this.temperatureUnit,_this.effectsFps,_this.language);
}

@override
String toString() {
  final _this = this as Preferences;
  return 'Preferences(closeToTray: ${_this.closeToTray}, temperatureUnit: ${_this.temperatureUnit}, effectsFps: ${_this.effectsFps}, language: ${_this.language})';
}


}

/// @nodoc
abstract mixin class $PreferencesCopyWith<$Res>  {
  factory $PreferencesCopyWith(Preferences value, $Res Function(Preferences) _then) = _$PreferencesCopyWithImpl;
@useResult
$Res call({
 bool closeToTray, TemperatureUnit temperatureUnit, int effectsFps, AppLanguage language
});




}
/// @nodoc
class _$PreferencesCopyWithImpl<$Res>
    implements $PreferencesCopyWith<$Res> {
  _$PreferencesCopyWithImpl(this._self, this._then);

  final Preferences _self;
  final $Res Function(Preferences) _then;

/// Create a copy of Preferences
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? closeToTray = null,Object? temperatureUnit = null,Object? effectsFps = null,Object? language = null,}) {
  return _then(Preferences(
closeToTray: null == closeToTray ? _self.closeToTray : closeToTray // ignore: cast_nullable_to_non_nullable
as bool,temperatureUnit: null == temperatureUnit ? _self.temperatureUnit : temperatureUnit // ignore: cast_nullable_to_non_nullable
as TemperatureUnit,effectsFps: null == effectsFps ? _self.effectsFps : effectsFps // ignore: cast_nullable_to_non_nullable
as int,language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as AppLanguage,
  ));
}

}


/// Adds pattern-matching-related methods to [Preferences].
extension PreferencesPatterns on Preferences {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Preferences value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Preferences() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Preferences value)  $default,){
final _that = this;
switch (_that) {
case _Preferences():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Preferences value)?  $default,){
final _that = this;
switch (_that) {
case _Preferences() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool closeToTray,  TemperatureUnit temperatureUnit,  int effectsFps,  AppLanguage language)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Preferences() when $default != null:
return $default(_that.closeToTray,_that.temperatureUnit,_that.effectsFps,_that.language);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool closeToTray,  TemperatureUnit temperatureUnit,  int effectsFps,  AppLanguage language)  $default,) {final _that = this;
switch (_that) {
case _Preferences():
return $default(_that.closeToTray,_that.temperatureUnit,_that.effectsFps,_that.language);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool closeToTray,  TemperatureUnit temperatureUnit,  int effectsFps,  AppLanguage language)?  $default,) {final _that = this;
switch (_that) {
case _Preferences() when $default != null:
return $default(_that.closeToTray,_that.temperatureUnit,_that.effectsFps,_that.language);case _:
  return null;

}
}

}

/// @nodoc


class _Preferences implements Preferences {
  const _Preferences({this.closeToTray = true, this.temperatureUnit = TemperatureUnit.celsius, this.effectsFps = 30, this.language = AppLanguage.en});
  

/// Closing the window only hides it; the app remains in the system tray.
@override@JsonKey() final  bool closeToTray;
@override@JsonKey() final  TemperatureUnit temperatureUnit;
/// Frames per second for the LED loop (the AL V2 is limited to ~15).
@override@JsonKey() final  int effectsFps;
/// UI language; missing or unknown values fall back to English.
@override@JsonKey() final  AppLanguage language;

/// Create a copy of Preferences
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PreferencesCopyWith<_Preferences> get copyWith => __$PreferencesCopyWithImpl<_Preferences>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Preferences&&(identical(other.closeToTray, closeToTray) || other.closeToTray == closeToTray)&&(identical(other.temperatureUnit, temperatureUnit) || other.temperatureUnit == temperatureUnit)&&(identical(other.effectsFps, effectsFps) || other.effectsFps == effectsFps)&&(identical(other.language, language) || other.language == language));
}


@override
int get hashCode {
    return Object.hash(runtimeType,closeToTray,temperatureUnit,effectsFps,language);
}

@override
String toString() {
    return 'Preferences(closeToTray: $closeToTray, temperatureUnit: $temperatureUnit, effectsFps: $effectsFps, language: $language)';
}


}

/// @nodoc
abstract mixin class _$PreferencesCopyWith<$Res> implements $PreferencesCopyWith<$Res> {
  factory _$PreferencesCopyWith(_Preferences value, $Res Function(_Preferences) _then) = __$PreferencesCopyWithImpl;
@override @useResult
$Res call({
 bool closeToTray, TemperatureUnit temperatureUnit, int effectsFps, AppLanguage language
});




}
/// @nodoc
class __$PreferencesCopyWithImpl<$Res>
    implements _$PreferencesCopyWith<$Res> {
  __$PreferencesCopyWithImpl(this._self, this._then);

  final _Preferences _self;
  final $Res Function(_Preferences) _then;

/// Create a copy of Preferences
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? closeToTray = null,Object? temperatureUnit = null,Object? effectsFps = null,Object? language = null,}) {
  return _then(_Preferences(
closeToTray: null == closeToTray ? _self.closeToTray : closeToTray // ignore: cast_nullable_to_non_nullable
as bool,temperatureUnit: null == temperatureUnit ? _self.temperatureUnit : temperatureUnit // ignore: cast_nullable_to_non_nullable
as TemperatureUnit,effectsFps: null == effectsFps ? _self.effectsFps : effectsFps // ignore: cast_nullable_to_non_nullable
as int,language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as AppLanguage,
  ));
}


}

// dart format on
