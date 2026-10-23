/// Lighting module: global ARGB state, effects, and per-device lighting
/// (fans, motherboard, case, memory). Public API: other modules import only
/// this file.
library;

export 'application/effects/installed_effects_notifier.dart'
    show
        InstalledEffectsNotifier,
        effectImporterProvider,
        effectLibraryProvider,
        effectRuntimeFactoryProvider,
        installedEffectsProvider;
export 'application/lighting_notifier.dart'
    show
        LightingNotifier,
        fanGroupNamesProvider,
        lightingProvider,
        lightingRepositoryProvider;
export 'application/status/lighting_status_notifier.dart'
    show LightingStatusNotifier, lightingStatusProvider;
export 'application/messages/set_lighting_fps.dart' show SetLightingFps;
export 'application/lighting_engine_module.dart' show LightingEngineModule;
export 'application/messages/argb_state_changed.dart' show ArgbStateChanged;
export 'application/messages/identify_fan_group.dart' show IdentifyFanGroup;
export 'application/status/light_output_state.dart'
    show LightOutputIssue, LightOutputState, OutputFamily;
export 'application/status/light_output_status.dart' show LightOutputStatus;
export 'application/messages/lighting_status.dart' show LightingStatus;
export 'application/status/loop_stats.dart' show LoopStats;
export 'application/messages/set_argb_off.dart' show SetArgbOff;
export 'application/messages/set_lighting_config.dart' show SetLightingConfig;
export 'application/effects/html_effect_runner.dart'
    show HtmlEffectIssue, HtmlEffectRunner, htmlEffectRunnerProvider;
export 'application/effects/html_effect_status.dart' show HtmlEffectStatus;
export 'domain/effects/effect_compatibility.dart'
    show EffectCompatibility, EffectIssue, EffectSupport, analyzeEffect;
export 'domain/effect_import/import_issue.dart' show ImportIssue;
export 'domain/effects/effect_library.dart' show ImportIssueKind;
export 'domain/effect_import/import_report.dart' show ImportReport;
export 'domain/effects/effect_property.dart' show EffectProperty;
export 'domain/effects/effect_source.dart' show EffectSource;
export 'domain/effects/effect_meta.dart' show parseEffect;
export 'domain/canvas/effect_frame.dart' show EffectFrame;
export 'domain/effects/installed_effect.dart'
    show
        EffectOrigin,
        InstalledEffect,
        InstalledEffectX,
        htmlEffectId,
        htmlEffectSlugOf;
export 'domain/canvas/led_layout.dart';
export 'domain/canvas/led_point.dart';
export 'domain/canvas/canvas_rect.dart';
export 'domain/light_device.dart';
export 'domain/hardware_mode/alv2_hardware_config.dart';
export 'domain/config/lighting_config.dart';
export 'domain/hardware_mode/gpu_hardware_config.dart';
export 'domain/config/board_zone_config.dart';
export 'domain/config/device_light_config.dart';
export 'domain/config/lighting_config_repository.dart';
export 'domain/native_effects/native_effects.dart';
export 'domain/effects/effect_param.dart';
export 'domain/effects/effect_values.dart';
export 'domain/native_effects/native_effect.dart';
export 'domain/rgb.dart';
export 'lighting_module.dart';
export 'presentation/widgets/argb_toggle.dart' show ArgbToggle;
export 'presentation/lighting_labels.dart'
    show effectIssueLabel, outputIssueLabel;
export 'presentation/views/lighting_view.dart' show LightingView;
