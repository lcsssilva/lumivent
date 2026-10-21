// NVMe SSDs: sysfs identification (without privileges) and SMART 02h log through
// helper `lumivent-nvme-smart` (tool/lumivent-nvme-smart, installed by the package in
// /usr/lib/lumivent/ with setcap).
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import '../domain/ssd.dart';

const nvmeHelperName = 'lumivent-nvme-smart';
const nvmeHelperHint =
    'Instale o pacote lumivent (helper em /usr/lib/lumivent).';

/// Where the helper may be: `$LUMIVENT_NVME_SMART`, the package, or a manual install
/// (for development, see docs/instalacao.md).
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
({String ctrl, NvmeSmartLog? log, String? error})? parseHelperLine(
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
    return (ctrl: ctrl, log: null, error: error);
  }
  final bytes = json['log'] is String ? _fromHex(json['log']! as String) : null;
  final log = bytes == null ? null : parseNvmeSmartLog(bytes);
  return log == null
      ? (ctrl: ctrl, log: null, error: 'resposta inválida do helper')
      : (ctrl: ctrl, log: log, error: null);
}

class NvmeSsdReader implements SsdReader {
  NvmeSsdReader({
    this.sysfsRoot = '/sys',
    this._helper,
    this.timeout = const Duration(seconds: 5),
  });

  final String sysfsRoot;
  final Duration timeout;

  /// Helper path; `null` searches in [nvmeHelperCandidates].
  final String? _helper;

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
  Future<(Map<String, ({NvmeSmartLog? log, String? error})>, String?)>
  _runHelper(List<String> ctrls) async {
    final helper = _helper ?? findNvmeSmartHelper();
    if (helper == null) {
      return (
        const <String, Never>{},
        'O helper $nvmeHelperName não está instalado. $nvmeHelperHint',
      );
    }
    final ProcessResult r;
    try {
      r = await Process.run(helper, ctrls).timeout(timeout);
    } on Object catch (e) {
      return (const <String, Never>{}, 'falha ao executar o helper: $e');
    }
    final out = <String, ({NvmeSmartLog? log, String? error})>{};
    for (final line in const LineSplitter().convert(r.stdout as String)) {
      final p = parseHelperLine(line);
      if (p != null) out[p.ctrl] = (log: p.log, error: p.error);
    }
    return (
      out,
      out.length == ctrls.length
          ? null
          : 'o helper saiu com ${r.exitCode}: ${(r.stderr as String).trim()}',
    );
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
