/// Lighting module: global ARGB state, effects, and per-device lighting
/// (fans, motherboard, case, memory). Public API: other modules import only
/// this file.
library;

export 'application/installed_effects_notifier.dart'
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
export 'application/lighting_status_notifier.dart'
    show LightingStatusNotifier, lightingStatusProvider;
export 'application/set_lighting_fps.dart' show SetLightingFps;
export 'application/lighting_engine_module.dart' show LightingEngineModule;
export 'application/argb_state_changed.dart' show ArgbStateChanged;
export 'application/identify_fan_group.dart' show IdentifyFanGroup;
export 'application/light_output_state.dart'
    show LightOutputIssue, LightOutputState, OutputFamily;
export 'application/light_output_status.dart' show LightOutputStatus;
export 'application/lighting_status.dart' show LightingStatus;
export 'application/loop_stats.dart' show LoopStats;
export 'application/set_argb_off.dart' show SetArgbOff;
export 'application/set_lighting_config.dart' show SetLightingConfig;
export 'application/html_effect_runner.dart'
    show HtmlEffectIssue, HtmlEffectRunner, htmlEffectRunnerProvider;
export 'application/html_effect_status.dart' show HtmlEffectStatus;
export 'domain/effect_compatibility.dart'
    show EffectCompatibility, EffectIssue, EffectSupport, analyzeEffect;
export 'domain/import_issue.dart' show ImportIssue;
export 'domain/effect_library.dart' show ImportIssueKind;
export 'domain/import_report.dart' show ImportReport;
export 'domain/effect_property.dart' show EffectProperty;
export 'domain/effect_source.dart' show EffectSource;
export 'domain/effect_meta.dart' show parseEffect;
export 'domain/effect_frame.dart' show EffectFrame;
export 'domain/installed_effect.dart'
    show
        EffectOrigin,
        InstalledEffect,
        InstalledEffectX,
        htmlEffectId,
        htmlEffectSlugOf;
export 'domain/led_layout.dart';
export 'domain/led_point.dart';
export 'domain/canvas_rect.dart';
export 'domain/light_device.dart';
export 'domain/alv2_hardware_config.dart';
export 'domain/lighting_config.dart';
export 'domain/gpu_hardware_config.dart';
export 'domain/board_zone_config.dart';
export 'domain/device_light_config.dart';
export 'domain/lighting_config_repository.dart';
export 'domain/native_effects.dart';
export 'domain/effect_param.dart';
export 'domain/effect_values.dart';
export 'domain/native_effect.dart';
export 'domain/rgb.dart';
export 'lighting_module.dart';
export 'presentation/widgets/argb_toggle.dart' show ArgbToggle;
export 'presentation/lighting_labels.dart'
    show effectIssueLabel, outputIssueLabel;
export 'presentation/views/lighting_view.dart' show LightingView;
