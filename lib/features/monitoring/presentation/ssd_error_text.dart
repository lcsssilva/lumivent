import '../../../core/i18n/app_strings.dart';
import '../domain/ssd.dart';
import '../domain/ssd_smart_error.dart';

String ssdErrorText(SsdSmartError error, AppStrings strings) {
  final s = strings.monitoring;
  return switch (error.kind) {
    SsdErrorKind.helperMissing => s.ssdHelperMissing,
    SsdErrorKind.helperFailed => s.ssdHelperFailed(error.message ?? ''),
    SsdErrorKind.helperExit => s.ssdHelperExit(
      error.exitCode ?? 0,
      error.stderr ?? '',
    ),
    SsdErrorKind.invalidResponse => s.ssdInvalidResponse,
    SsdErrorKind.device => error.message ?? '',
  };
}
