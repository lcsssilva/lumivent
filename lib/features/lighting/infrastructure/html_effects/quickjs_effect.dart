// The JS half of an effect: owns QuickJS and the shim, no dart:ui.
//
// Every evaluation runs under a QuickJS interrupt deadline (see
// `quickjs_interrupt.dart`), so a script that never returns fails here, below
// the hard limits the parent enforces by killing the worker.

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_js/flutter_js.dart';

import '../../../../core/platform/numeric_locale.dart';
import '../../domain/effects/effect_meta.dart';
import '../../domain/effects/effect_source.dart';
import 'quickjs_interrupt.dart';
import 'effect_script_exception.dart';

/// QuickJS interrupts one evaluation after this long. Below the hard limits
/// below, so the worker answers with the script error before the parent kills
/// it.
const scriptInterruptLimit = Duration(milliseconds: 500);
const scriptLoadInterruptLimit = Duration(seconds: 6);

/// Longest a frame may run in the worker before the parent stops the worker.
/// The runner pauses after three frames above 250 ms; this is the hard stop
/// for a script that never returns (and for native code that ignores the
/// interrupt deadline).
const scriptHardLimit = Duration(milliseconds: 750);
const scriptLoadLimit = Duration(seconds: 8);

/// The shim is an asset; read it once on the main isolate and hand it to the
/// worker (background isolates cannot use the Flutter asset bundle).
Future<String>? _shimScript;
Future<String> loadShim() =>
    _shimScript ??= rootBundle.loadString('assets/effects/canvas2d_shim.js');

/// Decodes the base64 frame payload produced by `canvas2d_shim.js`.
Uint8List decodeCanvas(String s) => base64Decode(s);

/// A loaded HTML effect on QuickJS.
class QuickJsEffect {
  QuickJsEffect(this.effect, this._js);

  final EffectSource effect;
  final JavascriptRuntime _js;
  Duration lastScriptTime = Duration.zero;

  static QuickJsEffect load(
    String html,
    String shim,
    Map<String, Object?> values,
  ) {
    // Must run before the first QuickJS parse (see numeric_locale.dart).
    useCNumericLocale();
    final effect = parseEffect(html);
    final js = newInterruptibleQuickJs();
    final rt = QuickJsEffect(effect, js);
    try {
      rt._eval(shim, 'canvas2d_shim.js', limit: scriptLoadInterruptLimit);
      // Properties become globals before the effect script runs (§6.2).
      final globals = {
        for (final p in effect.properties) p.name: p.resolve(values[p.name]),
      };
      rt._eval(
        'Object.assign(globalThis, ${jsonEncode(globals)});',
        'props',
        limit: scriptLoadInterruptLimit,
      );
      rt._eval(effect.script, effect.title, limit: scriptLoadInterruptLimit);
      for (final hook in ['onEngineReady', 'onReady']) {
        rt._eval(
          'typeof $hook === "function" && $hook();',
          hook,
          limit: scriptLoadInterruptLimit,
        );
      }
    } on Object {
      js.dispose();
      rethrow;
    }
    return rt;
  }

  /// Advances the effect to [nowMs] and returns the canvas command buffer.
  Uint8List renderOps(double nowMs) {
    final sw = Stopwatch()..start();
    final encoded = _eval('__we_frame($nowMs)', 'frame');
    lastScriptTime = sw.elapsed;
    return decodeCanvas(encoded);
  }

  void setProperty(String name, Object? value) => _eval(
    '__we_setProperty(${jsonEncode(name)}, ${jsonEncode(value)});',
    'setProperty',
  );

  void setSensors(Map<String, double> values) {
    final clean = <String, double>{
      for (final e in values.entries)
        if (e.value.isFinite) e.key: e.value,
    };
    _eval('__we_setSensors(${jsonEncode(clean)});', 'sensors');
  }

  List<String> drainLog() {
    final r = _eval('JSON.stringify(__we_log.splice(0))', 'log');
    return (jsonDecode(r) as List).cast<String>();
  }

  String _eval(
    String code,
    String name, {
    Duration limit = scriptInterruptLimit,
  }) {
    final r = withScriptDeadline(
      limit,
      () => _js.evaluate(code, sourceUrl: name),
    );
    if (r.isError) throw EffectScriptException('$name: ${r.stringResult}');
    return r.stringResult;
  }

  void dispose() => _js.dispose();
}
