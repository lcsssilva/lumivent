// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'installed_effect.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$InstalledEffect {

/// Folder name inside the effects directory.
 String get id; String get title; EffectSource get source; EffectCompatibility get compatibility; String? get publisher; String? get description; EffectOrigin get origin; DateTime? get importedAt;/// Extra catalog metadata (type, tags) when imported from a Windows cache.
 List<String> get tags; bool get hasThumbnail;
/// Create a copy of InstalledEffect
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InstalledEffectCopyWith<InstalledEffect> get copyWith => _$InstalledEffectCopyWithImpl<InstalledEffect>(this as InstalledEffect, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as InstalledEffect;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InstalledEffect&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.source, _this.source) || other.source == _this.source)&&(identical(other.compatibility, _this.compatibility) || other.compatibility == _this.compatibility)&&(identical(other.publisher, _this.publisher) || other.publisher == _this.publisher)&&(identical(other.description, _this.description) || other.description == _this.description)&&(identical(other.origin, _this.origin) || other.origin == _this.origin)&&(identical(other.importedAt, _this.importedAt) || other.importedAt == _this.importedAt)&&const DeepCollectionEquality().equals(other.tags, _this.tags)&&(identical(other.hasThumbnail, _this.hasThumbnail) || other.hasThumbnail == _this.hasThumbnail));
}


@override
int get hashCode {
  final _this = this as InstalledEffect;
  return Object.hash(runtimeType,_this.id,_this.title,_this.source,_this.compatibility,_this.publisher,_this.description,_this.origin,_this.importedAt,const DeepCollectionEquality().hash(_this.tags),_this.hasThumbnail);
}

@override
String toString() {
  final _this = this as InstalledEffect;
  return 'InstalledEffect(id: ${_this.id}, title: ${_this.title}, source: ${_this.source}, compatibility: ${_this.compatibility}, publisher: ${_this.publisher}, description: ${_this.description}, origin: ${_this.origin}, importedAt: ${_this.importedAt}, tags: ${_this.tags}, hasThumbnail: ${_this.hasThumbnail})';
}


}

/// @nodoc
abstract mixin class $InstalledEffectCopyWith<$Res>  {
  factory $InstalledEffectCopyWith(InstalledEffect value, $Res Function(InstalledEffect) _then) = _$InstalledEffectCopyWithImpl;
@useResult
$Res call({
 String id, String title, EffectSource source, EffectCompatibility compatibility, String? publisher, String? description, EffectOrigin origin, DateTime? importedAt, List<String> tags, bool hasThumbnail
});


$EffectCompatibilityCopyWith<$Res> get compatibility;

}
/// @nodoc
class _$InstalledEffectCopyWithImpl<$Res>
    implements $InstalledEffectCopyWith<$Res> {
  _$InstalledEffectCopyWithImpl(this._self, this._then);

  final InstalledEffect _self;
  final $Res Function(InstalledEffect) _then;

/// Create a copy of InstalledEffect
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? source = null,Object? compatibility = null,Object? publisher = freezed,Object? description = freezed,Object? origin = null,Object? importedAt = freezed,Object? tags = null,Object? hasThumbnail = null,}) {
  return _then(InstalledEffect(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as EffectSource,compatibility: null == compatibility ? _self.compatibility : compatibility // ignore: cast_nullable_to_non_nullable
as EffectCompatibility,publisher: freezed == publisher ? _self.publisher : publisher // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,origin: null == origin ? _self.origin : origin // ignore: cast_nullable_to_non_nullable
as EffectOrigin,importedAt: freezed == importedAt ? _self.importedAt : importedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,tags: null == tags ? _self.tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,hasThumbnail: null == hasThumbnail ? _self.hasThumbnail : hasThumbnail // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of InstalledEffect
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$EffectCompatibilityCopyWith<$Res> get compatibility {
  
  return $EffectCompatibilityCopyWith<$Res>(_self.compatibility, (value) {
    return _then(_self.copyWith(compatibility: value));
  });
}
}


/// Adds pattern-matching-related methods to [InstalledEffect].
extension InstalledEffectPatterns on InstalledEffect {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _InstalledEffect value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _InstalledEffect() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _InstalledEffect value)  $default,){
final _that = this;
switch (_that) {
case _InstalledEffect():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _InstalledEffect value)?  $default,){
final _that = this;
switch (_that) {
case _InstalledEffect() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  EffectSource source,  EffectCompatibility compatibility,  String? publisher,  String? description,  EffectOrigin origin,  DateTime? importedAt,  List<String> tags,  bool hasThumbnail)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _InstalledEffect() when $default != null:
return $default(_that.id,_that.title,_that.source,_that.compatibility,_that.publisher,_that.description,_that.origin,_that.importedAt,_that.tags,_that.hasThumbnail);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  EffectSource source,  EffectCompatibility compatibility,  String? publisher,  String? description,  EffectOrigin origin,  DateTime? importedAt,  List<String> tags,  bool hasThumbnail)  $default,) {final _that = this;
switch (_that) {
case _InstalledEffect():
return $default(_that.id,_that.title,_that.source,_that.compatibility,_that.publisher,_that.description,_that.origin,_that.importedAt,_that.tags,_that.hasThumbnail);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  EffectSource source,  EffectCompatibility compatibility,  String? publisher,  String? description,  EffectOrigin origin,  DateTime? importedAt,  List<String> tags,  bool hasThumbnail)?  $default,) {final _that = this;
switch (_that) {
case _InstalledEffect() when $default != null:
return $default(_that.id,_that.title,_that.source,_that.compatibility,_that.publisher,_that.description,_that.origin,_that.importedAt,_that.tags,_that.hasThumbnail);case _:
  return null;

}
}

}

