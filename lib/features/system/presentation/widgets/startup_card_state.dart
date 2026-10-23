part of 'startup_card.dart';

class _StartupCardState extends ConsumerState<StartupCard>
    with AsyncActionMixin<StartupCard> {
  Future<void> _set(bool on) =>
      run(() => ref.read(autostartProvider.notifier).setEnabled(on));

  @override
  Widget build(BuildContext context) {
    final autostart = ref.watch(autostartProvider);
    final location = ref.watch(autostartServiceProvider).location;
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
