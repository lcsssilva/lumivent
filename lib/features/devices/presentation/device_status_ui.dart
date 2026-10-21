import 'package:flutter/material.dart';

import '../../../core/ui/theme.dart';
import '../domain/device.dart';

extension DeviceStatusUi on DeviceStatus {
  String get label => switch (this) {
    DeviceStatus.ok => 'Conectado',
    DeviceStatus.missing => 'Não encontrado',
    DeviceStatus.noPermission => 'Sem permissão',
    DeviceStatus.unavailable => 'Indisponível',
    DeviceStatus.blocked => 'Bloqueado',
    DeviceStatus.unsupported => 'Sem suporte',
    DeviceStatus.error => 'Erro',
  };

  Color get color => switch (this) {
    DeviceStatus.ok => WeColors.ok,
    DeviceStatus.missing || DeviceStatus.unsupported => WeColors.muted,
    DeviceStatus.noPermission ||
    DeviceStatus.unavailable ||
    DeviceStatus.blocked => WeColors.warn,
    DeviceStatus.error => WeColors.danger,
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