/// @nodoc


class _InstalledEffect implements InstalledEffect {
  const _InstalledEffect({required this.id, required this.title, required this.source, required this.compatibility, this.publisher, this.description, this.origin = EffectOrigin.file, this.importedAt,  List<String> tags = const <String>[], this.hasThumbnail = false}): _tags = tags;
  

/// Folder name inside the effects directory.
@override final  String id;
@override final  String title;
@override final  EffectSource source;
@override final  EffectCompatibility compatibility;
@override final  String? publisher;
@override final  String? description;
@override@JsonKey() final  EffectOrigin origin;
@override final  DateTime? importedAt;
/// Extra catalog metadata (type, tags) when imported from a Windows cache.
 final  List<String> _tags;
/// Extra catalog metadata (type, tags) when imported from a Windows cache.
@override@JsonKey() List<String> get tags {
  if (_tags is EqualUnmodifiableListView) return _tags;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tags);
}

@override@JsonKey() final  bool hasThumbnail;

/// Create a copy of InstalledEffect
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InstalledEffectCopyWith<_InstalledEffect> get copyWith => __$InstalledEffectCopyWithImpl<_InstalledEffect>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _InstalledEffect&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.source, source) || other.source == source)&&(identical(other.compatibility, compatibility) || other.compatibility == compatibility)&&(identical(other.publisher, publisher) || other.publisher == publisher)&&(identical(other.description, description) || other.description == description)&&(identical(other.origin, origin) || other.origin == origin)&&(identical(other.importedAt, importedAt) || other.importedAt == importedAt)&&const DeepCollectionEquality().equals(other.tags, _tags)&&(identical(other.hasThumbnail, hasThumbnail) || other.hasThumbnail == hasThumbnail));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,title,source,compatibility,publisher,description,origin,importedAt,const DeepCollectionEquality().hash(_tags),hasThumbnail);
}

@override
String toString() {
    return 'InstalledEffect(id: $id, title: $title, source: $source, compatibility: $compatibility, publisher: $publisher, description: $description, origin: $origin, importedAt: $importedAt, tags: $tags, hasThumbnail: $hasThumbnail)';
}


}

/// @nodoc
abstract mixin class _$InstalledEffectCopyWith<$Res> implements $InstalledEffectCopyWith<$Res> {
  factory _$InstalledEffectCopyWith(_InstalledEffect value, $Res Function(_InstalledEffect) _then) = __$InstalledEffectCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, EffectSource source, EffectCompatibility compatibility, String? publisher, String? description, EffectOrigin origin, DateTime? importedAt, List<String> tags, bool hasThumbnail
});


@override $EffectCompatibilityCopyWith<$Res> get compatibility;

}
/// @nodoc
class __$InstalledEffectCopyWithImpl<$Res>
    implements _$InstalledEffectCopyWith<$Res> {
  __$InstalledEffectCopyWithImpl(this._self, this._then);

  final _InstalledEffect _self;
  final $Res Function(_InstalledEffect) _then;

/// Create a copy of InstalledEffect
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? source = null,Object? compatibility = null,Object? publisher = freezed,Object? description = freezed,Object? origin = null,Object? importedAt = freezed,Object? tags = null,Object? hasThumbnail = null,}) {
  return _then(_InstalledEffect(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as EffectSource,compatibility: null == compatibility ? _self.compatibility : compatibility // ignore: cast_nullable_to_non_nullable
as EffectCompatibility,publisher: freezed == publisher ? _self.publisher : publisher // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,origin: null == origin ? _self.origin : origin // ignore: cast_nullable_to_non_nullable
as EffectOrigin,importedAt: freezed == importedAt ? _self.importedAt : importedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,tags: null == tags ? _self._tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,hasThumbnail: null == hasThumbnail ? _self.hasThumbnail : hasThumbnail // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of InstalledEffect
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$EffectCompatibilityCopyWith<$Res> get compatibility {
  
  return $EffectCompatibilityCopyWith<$Res>(_self.compatibility, (value) {
    return _then(_self.copyWith(compatibility: value));
  });
}
}

// dart format on
