// NVMe SSDs: sysfs identification (without privileges) and SMART 02h log through
// helper `lumivent-nvme-smart` (tool/lumivent-nvme-smart, installed by the package in
// /usr/lib/lumivent/ with setcap).
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import '../domain/ssd.dart';

const nvmeHelperName = 'lumivent-nvme-smart';

/// Where the helper may be: `$LUMIVENT_NVME_SMART`, the package, or a manual install
/// (for development, see README.md).
List<String> nvmeHelperCandidates([Map<String, String>? env]) {
  env ??= Platform.environment;
  return [
    if (env['LUMIVENT_NVME_SMART'] case final p? when p.isNotEmpty) p,
    '/usr/lib/lumivent/$nvmeHelperName',
    '/usr/local/lib/lumivent/$nvmeHelperName',
  ];
}

String? findNvmeSmartHelper([Map<String, String>? env]) =>
    nvmeHelperCandidates(env).where((p) => File(p).existsSync()).firstOrNull;

/// Parses the 512-byte SMART/Health log (NVMe 1.4, Figure 207; little endian).
/// 128-bit counters use only the lower 63 bits.
NvmeSmartLog? parseNvmeSmartLog(Uint8List b) {
  if (b.length < 512) return null;
  final d = ByteData.sublistView(b);
  int u16(int o) => d.getUint16(o, Endian.little);
  int u32(int o) => d.getUint32(o, Endian.little);
  int u128(int o) {
    final hi = d.getUint64(o + 8, Endian.little);
    final lo = d.getUint64(o, Endian.little);
    // Dart int is a signed 64-bit value: saturate instead of going negative.
    return hi != 0 || lo < 0 ? 0x7FFFFFFFFFFFFFFF : lo;
  }

  return NvmeSmartLog(
    criticalWarning: b[0],
    compositeKelvin: u16(1),
    availableSpare: b[3],
    availableSpareThreshold: b[4],
    percentageUsed: b[5],
    dataUnitsRead: u128(32),
    dataUnitsWritten: u128(48),
    hostReadCommands: u128(64),
    hostWriteCommands: u128(80),
    controllerBusyMinutes: u128(96),
    powerCycles: u128(112),
    powerOnHours: u128(128),
    unsafeShutdowns: u128(144),
    mediaErrors: u128(160),
    errorLogEntries: u128(176),
    warningTempMinutes: u32(192),
    criticalTempMinutes: u32(196),
    sensorsKelvin: [for (var i = 0; i < 8; i++) u16(200 + 2 * i)],
  );
}

Uint8List? _fromHex(String hex) {
  if (hex.length.isOdd) return null;
  final out = Uint8List(hex.length ~/ 2);
  for (var i = 0; i < out.length; i++) {
    final v = int.tryParse(hex.substring(2 * i, 2 * i + 2), radix: 16);
    if (v == null) return null;
    out[i] = v;
  }
  return out;
}

/// One helper output line: `{"ctrl":…, "log":hex}` or `{"ctrl":…, "error":…}`.
({String ctrl, NvmeSmartLog? log, SsdSmartError? error})? parseHelperLine(
  String line,
) {
  final Object? json;
  try {
    json = jsonDecode(line);
  } on FormatException {
    return null;
  }
  if (json is! Map<String, Object?> || json['ctrl'] is! String) return null;
  final ctrl = json['ctrl']! as String;
  if (json['error'] case final String error) {
    return (
      ctrl: ctrl,
      log: null,
      error: SsdSmartError(SsdErrorKind.device, message: error),
    );
  }
  final bytes = json['log'] is String ? _fromHex(json['log']! as String) : null;
  final log = bytes == null ? null : parseNvmeSmartLog(bytes);
  return log == null
      ? (
          ctrl: ctrl,
          log: null,
          error: const SsdSmartError(SsdErrorKind.invalidResponse),
        )
      : (ctrl: ctrl, log: log, error: null);
}

/// Starts the helper process; replaced in tests.
typedef NvmeProcessStarter = Future<Process> Function(
  String executable,
  List<String> arguments,
);

class NvmeSsdReader implements SsdReader {
  NvmeSsdReader({
    this.sysfsRoot = '/sys',
    this._helper,
    this.timeout = const Duration(seconds: 5),
    this._startProcess = Process.start,
  });

