/// System module: operating system integration (autostart through systemd --user
/// and driver/permission diagnostics).
/// Public API: other modules import only this file.
library;

export 'application/autostart_notifier.dart'
    show autostartProvider, autostartServiceProvider;
export 'application/diagnostics_providers.dart'
    show diagnosticsProvider, environmentDiagnosticsProvider;
export 'domain/autostart_error.dart';
export 'domain/autostart_state.dart';
export 'domain/autostart_exception.dart';
export 'domain/autostart_service.dart';
export 'domain/diagnostics.dart';
export 'domain/diagnostic_data.dart';
export 'domain/no_diagnostic_data.dart';
export 'domain/udev_rules_data.dart';
export 'domain/board_sensors_data.dart';
export 'domain/memory_smbus_data.dart';
export 'domain/memory_temperature_data.dart';
export 'domain/nvme_helper_data.dart';
export 'domain/loop_sample.dart';
export 'domain/lighting_loop_data.dart';
export 'domain/diagnostic_check.dart';
export 'domain/environment_diagnostics.dart';
export 'presentation/widgets/diagnostics_card.dart' show DiagnosticsCard;
export 'presentation/widgets/startup_card.dart' show StartupCard;
export 'system_module.dart';
