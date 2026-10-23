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
 String? get effectId; bool get loading;/// Reason the effect is not running; [error] carries technical detail.
 HtmlEffectIssue? get issue;/// Duration of the frame that paused the effect, for
/// [HtmlEffectIssue.paused].
 int get slowFrameMs;/// Host features the effect needs, for [HtmlEffectIssue.unsupported].
 List<EffectIssue> get missingFeatures; String? get error;/// Measured render FPS and mean frame time of the last second.
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
    ..add(DiagnosticsProperty('effectId', _this.effectId))..add(DiagnosticsProperty('loading', _this.loading))..add(DiagnosticsProperty('issue', _this.issue))..add(DiagnosticsProperty('slowFrameMs', _this.slowFrameMs))..add(DiagnosticsProperty('missingFeatures', _this.missingFeatures))..add(DiagnosticsProperty('error', _this.error))..add(DiagnosticsProperty('fps', _this.fps))..add(DiagnosticsProperty('frameMs', _this.frameMs));
}

@override
bool operator ==(Object other) {
  final _this = this as HtmlEffectStatus;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HtmlEffectStatus&&(identical(other.effectId, _this.effectId) || other.effectId == _this.effectId)&&(identical(other.loading, _this.loading) || other.loading == _this.loading)&&(identical(other.issue, _this.issue) || other.issue == _this.issue)&&(identical(other.slowFrameMs, _this.slowFrameMs) || other.slowFrameMs == _this.slowFrameMs)&&const DeepCollectionEquality().equals(other.missingFeatures, _this.missingFeatures)&&(identical(other.error, _this.error) || other.error == _this.error)&&(identical(other.fps, _this.fps) || other.fps == _this.fps)&&(identical(other.frameMs, _this.frameMs) || other.frameMs == _this.frameMs));
}


@override
int get hashCode {
  final _this = this as HtmlEffectStatus;
  return Object.hash(runtimeType,_this.effectId,_this.loading,_this.issue,_this.slowFrameMs,const DeepCollectionEquality().hash(_this.missingFeatures),_this.error,_this.fps,_this.frameMs);
}

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  final _this = this as HtmlEffectStatus;
  return 'HtmlEffectStatus(effectId: ${_this.effectId}, loading: ${_this.loading}, issue: ${_this.issue}, slowFrameMs: ${_this.slowFrameMs}, missingFeatures: ${_this.missingFeatures}, error: ${_this.error}, fps: ${_this.fps}, frameMs: ${_this.frameMs})';
}


}

