import 'package:flutter/material.dart';

import '../../../../core/i18n/app_strings.dart';
import '../../../../core/i18n/app_strings_scope.dart';
import '../../../../core/i18n/catalogs/system_strings.dart';
import '../../../../core/ui/we_colors.dart';
import '../../../../core/ui/we_card.dart';
import '../../../lighting/lighting.dart'
    show LightOutputStatus, outputIssueLabel;
import '../../application/hub_argb_sync_data.dart';
import '../../domain/diagnostics.dart';
import '../../domain/udev_rules_data.dart';
import '../../domain/board_sensors_data.dart';
import '../../domain/memory_smbus_data.dart';
import '../../domain/memory_temperature_data.dart';
import '../../domain/nvme_helper_data.dart';
import '../../domain/loop_sample.dart';
import '../../domain/lighting_loop_data.dart';
import '../../domain/diagnostic_check.dart';

class DiagnosticsCard extends StatelessWidget {
  const DiagnosticsCard({super.key, required this.checks});

  /// Environment checks followed by the checks of the running engine.
  final List<DiagnosticCheck> checks;

  @override
  Widget build(BuildContext context) {
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
    DiagnosticId.udevRules => switch (data) {
      UdevRulesData(installed: true) => s.udevInstalled(udevRulesFileName),
      _ => s.udevMissing(udevRulesFileName),
    },
    DiagnosticId.boardSensors => switch (data) {
      BoardSensorsData(:final modules) when modules.isNotEmpty =>
        s.boardSensorsLoaded(modules.join(' + ')),
      _ => s.boardSensorsMissing,
    },
    DiagnosticId.memorySmbus => switch (data) {
      MemorySmbusData(:final bus?) => s.memorySmbusOk(bus),
      _ => s.memorySmbusMissing,
    },
    DiagnosticId.memoryTemperature => switch (data) {
      MemoryTemperatureData(:final driver?) => s.memoryTemperatureOk(driver),
      _ => s.memoryTemperatureMissing,
    },
    DiagnosticId.nvmeHelper => switch (data) {
      NvmeHelperData(:final path?, hasCaps: true) => s.nvmeHelperOk(path),
      NvmeHelperData(:final path?) => s.nvmeHelperNoCaps(path),
      _ => s.nvmeHelperMissing,
    },
    DiagnosticId.hubRpmSync => switch (check.state) {
      CheckState.pending => s.hubRpmSyncPending,
      CheckState.ok => s.hubRpmSyncOk,
      CheckState.warn => s.hubRpmSyncWarn,
    },
    DiagnosticId.hubArgbSync => switch (check.state) {
      CheckState.pending => s.hubArgbSyncPending,
      CheckState.ok => s.hubArgbSyncOk,
      CheckState.warn => switch (data) {
        HubArgbSyncData(
          status: LightOutputStatus(:final issue?, :final args),
        ) =>
          outputIssueLabel(strings, issue, args),
        _ => s.hubUnavailable,
      },
    },
    DiagnosticId.lightingLoop => switch (data) {
      LightingLoopData(:final loops) => _lightingLoop(loops, strings),
      _ => '',
    },
  };
}

String _lightingLoop(List<LoopSample> loops, AppStrings strings) {
  final s = strings.system;
  return loops
      .map((loop) {
        final name = switch (loop.family) {
          LoopFamily.fans => s.loopFamilyFans,
          LoopFamily.board => s.loopFamilyBoard,
          LoopFamily.ram => s.loopFamilyRam,
          LoopFamily.gpu => s.loopFamilyGpu,
        };
        final fps = loop.fps;
        final sendMs = loop.sendMs;
        final value = fps == null
            ? '—'
            : sendMs == null
            ? s.loopFps(strings.decimal(fps, 1))
            : s.loopFpsMs(strings.decimal(fps, 1), strings.decimal(sendMs, 1));
        return s.loopValue(name, value);
      })
      .join(' · ');
}