  final String sysfsRoot;
  final Duration timeout;

  /// Helper path; `null` searches in [nvmeHelperCandidates].
  final String? _helper;
  final NvmeProcessStarter _startProcess;

  @override
  Future<List<SsdInfo>> read() async {
    final ctrls = _controllers();
    if (ctrls.isEmpty) return const [];
    final (smart, helperError) = await _runHelper(ctrls);
    return [
      for (final c in ctrls)
        SsdInfo(
          controller: c,
          model: _str('$sysfsRoot/class/nvme/$c/model') ?? c,
          serial: _str('$sysfsRoot/class/nvme/$c/serial') ?? '',
          firmware: _str('$sysfsRoot/class/nvme/$c/firmware_rev') ?? '',
          capacityBytes: _capacity(c),
          smart: smart[c]?.log,
          smartError: smart[c]?.error ?? helperError,
        ),
    ];
  }

  List<String> _controllers() {
    final dir = Directory('$sysfsRoot/class/nvme');
    if (!dir.existsSync()) return const [];
    final names = [
      for (final e in dir.listSync())
        if (RegExp(r'^nvme\d+$')
            .hasMatch(e.uri.pathSegments.where((s) => s.isNotEmpty).last))
          e.uri.pathSegments.where((s) => s.isNotEmpty).last,
    ];
    int n(String s) => int.parse(s.substring(4));
    return names..sort((a, b) => n(a).compareTo(n(b)));
  }

  /// Size of the first namespace (`nvmeXn1/size`, in 512-byte sectors).
  int? _capacity(String ctrl) {
    final sectors = int.tryParse(
      _str('$sysfsRoot/class/nvme/$ctrl/${ctrl}n1/size') ?? '',
    );
    return sectors == null ? null : sectors * 512;
  }

  /// SMART per controller and, if the whole helper failed, the reason.
  Future<
    (Map<String, ({NvmeSmartLog? log, SsdSmartError? error})>, SsdSmartError?)
  >
  _runHelper(List<String> ctrls) async {
    final helper = _helper ?? findNvmeSmartHelper();
    if (helper == null) {
      return (
        const <String, Never>{},
        const SsdSmartError(SsdErrorKind.helperMissing),
      );
    }
    final ProcessResult r;
    try {
      r = await _run(helper, ctrls);
    } on Object catch (e) {
      return (
        const <String, Never>{},
        SsdSmartError(SsdErrorKind.helperFailed, message: '$e'),
      );
    }
    final out = <String, ({NvmeSmartLog? log, SsdSmartError? error})>{};
    for (final line in const LineSplitter().convert(r.stdout as String)) {
      final p = parseHelperLine(line);
      if (p != null) out[p.ctrl] = (log: p.log, error: p.error);
    }
    return (
      out,
      out.length == ctrls.length
          ? null
          : SsdSmartError(
              SsdErrorKind.helperExit,
              exitCode: r.exitCode,
              stderr: (r.stderr as String).trim(),
            ),
    );
  }

  /// Runs the helper and collects its output. On timeout the process is killed
  /// (it holds CAP_SYS_ADMIN and would otherwise keep running, piling up with
  /// the next periodic reads) and a [TimeoutException] is thrown.
  Future<ProcessResult> _run(String helper, List<String> ctrls) async {
    final process = await _startProcess(helper, ctrls);
    final stdout = process.stdout.transform(utf8.decoder).join();
    final stderr = process.stderr.transform(utf8.decoder).join();
    try {
      final exitCode = await process.exitCode.timeout(timeout);
      return ProcessResult(process.pid, exitCode, await stdout, await stderr);
    } on TimeoutException {
      process.kill(ProcessSignal.sigkill);
      // Drain the pipes so the killed process leaves nothing pending.
      unawaited(stdout.then<void>((_) {}, onError: (Object _) {}));
      unawaited(stderr.then<void>((_) {}, onError: (Object _) {}));
      rethrow;
    }
  }

  static String? _str(String path) {
    try {
      final s = File(path).readAsStringSync().trim();
      return s.isEmpty ? null : s;
    } on FileSystemException {
      return null;
    }
  }
}
