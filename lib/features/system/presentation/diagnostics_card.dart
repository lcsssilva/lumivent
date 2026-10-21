import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ui/theme.dart';
import '../../../core/ui/widgets.dart';
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
    return WeCard(
      title: 'Permissões e sistema',
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
                  SizedBox(width: 220, child: Text(c.label)),
                  Expanded(
                    child: Text(
                      c.detail,
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
