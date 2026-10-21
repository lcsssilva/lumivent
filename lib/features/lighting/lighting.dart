/// Lighting module: global ARGB state, effects, and per-device lighting
/// (fans, motherboard, case, memory). Public API: other modules import only
/// this file.
library;

export 'application/effects_controller.dart'
    show
        InstalledEffectsController,
        effectImporterProvider,
        effectLibraryProvider,
        effectRuntimeFactoryProvider,
        installedEffectsProvider;
export 'application/lighting_controller.dart'
    show
        LightingController,
        LightingStatusController,
        fanGroupNamesProvider,
        lightingProvider,
        lightingRepositoryProvider,
        lightingStatusProvider;
export 'application/lighting_engine_commands.dart' show SetLightingFps;
export 'application/lighting_engine_module.dart' show LightingEngineModule;
export 'application/lighting_messages.dart'
    show
        ArgbStateChanged,
        IdentifyFanGroup,
        LightOutputIssue,
        LightOutputState,
        LightOutputStatus,
        LightingStatus,
        LoopStats,
        OutputFamily,
        SetArgbOff,
        SetLightingConfig;
export 'application/html_effect_runner.dart'
    show
        HtmlEffectIssue,
        HtmlEffectRunner,
        HtmlEffectStatus,
        htmlEffectRunnerProvider;
export 'domain/effect_compat.dart'
    show EffectCompatibility, EffectIssue, EffectSupport, analyzeEffect;
export 'domain/effect_library.dart'
    show ImportIssue, ImportIssueKind, ImportReport;
export 'domain/effect_meta.dart' show EffectProperty, EffectSource, parseEffect;
export 'domain/effect_runtime.dart' show EffectFrame;
export 'domain/installed_effect.dart'
    show EffectOrigin, InstalledEffect, htmlEffectId, htmlEffectSlugOf;
export 'domain/led_layout.dart';
export 'domain/light_device.dart';
export 'domain/lighting_config.dart';
export 'domain/native_effects.dart';
export 'domain/rgb.dart';
export 'lighting_module.dart';
export 'presentation/argb_toggle.dart' show ArgbToggle;
export 'presentation/lighting_page.dart' show LightingPage;
