import 'package:flutter/material.dart';

import '../../../core/i18n/app_strings.dart';
import '../../../core/ui/we_colors.dart';
import '../domain/device.dart';
import '../domain/device_info.dart';

extension DeviceStatusUi on DeviceStatus {
  String label(AppStrings strings) {
    final s = strings.devices;
    return switch (this) {
      DeviceStatus.ok => s.connected,
      DeviceStatus.missing => s.notFound,
      DeviceStatus.noPermission => s.noPermission,
      DeviceStatus.unavailable => s.unavailable,
      DeviceStatus.blocked => s.blocked,
      DeviceStatus.unsupported => s.unsupported,
      DeviceStatus.error => s.error,
    };
  }

  Color get color => switch (this) {
    DeviceStatus.ok => WeColors.ok,
    DeviceStatus.missing || DeviceStatus.unsupported => WeColors.muted,
    DeviceStatus.noPermission ||
    DeviceStatus.unavailable ||
    DeviceStatus.blocked => WeColors.warn,
    DeviceStatus.error => WeColors.danger,
  };
}

/// Localized generic device name. The model (hardware) is not translated.
String deviceName(DeviceInfo device, AppStrings strings) {
  final s = strings.devices;
  return switch (device.label) {
    DeviceLabel.alv2Fans => s.alv2Fans,
    DeviceLabel.boardAndCase => s.boardAndCase,
    DeviceLabel.memoryModules => s.memoryModules,
    DeviceLabel.memoryModule => s.memoryModule(device.slot ?? 0),
    DeviceLabel.graphicsCard => s.graphicsCard,
  };
}

/// What the user can do about [DeviceInfo.issue], if any.
String? deviceIssue(DeviceInfo device, AppStrings strings) {
  final s = strings.devices;
  return switch (device.issue) {
    null => null,
    DeviceIssue.udevRules => s.udevRulesHint,
    DeviceIssue.fanUsbCable => s.fanUsbCableHint,
    DeviceIssue.motherboardRgb => s.motherboardRgbHint,
    DeviceIssue.memoryBus => s.memoryBusHint,
    DeviceIssue.gpuSsid => s.gpuSsidHint,
    DeviceIssue.unsafeAddress => s.unsafeAddressHint,
    DeviceIssue.noResponse => s.noResponse(device.issueArg ?? ''),
  };
}

/// Worst status of a device group (for the summary).
DeviceStatus worstStatus(Iterable<DeviceStatus> all) {
  const rank = [
    DeviceStatus.error,
    DeviceStatus.noPermission,
    DeviceStatus.unavailable,
    DeviceStatus.blocked,
    DeviceStatus.missing,
    DeviceStatus.unsupported,
    DeviceStatus.ok,
  ];
  return all.reduce((a, b) => rank.indexOf(a) <= rank.indexOf(b) ? a : b);
}
