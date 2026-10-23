// Device detection. Runs in the engine isolate and only performs reads:
// AL V2 `E0 50 01` (firmware), ITE `CC 60` (info table), and Fury `0xDD`
// (guard). Sends stay blocked by the same checks as the drivers.
import 'dart:io';

import '../../../core/platform/dev_access.dart';
import '../../../core/platform/hid_api.dart';
import '../../../core/platform/hid_exception.dart';
import '../../../core/platform/smbus.dart';
import '../domain/device.dart';
import '../domain/device_info.dart';
import '../domain/device_snapshot.dart';
import '../domain/device_detector.dart';
import 'drivers/alv2/protocol.dart';
import 'drivers/gpu_gigabyte/gpu_exception.dart';
import 'drivers/gpu_gigabyte/gpu_controller.dart';
import 'drivers/gpu_gigabyte/protocol.dart';
import 'drivers/ite5702/protocol.dart';
import 'drivers/kingston_fury/protocol.dart';
import 'process_scan.dart';

class HardwareDeviceDetector implements DeviceDetector {
  HardwareDeviceDetector({this._hid, this.hidError, this.sysfsRoot = '/sys'});

  /// Opens hidapi; if the library is missing, HID devices show an error
  /// instead of crashing the engine.
  factory HardwareDeviceDetector.open() {
    try {
      return HardwareDeviceDetector(hid: HidApi.open());
    } on Object catch (e) {
      return HardwareDeviceDetector(
        hidError: 'libhidapi-hidraw unavailable: $e',
      );
    }
  }

  final HidApi? _hid;
  final String? hidError;
  final String sysfsRoot;

  @override
  String presenceKey() {
    final hid = _hid;
    return [
      if (hid != null) ...[
        for (final d in hid.enumerate(
          vendorId: alv2VendorId,
          productId: alv2ProductId,
        ))
          d.path,
        for (final d in hid.enumerate(
          vendorId: iteVendorId,
          productId: iteProductId,
        ))
          d.path,
      ],
      findI2cBusByName(furyBusName, sysfsRoot: sysfsRoot) ?? '-',
      findI2cBusByName(gpuI2cBusName, sysfsRoot: sysfsRoot) ?? '-',
      ...findConflictingPrograms(),
    ].join('|');
  }

  @override
  DeviceSnapshot scan() => DeviceSnapshot(
    devices: [_probeAlv2(), _probeIte(), ..._probeFury(), _probeGpu()],
    conflicts: findConflictingPrograms(),
    scannedAt: DateTime.now(),
  );

  @override
  void dispose() => _hid?.dispose();

  DeviceInfo _probeAlv2() {
    DeviceInfo info(
      DeviceStatus s, {
      String? detail,
      DeviceIssue? issue,
      String? issueArg,
    }) => DeviceInfo(
      id: 'alv2',
      kind: DeviceKind.fans,
      label: DeviceLabel.alv2Fans,
      model: 'Lian Li UNI FAN AL V2',
      status: s,
      detail: detail,
      issue: issue,
      issueArg: issueArg,
    );

    final hid = _hid;
    if (hid == null) return info(DeviceStatus.error, detail: hidError);
    final all = hid.enumerate(vendorId: alv2VendorId, productId: alv2ProductId);
    if (all.isEmpty) {
      return info(DeviceStatus.missing, issue: DeviceIssue.fanUsbCable);
    }
    // Never fall back to another interface: the composite device also exposes
    // keyboard/consumer interfaces that must not receive the read command.
    final target = all
        .where((d) => d.interfaceNumber == alv2Interface)
        .firstOrNull;
    if (target == null) {
      return info(DeviceStatus.missing, issue: DeviceIssue.fanUsbCable);
    }
    return _withHid(hid, target.path, info, (dev) {
      dev.sendFeature(alv2ReadFirmware, alv2FeatureLength);
      sleep(alv2PacketGap);
      final payload = alv2InputPayload(
        dev.getInput(alv2ReportId, alv2InputLength),
      );
      final fw = parseAlv2Firmware(payload);
      return fw == null
          ? info(DeviceStatus.error, detail: 'unexpected firmware response')
          : info(DeviceStatus.ok, detail: 'firmware v$fw · ${target.path}');
    });
  }

  DeviceInfo _probeIte() {
    DeviceInfo info(
      DeviceStatus s, {
      String? detail,
      DeviceIssue? issue,
      String? issueArg,
    }) => DeviceInfo(
      id: 'ite5702',
      kind: DeviceKind.motherboard,
      label: DeviceLabel.boardAndCase,
      model: 'Gigabyte RGB Fusion 2 (ITE 5702)',
      status: s,
      detail: detail,
      issue: issue,
      issueArg: issueArg,
    );

    final hid = _hid;
    if (hid == null) return info(DeviceStatus.error, detail: hidError);
    final all = hid.enumerate(vendorId: iteVendorId, productId: iteProductId);
    if (all.isEmpty) {
      return info(DeviceStatus.missing, issue: DeviceIssue.motherboardRgb);
    }
    // On hidraw, collections 0x10 and 0xCC share the same node; report ID CC
    // picks the right one.
    final target =
        all.where((d) => d.usage == iteUsage).firstOrNull ?? all.first;
    return _withHid(hid, target.path, info, (dev) {
      checkIteCommand(iteReadInfo);
      dev.sendFeature(iteReadInfo, iteReportLength);
      sleep(const Duration(milliseconds: 20));
      final parsed = parseIteInfo(dev.getFeature(iteReportId, iteReportLength));
      return parsed == null
          ? info(DeviceStatus.error, detail: 'unexpected CC 60 response')
          : info(
              DeviceStatus.ok,
              detail:
                  '${parsed.description} · fw ${parsed.firmware} · ${target.path}',
            );
    });
  }

