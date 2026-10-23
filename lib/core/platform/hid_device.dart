part of 'hid_api.dart';

class HidDevice {
  HidDevice._(this._api, this._dev, this.path);

  final HidApi _api;
  final Pointer<HidDeviceHandle> _dev;
  final String path;
  bool _closed = false;

  String get _lastError => _wstr(_api._error(_dev)) ?? 'unknown error';

  /// Sends a feature report. [data] starts with the report ID and is padded
  /// with zeroes up to [length].
  void sendFeature(List<int> data, int length) {
    _io(_api._sendFeature, data, length, 'hid_send_feature_report');
  }

  /// Reads a feature report with the given [reportId]. Returns the bytes read,
  /// including the report ID.
  Uint8List getFeature(int reportId, int length) =>
      _ioRead(_api._getFeature, reportId, length, 'hid_get_feature_report');

  /// Reads an input report (GET_REPORT through EP0) with the given [reportId].
  Uint8List getInput(int reportId, int length) =>
      _ioRead(_api._getInput, reportId, length, 'hid_get_input_report');

  /// Sends an output report through the interrupt endpoint.
  void write(List<int> data, int length) {
    _io(_api._write, data, length, 'hid_write');
  }

  // Not unit-tested (REV-008): a HidDevice only exists after a real hidapi
  // open, and _checkLength is a private one-line guard. Testing it would mean
  // widening the API or opening hardware, so the guards are reviewed here.
  /// Reads an input report from the interrupt endpoint; empty on timeout.
  Uint8List read(int length, {int timeoutMs = 100}) {
    _checkOpen();
    _checkLength(length, 'hid_read_timeout');
    final buf = calloc<Uint8>(length);
    try {
      final n = _api._readTimeout(_dev, buf, length, timeoutMs);
      if (n < 0) throw HidException('hid_read_timeout: $_lastError');
      return Uint8List.fromList(buf.asTypedList(n));
    } finally {
      calloc.free(buf);
    }
  }

  void _io(_IoD fn, List<int> data, int length, String name) {
    _checkOpen();
    if (data.length > length) {
      throw ArgumentError('$name: ${data.length} bytes > $length-byte report');
    }
    final buf = calloc<Uint8>(length);
    try {
      buf.asTypedList(length).setAll(0, data);
      final n = fn(_dev, buf, length);
      if (n < 0) throw HidException('$name: $_lastError');
    } finally {
      calloc.free(buf);
    }
  }

  Uint8List _ioRead(_IoD fn, int reportId, int length, String name) {
    _checkOpen();
    _checkLength(length, name);
    final buf = calloc<Uint8>(length);
    try {
      buf[0] = reportId;
      final n = fn(_dev, buf, length);
      if (n < 0) throw HidException('$name: $_lastError');
      return Uint8List.fromList(buf.asTypedList(n));
    } finally {
      calloc.free(buf);
    }
  }

  void _checkOpen() {
    if (_closed) throw StateError('HidDevice is already closed: $path');
  }

  // A read needs at least the report ID byte.
  static void _checkLength(int length, String name) {
    if (length <= 0) throw ArgumentError('$name: length must be positive');
  }

  void close() {
    if (_closed) return;
    _closed = true;
    _api._close(_dev);
  }
}
