import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/app_strings.dart';
import '../../../core/i18n/app_strings_scope.dart';
import '../../../core/i18n/catalogs/system_strings.dart';
import '../../../core/ui/theme.dart';
import '../../../core/ui/we_card.dart';
import '../application/runtime_checks.dart';
import '../application/system_controller.dart';
import '../domain/diagnostics.dart';

class DiagnosticsCard extends ConsumerWidget {
  const DiagnosticsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final checks = [
      ...ref.watch(diagnosticsProvider),
      ...ref.watch(runtimeChecksProvider),
    ];
    final strings = context.strings;
    return WeCard(
      title: strings.settings.permissionsAndSystem,
      child: Column(
        children: [
          for (final c in checks)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Icon(
                    switch (c.state) {
                      CheckState.ok => Icons.check_circle_outline,
                      CheckState.warn => Icons.error_outline,
                      CheckState.pending => Icons.schedule,
                    },
                    size: 18,
                    color: switch (c.state) {
                      CheckState.ok => WeColors.ok,
                      CheckState.warn => WeColors.warn,
                      CheckState.pending => WeColors.muted,
                    },
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 220,
                    child: Text(diagnosticLabel(c.id, strings.system)),
                  ),
                  Expanded(
                    child: Text(
                      diagnosticDetail(c, strings),
                      style: const TextStyle(
                        color: WeColors.muted,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

String diagnosticLabel(DiagnosticId id, SystemStrings s) => switch (id) {
  DiagnosticId.udevRules => s.udevRules,
  DiagnosticId.boardSensors => s.boardSensors,
  DiagnosticId.memorySmbus => s.memorySmbus,
  DiagnosticId.memoryTemperature => s.memoryTemperature,
  DiagnosticId.nvmeHelper => s.nvmeSmartHelper,
  DiagnosticId.hubRpmSync => s.hubRpmSync,
  DiagnosticId.hubArgbSync => s.hubArgbSync,
  DiagnosticId.lightingLoop => s.lightingLoop,
};

String diagnosticDetail(DiagnosticCheck check, AppStrings strings) {
  final s = strings.system;
  final data = check.data;
  return switch (check.id) {
    DiagnosticId.udevRules =>
      (data['installed'] == true)
          ? s.udevInstalled(data['file'] as String)
          : s.udevMissing(data['file'] as String),
    DiagnosticId.boardSensors => _boardSensors(data, s),
    DiagnosticId.memorySmbus => _memorySmbus(data, s),
    DiagnosticId.memoryTemperature => _memoryTemperature(data, s),
    DiagnosticId.nvmeHelper => _nvmeHelper(data, s),
    DiagnosticId.hubRpmSync => switch (check.state) {
      CheckState.pending => s.hubRpmSyncPending,
      CheckState.ok => s.hubRpmSyncOk,
      CheckState.warn => s.hubRpmSyncWarn,
    },
    DiagnosticId.hubArgbSync => switch (check.state) {
      CheckState.pending => s.hubArgbSyncPending,
      CheckState.ok => s.hubArgbSyncOk,
      CheckState.warn => switch (data['issue']) {
        final int issue => strings.lighting.outputIssue(
          issue,
          (data['args'] as List?)?.cast<String>() ?? const [],
        ),
        _ => s.hubUnavailable,
      },
    },
    DiagnosticId.lightingLoop => _lightingLoop(data, strings),
  };
}

String _boardSensors(Map<String, Object?> data, SystemStrings s) {
  final modules = (data['modules'] as List?)?.cast<String>() ?? const [];
  return modules.isEmpty
      ? s.boardSensorsMissing
      : s.boardSensorsLoaded(modules.join(' + '));
}

String _memorySmbus(Map<String, Object?> data, SystemStrings s) {
  final bus = data['bus'] as String?;
  return bus == null ? s.memorySmbusMissing : s.memorySmbusOk(bus);
}

String _memoryTemperature(Map<String, Object?> data, SystemStrings s) {
  final driver = data['driver'] as String?;
  return driver == null
      ? s.memoryTemperatureMissing
      : s.memoryTemperatureOk(driver);
}

String _nvmeHelper(Map<String, Object?> data, SystemStrings s) {
  final path = data['path'] as String?;
  if (path == null) return s.nvmeHelperMissing;
  return data['hasCaps'] == true
      ? s.nvmeHelperOk(path)
      : s.nvmeHelperNoCaps(path);
}

String _lightingLoop(Map<String, Object?> data, AppStrings strings) {
  final s = strings.system;
  final loops = (data['loops'] as List?)?.cast<LoopData>() ?? const [];
  return loops
      .map((loop) {
        final (family, fps, sendMs) = loop;
        final name = switch (family) {
          'fans' => s.loopFamilyFans,
          'board' => s.loopFamilyBoard,
          'ram' => s.loopFamilyRam,
          _ => s.loopFamilyGpu,
        };
        final value = fps == null
            ? '—'
            : sendMs == null
            ? s.loopFps(strings.decimal(fps, 1))
            : s.loopFpsMs(strings.decimal(fps, 1), strings.decimal(sendMs, 1));
        return s.loopValue(name, value);
      })
      .join(' · ');
}
