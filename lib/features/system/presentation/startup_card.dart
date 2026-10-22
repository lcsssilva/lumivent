import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/app_strings_scope.dart';
import '../../../core/ui/async_action.dart';
import '../../../core/ui/theme.dart';
import '../../../core/ui/we_card.dart';
import '../../../core/ui/setting_row.dart';
import '../application/system_controller.dart';
import '../domain/autostart.dart';

class StartupCard extends ConsumerStatefulWidget {
  const StartupCard({super.key});

  @override
  ConsumerState<StartupCard> createState() => _StartupCardState();
}

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
