// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'effect_compatibility.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$EffectCompatibility {

 EffectSupport get support;/// Missing features, without user-facing text.
 List<EffectIssue> get issues;
/// Create a copy of EffectCompatibility
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EffectCompatibilityCopyWith<EffectCompatibility> get copyWith => _$EffectCompatibilityCopyWithImpl<EffectCompatibility>(this as EffectCompatibility, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as EffectCompatibility;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EffectCompatibility&&(identical(other.support, _this.support) || other.support == _this.support)&&const DeepCollectionEquality().equals(other.issues, _this.issues));
}


@override
int get hashCode {
  final _this = this as EffectCompatibility;
  return Object.hash(runtimeType,_this.support,const DeepCollectionEquality().hash(_this.issues));
}

@override
String toString() {
  final _this = this as EffectCompatibility;
  return 'EffectCompatibility(support: ${_this.support}, issues: ${_this.issues})';
}


}

/// @nodoc
abstract mixin class $EffectCompatibilityCopyWith<$Res>  {
  factory $EffectCompatibilityCopyWith(EffectCompatibility value, $Res Function(EffectCompatibility) _then) = _$EffectCompatibilityCopyWithImpl;
@useResult
$Res call({
 EffectSupport support, List<EffectIssue> issues
});




}
/// @nodoc
class _$EffectCompatibilityCopyWithImpl<$Res>
    implements $EffectCompatibilityCopyWith<$Res> {
  _$EffectCompatibilityCopyWithImpl(this._self, this._then);

  final EffectCompatibility _self;
  final $Res Function(EffectCompatibility) _then;

/// Create a copy of EffectCompatibility
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? support = null,Object? issues = null,}) {
  return _then(EffectCompatibility(
null == support ? _self.support : support // ignore: cast_nullable_to_non_nullable
as EffectSupport,null == issues ? _self.issues : issues // ignore: cast_nullable_to_non_nullable
as List<EffectIssue>,
  ));
}

}


/// Adds pattern-matching-related methods to [EffectCompatibility].
extension EffectCompatibilityPatterns on EffectCompatibility {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EffectCompatibility value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EffectCompatibility() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EffectCompatibility value)  $default,){
final _that = this;
switch (_that) {
case _EffectCompatibility():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EffectCompatibility value)?  $default,){
final _that = this;
switch (_that) {
case _EffectCompatibility() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( EffectSupport support,  List<EffectIssue> issues)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EffectCompatibility() when $default != null:
return $default(_that.support,_that.issues);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( EffectSupport support,  List<EffectIssue> issues)  $default,) {final _that = this;
switch (_that) {
case _EffectCompatibility():
return $default(_that.support,_that.issues);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( EffectSupport support,  List<EffectIssue> issues)?  $default,) {final _that = this;
switch (_that) {
case _EffectCompatibility() when $default != null:
return $default(_that.support,_that.issues);case _:
  return null;

}
}

}

/// @nodoc


class _EffectCompatibility implements EffectCompatibility {
  const _EffectCompatibility(this.support,  List<EffectIssue> issues): _issues = issues;
  

@override final  EffectSupport support;
/// Missing features, without user-facing text.
 final  List<EffectIssue> _issues;
/// Missing features, without user-facing text.
@override List<EffectIssue> get issues {
  if (_issues is EqualUnmodifiableListView) return _issues;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_issues);
}


/// Create a copy of EffectCompatibility
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EffectCompatibilityCopyWith<_EffectCompatibility> get copyWith => __$EffectCompatibilityCopyWithImpl<_EffectCompatibility>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _EffectCompatibility&&(identical(other.support, support) || other.support == support)&&const DeepCollectionEquality().equals(other.issues, _issues));
}


@override
int get hashCode {
    return Object.hash(runtimeType,support,const DeepCollectionEquality().hash(_issues));
}

@override
String toString() {
    return 'EffectCompatibility(support: $support, issues: $issues)';
}


}

/// @nodoc
abstract mixin class _$EffectCompatibilityCopyWith<$Res> implements $EffectCompatibilityCopyWith<$Res> {
  factory _$EffectCompatibilityCopyWith(_EffectCompatibility value, $Res Function(_EffectCompatibility) _then) = __$EffectCompatibilityCopyWithImpl;
@override @useResult
$Res call({
 EffectSupport support, List<EffectIssue> issues
});




}
/// @nodoc
class __$EffectCompatibilityCopyWithImpl<$Res>
    implements _$EffectCompatibilityCopyWith<$Res> {
  __$EffectCompatibilityCopyWithImpl(this._self, this._then);

  final _EffectCompatibility _self;
  final $Res Function(_EffectCompatibility) _then;

/// Create a copy of EffectCompatibility
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? support = null,Object? issues = null,}) {
  return _then(_EffectCompatibility(
null == support ? _self.support : support // ignore: cast_nullable_to_non_nullable
as EffectSupport,null == issues ? _self._issues : issues // ignore: cast_nullable_to_non_nullable
as List<EffectIssue>,
  ));
}


}

// dart format on
