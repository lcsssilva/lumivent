/// System module: operating system integration (autostart through systemd --user
/// and driver/permission diagnostics).
/// Public API: other modules import only this file.
library;

export 'application/autostart_notifier.dart'
    show autostartProvider, autostartServiceProvider;
export 'application/diagnostics_providers.dart'
    show diagnosticsProvider, environmentDiagnosticsProvider;
export 'application/runtime_checks.dart' show runtimeChecksProvider;
export 'domain/autostart/autostart_error.dart';
export 'domain/autostart/autostart_state.dart';
export 'domain/autostart/autostart_exception.dart';
export 'domain/autostart/autostart_service.dart';
export 'domain/diagnostics/diagnostics.dart';
export 'domain/diagnostics/diagnostic_data.dart';
export 'domain/diagnostics/no_diagnostic_data.dart';
export 'domain/diagnostics/udev_rules_data.dart';
export 'domain/diagnostics/board_sensors_data.dart';
export 'domain/diagnostics/memory_smbus_data.dart';
export 'domain/diagnostics/memory_temperature_data.dart';
export 'domain/diagnostics/nvme_helper_data.dart';
export 'domain/diagnostics/loop_sample.dart';
export 'domain/diagnostics/lighting_loop_data.dart';
export 'domain/diagnostics/diagnostic_check.dart';
export 'domain/diagnostics/environment_diagnostics.dart';
export 'presentation/widgets/diagnostics_card.dart' show DiagnosticsCard;
export 'presentation/widgets/startup_card.dart' show StartupCard;
export 'system_module.dart';
