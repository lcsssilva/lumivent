import 'dart:convert';
import 'dart:isolate' show TransferableTypedData;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:lumivent/features/lighting/domain/light_device.dart';
import 'package:lumivent/features/lighting/domain/rgb.dart';
import 'package:lumivent/features/lighting/infrastructure/html_effects/effect_worker_protocol.dart';

/// Wraps a request in a numbered envelope, as the worker sees it.
List<Object?> numbered(List<Object?> request) => [7, ...request];

EffectWorkerRequest? parseRequest(List<Object?> requestBody) =>
    EffectWorkerRequest.tryParse(numbered(requestBody));

void main() {
  test('request builders round-trip through the worker parse', () {
    final load = parseRequest(loadRequest('<html>', 'shim.js', {'speed': 10}))!;
    expect(load.id, 7);
    expect(load.operation, EffectWorkerOperation.load);
    expect(load.html(), '<html>');
    expect(load.shim(), 'shim.js');
    expect(load.values(), {'speed': 10});

    final frame = parseRequest(frameRequest(16.5))!;
    expect(frame.operation, EffectWorkerOperation.frame);
    expect(frame.frameTime(), 16.5);

    final points = parseRequest(pointsRequest(null))!;
    expect(points.operation, EffectWorkerOperation.points);
    expect(points.samplePoints, isNull);

    final property = parseRequest(propertyRequest('speed', 80))!;
    expect(property.operation, EffectWorkerOperation.property);
    expect(property.propertyName(), 'speed');
    expect(property.propertyValue(), 80);

    final sensors = parseRequest(sensorsRequest({'cpu.tctl': 55.0}))!;
    expect(sensors.operation, EffectWorkerOperation.sensors);
    expect(sensors.sensorValues(), {'cpu.tctl': 55.0});

    expect(parseRequest(logRequest())!.operation, EffectWorkerOperation.log);
    expect(
      parseRequest(disposeRequest())!.operation,
      EffectWorkerOperation.dispose,
    );
  });

  test('sample point builders round-trip through the codec', () {
    const points = [
      (LightDeviceId.gpu, 5, 0x40),
      (LightDeviceId.alv2Group1, 0, 0),
    ];
    final request = parseRequest(pointsRequest(encodeSamplePoints(points)))!;
    expect(request.samplePoints, points);
  });

  test('malformed envelope shapes are rejected, not cast', () {
    for (final bad in <Object?>[
      null,
      0,
      [],
      [0],
      ['7', 'frame'],
      [1, 2],
      [-1, 'frame', 1],
      ['7', 'frame', 1],
    ]) {
      expect(
        EffectWorkerRequest.tryParse(bad),
        isNull,
        reason: '$bad must parse to null',
      );
    }
  });

  test(
    'unknown ops parse as requests for the worker to answer with errors',
    () {
      final request = parseRequest(['unknown-op', 'extra'])!;
      expect(request.id, 7);
      expect(request.op, 'unknown-op');
      request.arguments.length;
      expect(request.arguments, ['extra']);
    },
  );

  test('reply envelope parses both answers and rejects the rest', () {
    final ok = EffectWorkerReply.tryParse([3, true, 'value'])!;
    expect(ok.id, 3);
    expect(ok.ok, isTrue);
    expect(ok.payload, 'value');

    final failed = EffectWorkerReply.tryParse([
      3,
      false,
      ['boom', 'stack'],
    ])!;
    expect(failed.ok, isFalse);
    expect(failed.errorMessage, 'boom');

    for (final bad in <Object?>[
      null,
      [],
      [1, true],
      ['1', true, 'x'],
      [1, 'ok', 'x'],
    ]) {
      expect(
        EffectWorkerReply.tryParse(bad),
        isNull,
        reason: '$bad must parse to null',
      );
    }
  });

  test('frame reply reads transferable payloads (isolate transport)', () {
    final reply = frameReply(
      pixelsOrOps: Uint8List.fromList(const [1, 2, 3, 4]),
      simple: false,
      opCount: -1,
      logs: const ['first'],
      scriptTime: const Duration(milliseconds: 2),
      colors: null,
    );
    final parsed = parseFrameReply(reply);
    expect(parsed.pixelsOrOps, const [1, 2, 3, 4]);
    expect(parsed.simple, isFalse);
    expect(parsed.opCount, -1);
    expect(parsed.logs, const ['first']);
    expect(parsed.scriptTime, const Duration(milliseconds: 2));
    expect(parsed.colors, isNull);
  });

  test('frame reply reads typed data, bytes and base64 forms', () {
    Uint8List asType(Uint8List bytes) => bytes;

    Object transferPayload() => TransferableTypedData.fromList([
      asType(Uint8List.fromList([9, 8])),
    ]);
    final fromTransferable = parseFrameReply([
      transferPayload(),
      true,
      2,
      const <String>[],
      5,
      null,
    ]);
    expect(fromTransferable.pixelsOrOps, [9, 8]);
    expect(fromTransferable.opCount, 2);

    final fromBytes = parseFrameReply([
      Uint8List.fromList([1]),
      true,
      3,
      const <String>[],
      5,
      null,
    ]);
    expect(fromBytes.pixelsOrOps, [1]);

    final fromBase64 = parseFrameReply([
      base64Encode([1, 2, 3, 4]),
      true,
      4,
      const <String>[],
      5,
      null,
    ]);
    expect(fromBase64.pixelsOrOps, [1, 2, 3, 4]);
  });

  test('frame reply rejects malformed payloads', () {
    expect(
      () => parseFrameReply([1, true, 1, [], 0, null]),
      throwsFormatException,
      reason: 'unknown payload type',
    );
    expect(
      () => parseFrameReply([
        base64Encode([1]),
      ]),
      throwsFormatException,
      reason: 'short payload',
    );
    expect(
      () => parseFrameReply([
        base64Encode([1, 2, 3, 4]),
        true,
        1,
        const <String>[],
        0,
        'not-a-map',
      ]),
      throwsFormatException,
      reason: 'colors payload',
    );
  });

  test('sampled colors round-trip and invalid entries return null', () {
    final colors = {
      LightDeviceId.gpu: const [Rgb(255, 0, 0), Rgb(0, 255, 0)],
      LightDeviceId.ram1: const [Rgb(1, 2, 3)],
    };
    // Both transmits: named keys (JSON), enum keys (SendPort).
    final encoded = encodeSampledColors(colors);
    expect(decodeSampledColors(encoded), colors);
    expect(decodeSampledColors(colors), colors);

    for (final bad in <Object?>[
      'x',
      1,
      {'gpu': 'x'},
      {'not-a-device': []},
      {
        LightDeviceId.gpu: [
          [255, 0],
        ],
      },
      {
        LightDeviceId.gpu: [
          [255, 0.0, 0],
        ],
      },
      {LightDeviceId.gpu: 'ff0000'},
    ]) {
      expect(
        decodeSampledColors(bad),
        isNull,
        reason: '$bad must decode to null',
      );
    }
  });
}
