import 'package:flutter_test/flutter_test.dart';
import 'package:lumivent/core/i18n/app_strings.dart';
import 'package:lumivent/features/fans/fans.dart';
import 'package:lumivent/features/lighting/lighting.dart';
import 'package:lumivent/features/system/application/runtime_checks.dart';
import 'package:lumivent/features/system/application/hub_argb_sync_data.dart';
import 'package:lumivent/features/system/domain/diagnostics.dart';
import 'package:lumivent/features/system/domain/udev_rules_data.dart';
import 'package:lumivent/features/system/domain/board_sensors_data.dart';
import 'package:lumivent/features/system/domain/nvme_helper_data.dart';
import 'package:lumivent/features/system/domain/diagnostic_check.dart';
import 'package:lumivent/features/system/presentation/widgets/diagnostics_card.dart';

LightingStatus light(
  LightOutputState fans, {
  LightOutputIssue? issue,
  List<String> args = const [],
}) => LightingStatus(
  {LightDeviceId.alv2Group1: LightOutputStatus(fans, issue: issue, args: args)},
  fps: 30,
  loops: const {
    OutputFamily.fans: LoopStats(fps: 2, sendMs: 48.2),
    OutputFamily.ite: LoopStats(fps: 30, sendMs: 0.9),
    OutputFamily.ram: LoopStats(fps: 0, sendMs: null),
    OutputFamily.gpu: LoopStats(fps: 8, sendMs: 124),
  },
);

void main() {
  test('nothing from the engine yet: both hub checks pending', () {
    final c = runtimeChecks(null, null);
    expect(c.map((c) => c.state), [CheckState.pending, CheckState.pending]);
  });

  test('RPM sync turned off by the app is ok, not yet is a warning', () {
    expect(
      runtimeChecks(
        const FansStatus([], hubOk: true, syncOff: true),
        null,
      ).first.state,
      CheckState.ok,
    );
    expect(
      runtimeChecks(const FansStatus([], hubOk: false), null).first.state,
      CheckState.warn,
    );
  });

  test('ARGB sync and merge follow the hub init', () {
    expect(
      runtimeChecks(null, light(LightOutputState.ok))[1].state,
      CheckState.ok,
    );
    final down = runtimeChecks(
      null,
      light(LightOutputState.unavailable, issue: LightOutputIssue.ite),
    )[1];
    expect(down.state, CheckState.warn);
    expect((down.data as HubArgbSyncData).status?.issue, LightOutputIssue.ite);
    expect(
      diagnosticDetail(down, AppStrings.en),
      AppStrings.en.lighting.outputIte,
    );
  });

  test('typed data feeds the sentences of the static checks', () {
    final strings = AppStrings.en.system;
    expect(
      diagnosticDetail(
        const DiagnosticCheck(
          DiagnosticId.nvmeHelper,
          CheckState.ok,
          NvmeHelperData(path: '/x/helper', hasCaps: true),
        ),
        AppStrings.en,
      ),
      strings.nvmeHelperOk('/x/helper'),
    );
    expect(
      diagnosticDetail(
        const DiagnosticCheck(
          DiagnosticId.boardSensors,
          CheckState.warn,
          BoardSensorsData([]),
        ),
        AppStrings.en,
      ),
      strings.boardSensorsMissing,
    );
    expect(
      diagnosticDetail(
        const DiagnosticCheck(
          DiagnosticId.udevRules,
          CheckState.ok,
          UdevRulesData(installed: true),
        ),
        AppStrings.en,
      ),
      strings.udevInstalled(udevRulesFileName),
    );
  });

  test('loop line shows fps and send time per family', () {
    final loop = runtimeChecks(null, light(LightOutputState.ok)).last;
    expect(loop.id, DiagnosticId.lightingLoop);
    expect(
      diagnosticDetail(loop, AppStrings.pt),
      'fans 2,0 fps, 48,2 ms · placa/gabinete 30,0 fps, 0,9 ms · RAM 0,0 fps '
      '· GPU 8,0 fps, 124,0 ms',
    );
  });
}