/// @nodoc
abstract mixin class $HtmlEffectStatusCopyWith<$Res>  {
  factory $HtmlEffectStatusCopyWith(HtmlEffectStatus value, $Res Function(HtmlEffectStatus) _then) = _$HtmlEffectStatusCopyWithImpl;
@useResult
$Res call({
 String? effectId, bool loading, HtmlEffectIssue? issue, int slowFrameMs, List<EffectIssue> missingFeatures, String? error, double fps, double frameMs
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
@pragma('vm:prefer-inline') @override $Res call({Object? effectId = freezed,Object? loading = null,Object? issue = freezed,Object? slowFrameMs = null,Object? missingFeatures = null,Object? error = freezed,Object? fps = null,Object? frameMs = null,}) {
  return _then(HtmlEffectStatus(
effectId: freezed == effectId ? _self.effectId : effectId // ignore: cast_nullable_to_non_nullable
as String?,loading: null == loading ? _self.loading : loading // ignore: cast_nullable_to_non_nullable
as bool,issue: freezed == issue ? _self.issue : issue // ignore: cast_nullable_to_non_nullable
as HtmlEffectIssue?,slowFrameMs: null == slowFrameMs ? _self.slowFrameMs : slowFrameMs // ignore: cast_nullable_to_non_nullable
as int,missingFeatures: null == missingFeatures ? _self.missingFeatures : missingFeatures // ignore: cast_nullable_to_non_nullable
as List<EffectIssue>,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? effectId,  bool loading,  HtmlEffectIssue? issue,  int slowFrameMs,  List<EffectIssue> missingFeatures,  String? error,  double fps,  double frameMs)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HtmlEffectStatus() when $default != null:
return $default(_that.effectId,_that.loading,_that.issue,_that.slowFrameMs,_that.missingFeatures,_that.error,_that.fps,_that.frameMs);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? effectId,  bool loading,  HtmlEffectIssue? issue,  int slowFrameMs,  List<EffectIssue> missingFeatures,  String? error,  double fps,  double frameMs)  $default,) {final _that = this;
switch (_that) {
case _HtmlEffectStatus():
return $default(_that.effectId,_that.loading,_that.issue,_that.slowFrameMs,_that.missingFeatures,_that.error,_that.fps,_that.frameMs);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? effectId,  bool loading,  HtmlEffectIssue? issue,  int slowFrameMs,  List<EffectIssue> missingFeatures,  String? error,  double fps,  double frameMs)?  $default,) {final _that = this;
switch (_that) {
case _HtmlEffectStatus() when $default != null:
return $default(_that.effectId,_that.loading,_that.issue,_that.slowFrameMs,_that.missingFeatures,_that.error,_that.fps,_that.frameMs);case _:
  return null;

}
}

}

/// @nodoc


class _HtmlEffectStatus with DiagnosticableTreeMixin implements HtmlEffectStatus {
  const _HtmlEffectStatus({this.effectId, this.loading = false, this.issue, this.slowFrameMs = 0,  List<EffectIssue> missingFeatures = const <EffectIssue>[], this.error, this.fps = 0, this.frameMs = 0}): _missingFeatures = missingFeatures;
  

/// Global effect id (`html:<id>`) currently rendered.
@override final  String? effectId;
@override@JsonKey() final  bool loading;
/// Reason the effect is not running; [error] carries technical detail.
@override final  HtmlEffectIssue? issue;
/// Duration of the frame that paused the effect, for
/// [HtmlEffectIssue.paused].
@override@JsonKey() final  int slowFrameMs;
/// Host features the effect needs, for [HtmlEffectIssue.unsupported].
 final  List<EffectIssue> _missingFeatures;
/// Host features the effect needs, for [HtmlEffectIssue.unsupported].
@override@JsonKey() List<EffectIssue> get missingFeatures {
  if (_missingFeatures is EqualUnmodifiableListView) return _missingFeatures;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_missingFeatures);
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
    ..add(DiagnosticsProperty('effectId', effectId))..add(DiagnosticsProperty('loading', loading))..add(DiagnosticsProperty('issue', issue))..add(DiagnosticsProperty('slowFrameMs', slowFrameMs))..add(DiagnosticsProperty('missingFeatures', missingFeatures))..add(DiagnosticsProperty('error', error))..add(DiagnosticsProperty('fps', fps))..add(DiagnosticsProperty('frameMs', frameMs));
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _HtmlEffectStatus&&(identical(other.effectId, effectId) || other.effectId == effectId)&&(identical(other.loading, loading) || other.loading == loading)&&(identical(other.issue, issue) || other.issue == issue)&&(identical(other.slowFrameMs, slowFrameMs) || other.slowFrameMs == slowFrameMs)&&const DeepCollectionEquality().equals(other.missingFeatures, _missingFeatures)&&(identical(other.error, error) || other.error == error)&&(identical(other.fps, fps) || other.fps == fps)&&(identical(other.frameMs, frameMs) || other.frameMs == frameMs));
}


@override
int get hashCode {
    return Object.hash(runtimeType,effectId,loading,issue,slowFrameMs,const DeepCollectionEquality().hash(_missingFeatures),error,fps,frameMs);
}

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
    return 'HtmlEffectStatus(effectId: $effectId, loading: $loading, issue: $issue, slowFrameMs: $slowFrameMs, missingFeatures: $missingFeatures, error: $error, fps: $fps, frameMs: $frameMs)';
}


}

/// @nodoc
abstract mixin class _$HtmlEffectStatusCopyWith<$Res> implements $HtmlEffectStatusCopyWith<$Res> {
  factory _$HtmlEffectStatusCopyWith(_HtmlEffectStatus value, $Res Function(_HtmlEffectStatus) _then) = __$HtmlEffectStatusCopyWithImpl;
@override @useResult
$Res call({
 String? effectId, bool loading, HtmlEffectIssue? issue, int slowFrameMs, List<EffectIssue> missingFeatures, String? error, double fps, double frameMs
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
@override @pragma('vm:prefer-inline') $Res call({Object? effectId = freezed,Object? loading = null,Object? issue = freezed,Object? slowFrameMs = null,Object? missingFeatures = null,Object? error = freezed,Object? fps = null,Object? frameMs = null,}) {
  return _then(_HtmlEffectStatus(
effectId: freezed == effectId ? _self.effectId : effectId // ignore: cast_nullable_to_non_nullable
as String?,loading: null == loading ? _self.loading : loading // ignore: cast_nullable_to_non_nullable
as bool,issue: freezed == issue ? _self.issue : issue // ignore: cast_nullable_to_non_nullable
as HtmlEffectIssue?,slowFrameMs: null == slowFrameMs ? _self.slowFrameMs : slowFrameMs // ignore: cast_nullable_to_non_nullable
as int,missingFeatures: null == missingFeatures ? _self._missingFeatures : missingFeatures // ignore: cast_nullable_to_non_nullable
as List<EffectIssue>,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,fps: null == fps ? _self.fps : fps // ignore: cast_nullable_to_non_nullable
as double,frameMs: null == frameMs ? _self.frameMs : frameMs // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

// dart format on
