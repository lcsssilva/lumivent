import 'effect_runtime.dart';

/// Creates a runtime from the effect HTML (an isolate-safe port: the
/// implementation lives in lighting/infrastructure/html_effects).
abstract interface class EffectRuntimeFactory {
  Future<EffectRuntime> load(
    String html, {
    Map<String, Object?> values = const {},
  });
}
