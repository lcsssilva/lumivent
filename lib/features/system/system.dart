/// System module: operating system integration (autostart through systemd --user
/// and driver/permission diagnostics).
/// Public API: other modules import only this file.
library;

export 'application/system_controller.dart'
    show
        autostartProvider,
        autostartServiceProvider,
        diagnosticsProvider,
        environmentDiagnosticsProvider;
export 'domain/autostart.dart';
export 'domain/diagnostics.dart';
export 'presentation/diagnostics_card.dart' show DiagnosticsCard;
export 'presentation/startup_card.dart' show StartupCard;
export 'system_module.dart';
