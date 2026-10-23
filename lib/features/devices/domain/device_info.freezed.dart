// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'device_info.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$DeviceInfo {

/// Stable between runs (used by configuration in future phases).
 String get id; DeviceKind get kind; DeviceLabel get label;/// Memory slot for [DeviceLabel.memoryModule] (1-based).
 int? get slot; String get model; DeviceStatus get status;/// Firmware, node path, or a neutral technical error.
 String? get detail;/// Actionable issue and its data (for example the bus that did not
/// respond).
 DeviceIssue? get issue; String? get issueArg;
/// Create a copy of DeviceInfo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DeviceInfoCopyWith<DeviceInfo> get copyWith => _$DeviceInfoCopyWithImpl<DeviceInfo>(this as DeviceInfo, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as DeviceInfo;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DeviceInfo&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.kind, _this.kind) || other.kind == _this.kind)&&(identical(other.label, _this.label) || other.label == _this.label)&&(identical(other.slot, _this.slot) || other.slot == _this.slot)&&(identical(other.model, _this.model) || other.model == _this.model)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.detail, _this.detail) || other.detail == _this.detail)&&(identical(other.issue, _this.issue) || other.issue == _this.issue)&&(identical(other.issueArg, _this.issueArg) || other.issueArg == _this.issueArg));
}


@override
int get hashCode {
  final _this = this as DeviceInfo;
  return Object.hash(runtimeType,_this.id,_this.kind,_this.label,_this.slot,_this.model,_this.status,_this.detail,_this.issue,_this.issueArg);
}

@override
String toString() {
  final _this = this as DeviceInfo;
  return 'DeviceInfo(id: ${_this.id}, kind: ${_this.kind}, label: ${_this.label}, slot: ${_this.slot}, model: ${_this.model}, status: ${_this.status}, detail: ${_this.detail}, issue: ${_this.issue}, issueArg: ${_this.issueArg})';
}


}

/// @nodoc
abstract mixin class $DeviceInfoCopyWith<$Res>  {
  factory $DeviceInfoCopyWith(DeviceInfo value, $Res Function(DeviceInfo) _then) = _$DeviceInfoCopyWithImpl;
@useResult
$Res call({
 String id, DeviceKind kind, DeviceLabel label, int? slot, String model, DeviceStatus status, String? detail, DeviceIssue? issue, String? issueArg
});




}
/// @nodoc
class _$DeviceInfoCopyWithImpl<$Res>
    implements $DeviceInfoCopyWith<$Res> {
  _$DeviceInfoCopyWithImpl(this._self, this._then);

  final DeviceInfo _self;
  final $Res Function(DeviceInfo) _then;

/// Create a copy of DeviceInfo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? kind = null,Object? label = null,Object? slot = freezed,Object? model = null,Object? status = null,Object? detail = freezed,Object? issue = freezed,Object? issueArg = freezed,}) {
  return _then(DeviceInfo(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as DeviceKind,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as DeviceLabel,slot: freezed == slot ? _self.slot : slot // ignore: cast_nullable_to_non_nullable
as int?,model: null == model ? _self.model : model // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as DeviceStatus,detail: freezed == detail ? _self.detail : detail // ignore: cast_nullable_to_non_nullable
as String?,issue: freezed == issue ? _self.issue : issue // ignore: cast_nullable_to_non_nullable
as DeviceIssue?,issueArg: freezed == issueArg ? _self.issueArg : issueArg // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [DeviceInfo].
extension DeviceInfoPatterns on DeviceInfo {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DeviceInfo value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DeviceInfo() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DeviceInfo value)  $default,){
final _that = this;
switch (_that) {
case _DeviceInfo():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DeviceInfo value)?  $default,){
final _that = this;
switch (_that) {
case _DeviceInfo() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  DeviceKind kind,  DeviceLabel label,  int? slot,  String model,  DeviceStatus status,  String? detail,  DeviceIssue? issue,  String? issueArg)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DeviceInfo() when $default != null:
return $default(_that.id,_that.kind,_that.label,_that.slot,_that.model,_that.status,_that.detail,_that.issue,_that.issueArg);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  DeviceKind kind,  DeviceLabel label,  int? slot,  String model,  DeviceStatus status,  String? detail,  DeviceIssue? issue,  String? issueArg)  $default,) {final _that = this;
switch (_that) {
case _DeviceInfo():
return $default(_that.id,_that.kind,_that.label,_that.slot,_that.model,_that.status,_that.detail,_that.issue,_that.issueArg);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  DeviceKind kind,  DeviceLabel label,  int? slot,  String model,  DeviceStatus status,  String? detail,  DeviceIssue? issue,  String? issueArg)?  $default,) {final _that = this;
switch (_that) {
case _DeviceInfo() when $default != null:
return $default(_that.id,_that.kind,_that.label,_that.slot,_that.model,_that.status,_that.detail,_that.issue,_that.issueArg);case _:
  return null;

}
}

}

