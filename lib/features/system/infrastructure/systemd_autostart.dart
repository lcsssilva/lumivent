// Autostart through a `systemd --user` unit.
//
// The unit is bound to `graphical-session.target` (Plasma 6 activates it at
// login), starts the app with `--minimized`, and restarts only on failure:
// exiting through the tray returns code 0 and does not restart.
import 'dart:io';

import '../domain/autostart/autostart_error.dart';
import '../domain/autostart/autostart_state.dart';
import '../domain/autostart/autostart_exception.dart';
import '../domain/autostart/autostart_service.dart';

typedef ProcessRunner = Future<ProcessResult> Function(
  String exe,
  List<String> args,
);

Future<ProcessResult> _run(String exe, List<String> args) =>
    Process.run(exe, args);

/// Quotes an argument for the systemd command line (`ExecStart=`).
String systemdQuote(String arg) {
  final escaped = arg
      .replaceAll(r'\', r'\\')
      .replaceAll('"', r'\"')
      .replaceAll('%', '%%')
      .replaceAll(r'$', r'$$');
  return '"$escaped"';
}

String buildAutostartUnit(String executable) =>
    '''
[Unit]
Description=Lumivent (lighting, fan control, and monitoring)
PartOf=graphical-session.target
After=graphical-session.target

[Service]
Type=simple
ExecStart=${systemdQuote(executable)} --minimized
Restart=on-failure
RestartSec=5

[Install]
WantedBy=graphical-session.target
''';

class SystemdAutostart implements AutostartService {
  SystemdAutostart({
    required this.executable,
    Directory? unitDir,
    ProcessRunner run = _run,
  }) : unitDir = unitDir ?? _defaultUnitDir(),
       _runner = run;

  static const unitName = 'lumivent.service';

  /// Binary the unit starts (the currently running app).
  final String executable;
  final Directory unitDir;
  final ProcessRunner _runner;

  File get unitFile => File('${unitDir.path}/$unitName');

  @override
  String get location => unitFile.path;

  @override
  Future<AutostartState> status() async => AutostartState(
    enabled: await isEnabled(),
    stale: await pointsElsewhere(),
  );

  static Directory _defaultUnitDir() {
    final env = Platform.environment;
    final xdg = env['XDG_CONFIG_HOME'];
    final base = (xdg != null && xdg.isNotEmpty)
        ? xdg
        : '${env['HOME']}/.config';
    return Directory('$base/systemd/user');
  }

  /// Active = file present and `systemctl --user is-enabled` says "enabled".
  Future<bool> isEnabled() async {
    if (!await unitFile.exists()) return false;
    final r = await _runner('systemctl', ['--user', 'is-enabled', unitName]);
    return r.exitCode == 0 && (r.stdout as String).trim() == 'enabled';
  }

  /// Does the unit point to another binary (for example, an old build)?
  Future<bool> pointsElsewhere() async {
    if (!await unitFile.exists()) return false;
    return await unitFile.readAsString() != buildAutostartUnit(executable);
  }

  @override
  Future<void> enable() async {
    await unitDir.create(recursive: true);
    await unitFile.writeAsString(buildAutostartUnit(executable), flush: true);
    await _systemctl(['daemon-reload']);
    await _systemctl(['enable', unitName]);
  }

  @override
  Future<void> disable() async {
    if (await unitFile.exists()) {
      await _systemctl(['disable', unitName]);
      await unitFile.delete();
    }
    await _systemctl(['daemon-reload']);
  }

  Future<void> _systemctl(List<String> args) async {
    final r = await _runner('systemctl', ['--user', ...args]);
    if (r.exitCode != 0) {
      throw AutostartException(
        AutostartError.systemctlFailed,
        command: 'systemctl --user ${args.join(' ')}',
        stderr: (r.stderr as String).trim(),
      );
    }
  }
}
