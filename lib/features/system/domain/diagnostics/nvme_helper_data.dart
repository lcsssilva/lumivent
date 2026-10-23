import 'diagnostic_data.dart';

class NvmeHelperData extends DiagnosticData {
  const NvmeHelperData({this.path, required this.hasCaps});

  /// Installed SMART helper, or null when it was not found.
  final String? path;
  final bool hasCaps;
}
