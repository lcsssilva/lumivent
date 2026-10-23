// Runs an HTML/Canvas effect on QuickJS (flutter_js) and draws each frame into
// a 320×200 ui.Image by replaying the binary canvas commands emitted by
// canvas2d_shim.js.
//
// This factory picks one of the two runtimes used by the app
// (`isolated_html_effect_runtime.dart`, `html_effect_runtime.dart`); the
// pieces they share live in their own files:
//
// * `quickjs_effect.dart`: QuickJS evaluation and the script deadline limits.
// * `effect_rasterizer.dart`: frame rasterization (fast path and dart:ui
//   replay).
// * `effect_worker_protocol.dart`: named, validated worker message envelopes
//   and codecs.
// * `effect_worker.dart`: the worker side (child process and isolate).
// * `effect_worker_connection.dart`: the parent side of the worker transports.
// * `shared_effect_worker.dart`: one worker reused across effect loads.
//
// Linux app builds run QuickJS in a child process; tests and development
// runners use an isolate. Both paths enforce the evaluation deadlines, while
// the process boundary can also kill a native call stuck past its limit.

import '../../domain/effect_runtime.dart';
import '../../domain/effect_runtime_factory.dart';
import 'shared_effect_worker.dart';
import 'isolated_html_effect_runtime.dart';

/// Port implementation used by the UI (wired in `lighting_module.dart`).
class HtmlEffectRuntimeFactory implements EffectRuntimeFactory {
  HtmlEffectRuntimeFactory({SharedEffectWorker? worker})
    : _worker = worker ?? SharedEffectWorker();

  /// Every effect the app loads goes through the same worker.
  final SharedEffectWorker _worker;

  @override
  Future<EffectRuntime> load(
    String html, {
    Map<String, Object?> values = const {},
  }) => IsolatedHtmlEffectRuntime.load(html, values: values, worker: _worker);
}
