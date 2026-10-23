// ignore_for_file: avoid_print, avoid_function_literals_in_foreach_calls
// Spike da fase 0 (a): ler firmware/RPM do AL V2 e a tabela CC 60 do ITE
// through hidapi via FFI. READ-ONLY: the only packets sent are the three
// pedidos de leitura de [_allowed].
//
//   dart run tool/spike_hid.dart
import 'dart:io';
import 'dart:typed_data';

import 'package:lumivent/core/platform/hid_api.dart';

const _alv2Vid = 0x0CF2, _alv2Pid = 0xA104;
const _iteVid = 0x048D, _itePid = 0x5702;

/// Pedidos de leitura permitidos (AL-V2 §2, ITE §1.2).
const _allowed = <String>{'e05001', 'e05000', 'cc60'};

String hex(List<int> b) =>
    b.map((v) => v.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ');

void sendRead(HidDevice dev, List<int> req, int len) {
  final key = req.map((v) => v.toRadixString(16).padLeft(2, '0')).join();
  if (!_allowed.contains(key)) throw StateError('pacote fora da lista: $key');
  dev.sendFeature(req, len);
}

void alv2(HidApi api) {
  final all = api.enumerate(vendorId: _alv2Vid, productId: _alv2Pid);
  all.forEach((d) => print('  $d'));
  final info =
      all.where((d) => d.interfaceNumber == 1).firstOrNull ?? all.firstOrNull;
  if (info == null) return print('  AL V2 not found');
  final dev = api.openPath(info.path);
  try {
    sendRead(dev, [0xE0, 0x50, 0x01], 7);
    sleep(const Duration(milliseconds: 20));
    // On hidraw the buffer is [ID E0][payload]; the firmware payload is
    // `E0 50 80 C6 vv` (AL-V2 §8). The rest is stale data from older reads.
    final fw = Uint8List.sublistView(dev.getInput(0xE0, 65), 1);
    print('  firmware: ${hex(fw.sublist(0, 5))}');
    if (fw[1] == 0x50 && fw[2] == 0x80 && fw[3] == 0xC6) {
      print('    -> v${fw[4] >> 4}.${fw[4] & 0x0F}');
    }

    for (var i = 0; i < 3; i++) {
      sleep(const Duration(milliseconds: 20));
      sendRead(dev, [0xE0, 0x50, 0x00], 7);
      sleep(const Duration(milliseconds: 20));
      final r = dev.getInput(0xE0, 65);
      // Response: ID E0, then 1 byte + 4×u16 big-endian (AL-V2 §2).
      final d = Uint8List.sublistView(r, 1);
      final rpm = [
        for (var g = 0; g < 4; g++) d[2 * g + 1] << 8 | d[2 * g + 2],
      ];
      print('  rpm[$i]: ${hex(d.sublist(0, 9))} -> $rpm');
    }
  } finally {
    dev.close();
  }
}

void ite(HidApi api) {
  final all = api.enumerate(vendorId: _iteVid, productId: _itePid);
  all.forEach((d) => print('  $d'));
  // On hidraw the two collections (0x10 and 0xCC) share the same node; report ID
  // CC selects the correct collection.
  final info = all.where((d) => d.usage == 0xCC).firstOrNull ?? all.firstOrNull;
  if (info == null) return print('  ITE not found');
  final dev = api.openPath(info.path);
  try {
    sendRead(dev, [0xCC, 0x60], 64);
    sleep(const Duration(milliseconds: 20));
    final t = dev.getFeature(0xCC, 64);
    for (var o = 0; o < t.length; o += 8) {
      print(
        '  ${o.toRadixString(16).padLeft(2, '0')}: '
        '${hex(t.sublist(o, (o + 8).clamp(0, t.length)))}',
      );
    }
    final desc = String.fromCharCodes(
      t.sublist(12, 40).takeWhile((c) => c != 0),
    );
    print('    -> fw ${t[4]}.${t[5]}.${t[6]}.${t[7]}  "$desc"');
  } finally {
    dev.close();
  }
}

void main() {
  final api = HidApi.open();
  try {
    print(
      'AL V2 (${_alv2Vid.toRadixString(16)}:${_alv2Pid.toRadixString(16)})',
    );
    alv2(api);
    print('ITE (${_iteVid.toRadixString(16)}:${_itePid.toRadixString(16)})');
    ite(api);
  } finally {
    api.dispose();
  }
}
