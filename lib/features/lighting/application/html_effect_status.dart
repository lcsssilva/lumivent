import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../domain/effect_compatibility.dart' show EffectIssue;
import 'html_effect_runner.dart';

part 'html_effect_status.freezed.dart';

@freezed
abstract class HtmlEffectStatus with _$HtmlEffectStatus {
  const factory HtmlEffectStatus({
    /// Global effect id (`html:<id>`) currently rendered.
    String? effectId,
    @Default(false) bool loading,

    /// Reason the effect is not running; [error] carries technical detail.
    HtmlEffectIssue? issue,

    /// Duration of the frame that paused the effect, for
    /// [HtmlEffectIssue.paused].
    @Default(0) int slowFrameMs,

    /// Host features the effect needs, for [HtmlEffectIssue.unsupported].
    @Default(<EffectIssue>[]) List<EffectIssue> missingFeatures,
    String? error,

    /// Measured render FPS and mean frame time of the last second.
    @Default(0) double fps,
    @Default(0) double frameMs,
  }) = _HtmlEffectStatus;
}
