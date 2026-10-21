/// Fans module: AL V2 fan speed through curves and presets (phase 3).
/// Public API: other modules import only this file.
library;

export 'application/fans_controller.dart'
    show
        FansController,
        FansStatusController,
        fansProvider,
        fansRepositoryProvider,
        fansStatusProvider;
export 'application/fans_engine_module.dart' show FansEngineModule;
export 'application/fans_messages.dart'
    show FanGroupStatus, FansStatus, SetFansConfig;
export 'domain/fan_curve.dart';
export 'domain/fan_group.dart';
export 'domain/fan_response.dart';
export 'fans_module.dart' show FansModule;
export 'presentation/fans_page.dart' show FansPage;