  DeviceInfo _withHid(
    HidApi hid,
    String path,
    DeviceInfo Function(
      DeviceStatus, {
      String? detail,
      DeviceIssue? issue,
      String? issueArg,
    })
    info,
    DeviceInfo Function(HidDevice dev) body,
  ) {
    final HidDevice dev;
    try {
      dev = hid.openPath(path);
    } on HidException catch (e) {
      return isPermissionDenied(path)
          ? info(
              DeviceStatus.noPermission,
              detail: path,
              issue: DeviceIssue.udevRules,
            )
          : info(DeviceStatus.error, detail: e.message);
    }
    try {
      return body(dev);
    } on HidException catch (e) {
      return info(DeviceStatus.error, detail: e.message);
    } finally {
      dev.close();
    }
  }

  List<DeviceInfo> _probeFury() {
    DeviceInfo info(
      int slot,
      DeviceStatus s, {
      String? detail,
      DeviceIssue? issue,
      String? issueArg,
    }) => DeviceInfo(
      id: slot == 0 ? 'fury' : 'fury-$slot',
      kind: DeviceKind.memory,
      label: slot == 0 ? DeviceLabel.memoryModules : DeviceLabel.memoryModule,
      slot: slot == 0 ? null : slot,
      model: 'Kingston Fury DDR5',
      status: s,
      detail: detail,
      issue: issue,
      issueArg: issueArg,
    );

    final bus = findI2cBusByName(furyBusName, sysfsRoot: sysfsRoot);
    if (bus == null) {
      return [
        info(
          0,
          DeviceStatus.unavailable,
          detail: 'adapter "$furyBusName" missing',
          issue: DeviceIssue.memoryBus,
        ),
      ];
    }
    final SmBus smbus;
    try {
      smbus = SmBus.open(bus);
    } on SmbusException catch (e) {
      return [
        e.permissionDenied
            ? info(
                0,
                DeviceStatus.noPermission,
                detail: bus,
                issue: DeviceIssue.udevRules,
              )
            : info(0, DeviceStatus.error, detail: e.toString()),
      ];
    }
    try {
      return [
        for (final (i, addr) in furyAddresses.indexed)
          _probeFurySlot(smbus, bus, addr, i + 1, info),
      ];
    } finally {
      smbus.close();
    }
  }

  DeviceInfo _probeGpu() {
    DeviceInfo info(
      DeviceStatus s, {
      String? detail,
      DeviceIssue? issue,
      String? issueArg,
    }) => DeviceInfo(
      id: 'gpu',
      kind: DeviceKind.gpu,
      label: DeviceLabel.graphicsCard,
      model: 'Gigabyte RX 9060 XT',
      status: s,
      detail: detail,
      issue: issue,
      issueArg: issueArg,
    );

    final GpuController gpu;
    try {
      gpu = GpuController.open(sysfsRoot: sysfsRoot);
    } on GpuException catch (e) {
      return e.permissionDenied
          ? info(
              DeviceStatus.noPermission,
              detail: e.message,
              issue: DeviceIssue.udevRules,
            )
          : info(DeviceStatus.unavailable, detail: e.message);
    }
    try {
      if (!gpu.init()) {
        return info(
          DeviceStatus.blocked,
          detail: gpu.disabledReason,
          issue: DeviceIssue.gpuSsid,
        );
      }
      final node = gpu.busPath?.split('/').last ?? '?';
      return info(
        DeviceStatus.ok,
        detail: 'SSID 0x2429 · fw ${gpu.firmware} · $node',
      );
    } finally {
      gpu.close();
    }
  }

  DeviceInfo _probeFurySlot(
    SmBus smbus,
    String bus,
    int addr,
    int slot,
    DeviceInfo Function(
      int,
      DeviceStatus, {
      String? detail,
      DeviceIssue? issue,
      String? issueArg,
    })
    info,
  ) {
    final where = '${bus.split('/').last} 0x${addr.toRadixString(16)}';
    final int dd;
    try {
      dd = smbus.readByteData(addr, furyGuardRegister);
    } on SmbusException {
      return info(
        slot,
        DeviceStatus.missing,
        detail: '$where · no response',
        issue: DeviceIssue.noResponse,
        issueArg: where,
      );
    }
    final ddHex = '0x${dd.toRadixString(16).padLeft(2, '0').toUpperCase()}';
    return furyGuardAllows(dd)
        ? info(slot, DeviceStatus.ok, detail: '$where · guard 0xDD = $ddHex')
        : info(
            slot,
            DeviceStatus.blocked,
            detail: '$where · 0xDD = $ddHex (PWM controller)',
            issue: DeviceIssue.unsafeAddress,
          );
  }
}
