// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'html_effect_runner.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$HtmlEffectStatus implements DiagnosticableTreeMixin {

/// Global effect id (`html:<id>`) currently rendered.
 String? get effectId; bool get loading;/// Stopped because frames take too long (an effect stuck in a loop).
 bool get paused;/// Reason the effect is not running; [error] carries technical detail.
 HtmlEffectIssue? get issue; List<String> get issueArgs; String? get error;/// Measured render FPS and mean frame time of the last second.
 double get fps; double get frameMs;
/// Create a copy of HtmlEffectStatus
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HtmlEffectStatusCopyWith<HtmlEffectStatus> get copyWith => _$HtmlEffectStatusCopyWithImpl<HtmlEffectStatus>(this as HtmlEffectStatus, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  final _this = this as HtmlEffectStatus;
  properties
    ..add(DiagnosticsProperty('type', 'HtmlEffectStatus'))
    ..add(DiagnosticsProperty('effectId', _this.effectId))..add(DiagnosticsProperty('loading', _this.loading))..add(DiagnosticsProperty('paused', _this.paused))..add(DiagnosticsProperty('issue', _this.issue))..add(DiagnosticsProperty('issueArgs', _this.issueArgs))..add(DiagnosticsProperty('error', _this.error))..add(DiagnosticsProperty('fps', _this.fps))..add(DiagnosticsProperty('frameMs', _this.frameMs));
}

@override
bool operator ==(Object other) {
  final _this = this as HtmlEffectStatus;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HtmlEffectStatus&&(identical(other.effectId, _this.effectId) || other.effectId == _this.effectId)&&(identical(other.loading, _this.loading) || other.loading == _this.loading)&&(identical(other.paused, _this.paused) || other.paused == _this.paused)&&(identical(other.issue, _this.issue) || other.issue == _this.issue)&&const DeepCollectionEquality().equals(other.issueArgs, _this.issueArgs)&&(identical(other.error, _this.error) || other.error == _this.error)&&(identical(other.fps, _this.fps) || other.fps == _this.fps)&&(identical(other.frameMs, _this.frameMs) || other.frameMs == _this.frameMs));
}


@override
int get hashCode {
  final _this = this as HtmlEffectStatus;
  return Object.hash(runtimeType,_this.effectId,_this.loading,_this.paused,_this.issue,const DeepCollectionEquality().hash(_this.issueArgs),_this.error,_this.fps,_this.frameMs);
}

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  final _this = this as HtmlEffectStatus;
  return 'HtmlEffectStatus(effectId: ${_this.effectId}, loading: ${_this.loading}, paused: ${_this.paused}, issue: ${_this.issue}, issueArgs: ${_this.issueArgs}, error: ${_this.error}, fps: ${_this.fps}, frameMs: ${_this.frameMs})';
}


}

/// @nodoc
abstract mixin class $HtmlEffectStatusCopyWith<$Res>  {
  factory $HtmlEffectStatusCopyWith(HtmlEffectStatus value, $Res Function(HtmlEffectStatus) _then) = _$HtmlEffectStatusCopyWithImpl;
@useResult
$Res call({
 String? effectId, bool loading, bool paused, HtmlEffectIssue? issue, List<String> issueArgs, String? error, double fps, double frameMs
});




}
/// @nodoc
class _$HtmlEffectStatusCopyWithImpl<$Res>
    implements $HtmlEffectStatusCopyWith<$Res> {
  _$HtmlEffectStatusCopyWithImpl(this._self, this._then);

  final HtmlEffectStatus _self;
  final $Res Function(HtmlEffectStatus) _then;

/// Create a copy of HtmlEffectStatus
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? effectId = freezed,Object? loading = null,Object? paused = null,Object? issue = freezed,Object? issueArgs = null,Object? error = freezed,Object? fps = null,Object? frameMs = null,}) {
  return _then(HtmlEffectStatus(
effectId: freezed == effectId ? _self.effectId : effectId // ignore: cast_nullable_to_non_nullable
as String?,loading: null == loading ? _self.loading : loading // ignore: cast_nullable_to_non_nullable
as bool,paused: null == paused ? _self.paused : paused // ignore: cast_nullable_to_non_nullable
as bool,issue: freezed == issue ? _self.issue : issue // ignore: cast_nullable_to_non_nullable
as HtmlEffectIssue?,issueArgs: null == issueArgs ? _self.issueArgs : issueArgs // ignore: cast_nullable_to_non_nullable
as List<String>,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,fps: null == fps ? _self.fps : fps // ignore: cast_nullable_to_non_nullable
as double,frameMs: null == frameMs ? _self.frameMs : frameMs // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [HtmlEffectStatus].
extension HtmlEffectStatusPatterns on HtmlEffectStatus {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HtmlEffectStatus value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HtmlEffectStatus() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HtmlEffectStatus value)  $default,){
final _that = this;
switch (_that) {
case _HtmlEffectStatus():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HtmlEffectStatus value)?  $default,){
final _that = this;
switch (_that) {
case _HtmlEffectStatus() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? effectId,  bool loading,  bool paused,  HtmlEffectIssue? issue,  List<String> issueArgs,  String? error,  double fps,  double frameMs)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HtmlEffectStatus() when $default != null:
return $default(_that.effectId,_that.loading,_that.paused,_that.issue,_that.issueArgs,_that.error,_that.fps,_that.frameMs);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? effectId,  bool loading,  bool paused,  HtmlEffectIssue? issue,  List<String> issueArgs,  String? error,  double fps,  double frameMs)  $default,) {final _that = this;
switch (_that) {
case _HtmlEffectStatus():
return $default(_that.effectId,_that.loading,_that.paused,_that.issue,_that.issueArgs,_that.error,_that.fps,_that.frameMs);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? effectId,  bool loading,  bool paused,  HtmlEffectIssue? issue,  List<String> issueArgs,  String? error,  double fps,  double frameMs)?  $default,) {final _that = this;
switch (_that) {
case _HtmlEffectStatus() when $default != null:
return $default(_that.effectId,_that.loading,_that.paused,_that.issue,_that.issueArgs,_that.error,_that.fps,_that.frameMs);case _:
  return null;

}
}

}

