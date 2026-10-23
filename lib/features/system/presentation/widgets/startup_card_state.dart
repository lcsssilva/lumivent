part of 'startup_card.dart';

class _StartupCardState extends State<StartupCard>
    with AsyncActionMixin<StartupCard> {
  Future<void> _set(bool on) => run(() => widget.onChanged(on));

  @override
  Widget build(BuildContext context) {
    final autostart = widget.autostart;
    final location = widget.location;
    final state = autostart.value;
    final strings = context.strings;
    final s = strings.settings;
    final error = autostart.error;
    final errorText = switch (error) {
      null => null,
      AutostartException e => strings.system.autostartFailed(
        e.command,
        e.stderr,
      ),
      _ => '${strings.common.technicalDetails}: $error',
    };
    return WeCard(
      title: s.startup,
      child: SettingRow(
        title: s.startAtLogin,
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(s.systemdUnit(location)),
            if (state?.stale ?? false)
              Text(s.staleUnit, style: const TextStyle(color: WeColors.warn)),
            if (errorText != null)
              Text(errorText, style: const TextStyle(color: WeColors.danger)),
          ],
        ),
        control: Switch(
          value: state?.enabled ?? false,
          onChanged: isRunning || autostart.isLoading ? null : _set,
        ),
      ),
    );
  }
}
