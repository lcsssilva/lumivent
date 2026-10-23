import 'dart:typed_data';

import 'package:lumivent/features/lighting/domain/effects/effect_library.dart';
import 'package:lumivent/features/lighting/domain/effects/installed_effect.dart';

class FakeEffectLibrary implements EffectLibrary {
  FakeEffectLibrary(this.effects);

  final List<InstalledEffect> effects;
  final removed = <String>[];
  var thumbnailReads = 0;

  @override
  Future<List<InstalledEffect>> list() async => List.of(effects);

  @override
  Future<InstalledEffect?> find(String id) async =>
      effects.where((e) => e.id == id).firstOrNull;

  @override
  Future<String> readHtml(String id) async => '<html></html>';

  @override
  Future<void> remove(String id) async {
    removed.add(id);
    effects.removeWhere((e) => e.id == id);
  }

  @override
  Future<void> saveThumbnail(String id, Uint8List png) async {}

  @override
  Future<Uint8List?> thumbnail(String id) async {
    thumbnailReads++;
    return null;
  }
}