/// @nodoc


class _HtmlEffectStatus with DiagnosticableTreeMixin implements HtmlEffectStatus {
  const _HtmlEffectStatus({this.effectId, this.loading = false, this.paused = false, this.issue,  List<String> issueArgs = const <String>[], this.error, this.fps = 0, this.frameMs = 0}): _issueArgs = issueArgs;
  

/// Global effect id (`html:<id>`) currently rendered.
@override final  String? effectId;
@override@JsonKey() final  bool loading;
/// Stopped because frames take too long (an effect stuck in a loop).
@override@JsonKey() final  bool paused;
/// Reason the effect is not running; [error] carries technical detail.
@override final  HtmlEffectIssue? issue;
 final  List<String> _issueArgs;
@override@JsonKey() List<String> get issueArgs {
  if (_issueArgs is EqualUnmodifiableListView) return _issueArgs;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_issueArgs);
}

@override final  String? error;
/// Measured render FPS and mean frame time of the last second.
@override@JsonKey() final  double fps;
@override@JsonKey() final  double frameMs;

/// Create a copy of HtmlEffectStatus
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HtmlEffectStatusCopyWith<_HtmlEffectStatus> get copyWith => __$HtmlEffectStatusCopyWithImpl<_HtmlEffectStatus>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
    ..add(DiagnosticsProperty('type', 'HtmlEffectStatus'))
    ..add(DiagnosticsProperty('effectId', effectId))..add(DiagnosticsProperty('loading', loading))..add(DiagnosticsProperty('paused', paused))..add(DiagnosticsProperty('issue', issue))..add(DiagnosticsProperty('issueArgs', issueArgs))..add(DiagnosticsProperty('error', error))..add(DiagnosticsProperty('fps', fps))..add(DiagnosticsProperty('frameMs', frameMs));
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _HtmlEffectStatus&&(identical(other.effectId, effectId) || other.effectId == effectId)&&(identical(other.loading, loading) || other.loading == loading)&&(identical(other.paused, paused) || other.paused == paused)&&(identical(other.issue, issue) || other.issue == issue)&&const DeepCollectionEquality().equals(other.issueArgs, _issueArgs)&&(identical(other.error, error) || other.error == error)&&(identical(other.fps, fps) || other.fps == fps)&&(identical(other.frameMs, frameMs) || other.frameMs == frameMs));
}


@override
int get hashCode {
    return Object.hash(runtimeType,effectId,loading,paused,issue,const DeepCollectionEquality().hash(_issueArgs),error,fps,frameMs);
}

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
    return 'HtmlEffectStatus(effectId: $effectId, loading: $loading, paused: $paused, issue: $issue, issueArgs: $issueArgs, error: $error, fps: $fps, frameMs: $frameMs)';
}


}

/// @nodoc
abstract mixin class _$HtmlEffectStatusCopyWith<$Res> implements $HtmlEffectStatusCopyWith<$Res> {
  factory _$HtmlEffectStatusCopyWith(_HtmlEffectStatus value, $Res Function(_HtmlEffectStatus) _then) = __$HtmlEffectStatusCopyWithImpl;
@override @useResult
$Res call({
 String? effectId, bool loading, bool paused, HtmlEffectIssue? issue, List<String> issueArgs, String? error, double fps, double frameMs
});




}
/// @nodoc
class __$HtmlEffectStatusCopyWithImpl<$Res>
    implements _$HtmlEffectStatusCopyWith<$Res> {
  __$HtmlEffectStatusCopyWithImpl(this._self, this._then);

  final _HtmlEffectStatus _self;
  final $Res Function(_HtmlEffectStatus) _then;

/// Create a copy of HtmlEffectStatus
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? effectId = freezed,Object? loading = null,Object? paused = null,Object? issue = freezed,Object? issueArgs = null,Object? error = freezed,Object? fps = null,Object? frameMs = null,}) {
  return _then(_HtmlEffectStatus(
effectId: freezed == effectId ? _self.effectId : effectId // ignore: cast_nullable_to_non_nullable
as String?,loading: null == loading ? _self.loading : loading // ignore: cast_nullable_to_non_nullable
as bool,paused: null == paused ? _self.paused : paused // ignore: cast_nullable_to_non_nullable
as bool,issue: freezed == issue ? _self.issue : issue // ignore: cast_nullable_to_non_nullable
as HtmlEffectIssue?,issueArgs: null == issueArgs ? _self._issueArgs : issueArgs // ignore: cast_nullable_to_non_nullable
as List<String>,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,fps: null == fps ? _self.fps : fps // ignore: cast_nullable_to_non_nullable
as double,frameMs: null == frameMs ? _self.frameMs : frameMs // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

// dart format on
