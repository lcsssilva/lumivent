// Decodes the binary command buffer produced by canvas2d_shim.js.
//
// Layout per command: opcode (u8), argument count (u8), then each argument as
// tag (u8) + payload: 0 = float32, 1 = u16 length + UTF-8, 2 = gradient id
// (float32), 3 = packed ARGB color (uint32). Little endian.

import 'dart:convert';
import 'dart:typed_data';

/// Opcodes shared with the JS shim. Keep the two tables in sync.
abstract final class CanvasOp {
  static const unknown = 0;
  static const fillStyle = 1, strokeStyle = 2, lineWidth = 3, alpha = 4;
  static const composite = 5, lineCap = 6, lineJoin = 7;
  static const save = 8, restore = 9;
  static const translate = 10, rotate = 11, scale = 12, transform = 13;
  static const setTransform = 14;
  static const clearRect = 15, fillRect = 16, strokeRect = 17;
  static const beginPath = 18, closePath = 19, moveTo = 20, lineTo = 21;
  static const rect = 22, arc = 23, ellipse = 24, quadratic = 25, bezier = 26;
  static const fill = 27, stroke = 28, clip = 29;
  static const linearGradient = 30, radialGradient = 31, colorStop = 32;

  /// Compact opaque fill rect: opcode, 4×int16, packed ARGB (13 bytes).
  static const fillRect16 = 33;

  /// Fill style as HSL (h, s, l floats) when `hsl()` is parsed in Dart.
  static const hslStyle = 34;

  /// Compact opaque HSL fill rect: opcode, 4×int16, int16 hue×10, u8 s, u8 l.
  static const fillRect16Hsl = 35;
}

class CanvasCommandBuffer {
  CanvasCommandBuffer(Uint8List bytes)
    : _bytes = bytes,
      _data = ByteData.sublistView(bytes) {
    if (bytes.lengthInBytes > maxBytes) {
      throw const FormatException('Canvas command buffer exceeds byte limit');
    }
  }

  static const maxBytes = 4 * 1024 * 1024;
  static const maxOps = 200000;

  final Uint8List _bytes;
  final ByteData _data;
  int _pos = 0;

  final _numbers = Float64List(8);
  final _colors = Uint32List(8);
  final _strings = List<String?>.filled(8, null);
  final _tags = Uint8List(8);

  int opcode = 0;
  int argCount = 0;
  int count = 0;

  bool get hasNext => _pos < _data.lengthInBytes;

  void _require(int length) {
    if (length < 0 || _pos > _data.lengthInBytes - length) {
      throw const FormatException('Truncated canvas command buffer');
    }
  }

  void _countOp() {
    count++;
    if (count > maxOps) {
      throw const FormatException('Canvas command buffer exceeds op limit');
    }
  }

  bool next() {
    if (!hasNext) return false;
    _require(2);
    opcode = _data.getUint8(_pos++);
    if (opcode == CanvasOp.fillRect16) {
      _require(12);
      argCount = 5;
      for (var i = 0; i < 4; i++) {
        _numbers[i] = _data.getInt16(_pos, Endian.little).toDouble();
        _pos += 2;
        _strings[i] = null;
        _tags[i] = 0;
      }
      _colors[4] = _data.getUint32(_pos, Endian.little);
      _pos += 4;
      _strings[4] = null;
      _tags[4] = 3;
      _countOp();
      return true;
    }
    if (opcode == CanvasOp.fillRect16Hsl) {
      _require(12);
      argCount = 7;
      for (var i = 0; i < 4; i++) {
        _numbers[i] = _data.getInt16(_pos, Endian.little).toDouble();
        _pos += 2;
        _strings[i] = null;
        _tags[i] = 0;
      }
      _numbers[4] = _data.getInt16(_pos, Endian.little) / 10.0;
      _pos += 2;
      _numbers[5] = _data.getUint8(_pos++).toDouble();
      _numbers[6] = _data.getUint8(_pos++).toDouble();
      for (var i = 4; i < 7; i++) {
        _strings[i] = null;
        _tags[i] = 0;
      }
      _countOp();
      return true;
    }
    argCount = _data.getUint8(_pos++);
    if (argCount > _tags.length) {
      throw FormatException('Canvas op with $argCount arguments');
    }
    for (var i = 0; i < argCount; i++) {
      _require(1);
      final tag = _data.getUint8(_pos++);
      _tags[i] = tag;
      switch (tag) {
        case 0:
        case 2:
          _require(4);
          _numbers[i] = _data.getFloat32(_pos, Endian.little);
          _pos += 4;
          _strings[i] = null;
        case 3:
          _require(4);
          _colors[i] = _data.getUint32(_pos, Endian.little);
          _pos += 4;
          _strings[i] = null;
        case 1:
          _require(2);
          final len = _data.getUint16(_pos, Endian.little);
          _pos += 2;
          _require(len);
          _strings[i] = utf8.decode(
            Uint8List.sublistView(_bytes, _pos, _pos + len),
          );
          _pos += len;
        default:
          throw FormatException('Unknown argument tag: $tag');
      }
    }
    _countOp();
    return true;
  }

  /// The argument [i] as a number (also gradient ids).
  double number(int i) => _numbers[i];

  /// Whether argument [i] is a gradient reference.
  bool isGradient(int i) => _tags[i] == 2;

  /// Whether argument [i] is a packed ARGB color.
  bool isColor(int i) => _tags[i] == 3;

  /// ARGB value of a packed color argument.
  int color(int i) => _colors[i];

  /// The argument [i] as text (empty when it is a number).
  String text(int i) => _strings[i] ?? '';
}
