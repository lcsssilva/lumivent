/// Failure while opening the adapter; [permissionDenied] maps to the udev hint.
class GpuException implements Exception {
  const GpuException(this.message, {this.permissionDenied = false});
  final String message;
  final bool permissionDenied;
  @override
  String toString() => message;
}
