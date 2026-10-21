import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ui/theme.dart';
import '../../../core/ui/widgets.dart';
import '../application/system_controller.dart';

class StartupCard extends ConsumerStatefulWidget {
  const StartupCard({super.key});

  @override
  ConsumerState<StartupCard> createState() => _StartupCardState();
}

class _StartupCardState extends ConsumerState<StartupCard> {
  bool _busy = false;

  Future<void> _set(bool on) async {
    setState(() => _busy = true);
    await ref.read(autostartProvider.notifier).setEnabled(on);
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final autostart = ref.watch(autostartProvider);
    final location = ref.watch(autostartServiceProvider).location;
    final state = autostart.value;
    return WeCard(
      title: 'Inicialização',
      child: SettingRow(
        title: 'Iniciar com o sistema',
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Unidade systemd --user, inicia minimizado na bandeja: $location',
            ),
            if (state?.stale ?? false)
              const Text(
                'A unidade instalada aponta para outro executável. '
                'Desative e ative de novo para usar este.',
                style: TextStyle(color: WeColors.warn),
              ),
            if (autostart.hasError)
              Text(
                '${autostart.error}',
                style: const TextStyle(color: WeColors.danger),
              ),
          ],
        ),
        control: Switch(
          value: state?.enabled ?? false,
          onChanged: _busy || autostart.isLoading ? null : _set,
        ),
      ),
    );
  }
}