/// @nodoc


class _DeviceInfo implements DeviceInfo {
  const _DeviceInfo({required this.id, required this.kind, required this.label, this.slot, required this.model, required this.status, this.detail, this.issue, this.issueArg});
  

/// Stable between runs (used by configuration in future phases).
@override final  String id;
@override final  DeviceKind kind;
@override final  DeviceLabel label;
/// Memory slot for [DeviceLabel.memoryModule] (1-based).
@override final  int? slot;
@override final  String model;
@override final  DeviceStatus status;
/// Firmware, node path, or a neutral technical error.
@override final  String? detail;
/// Actionable issue and its data (for example the bus that did not
/// respond).
@override final  DeviceIssue? issue;
@override final  String? issueArg;

/// Create a copy of DeviceInfo
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DeviceInfoCopyWith<_DeviceInfo> get copyWith => __$DeviceInfoCopyWithImpl<_DeviceInfo>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _DeviceInfo&&(identical(other.id, id) || other.id == id)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.label, label) || other.label == label)&&(identical(other.slot, slot) || other.slot == slot)&&(identical(other.model, model) || other.model == model)&&(identical(other.status, status) || other.status == status)&&(identical(other.detail, detail) || other.detail == detail)&&(identical(other.issue, issue) || other.issue == issue)&&(identical(other.issueArg, issueArg) || other.issueArg == issueArg));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,kind,label,slot,model,status,detail,issue,issueArg);
}

@override
String toString() {
    return 'DeviceInfo(id: $id, kind: $kind, label: $label, slot: $slot, model: $model, status: $status, detail: $detail, issue: $issue, issueArg: $issueArg)';
}


}

/// @nodoc
abstract mixin class _$DeviceInfoCopyWith<$Res> implements $DeviceInfoCopyWith<$Res> {
  factory _$DeviceInfoCopyWith(_DeviceInfo value, $Res Function(_DeviceInfo) _then) = __$DeviceInfoCopyWithImpl;
@override @useResult
$Res call({
 String id, DeviceKind kind, DeviceLabel label, int? slot, String model, DeviceStatus status, String? detail, DeviceIssue? issue, String? issueArg
});




}
/// @nodoc
class __$DeviceInfoCopyWithImpl<$Res>
    implements _$DeviceInfoCopyWith<$Res> {
  __$DeviceInfoCopyWithImpl(this._self, this._then);

  final _DeviceInfo _self;
  final $Res Function(_DeviceInfo) _then;

/// Create a copy of DeviceInfo
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? kind = null,Object? label = null,Object? slot = freezed,Object? model = null,Object? status = null,Object? detail = freezed,Object? issue = freezed,Object? issueArg = freezed,}) {
  return _then(_DeviceInfo(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as DeviceKind,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as DeviceLabel,slot: freezed == slot ? _self.slot : slot // ignore: cast_nullable_to_non_nullable
as int?,model: null == model ? _self.model : model // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as DeviceStatus,detail: freezed == detail ? _self.detail : detail // ignore: cast_nullable_to_non_nullable
as String?,issue: freezed == issue ? _self.issue : issue // ignore: cast_nullable_to_non_nullable
as DeviceIssue?,issueArg: freezed == issueArg ? _self.issueArg : issueArg // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
