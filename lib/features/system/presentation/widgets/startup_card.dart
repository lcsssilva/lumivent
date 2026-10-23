import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/i18n/app_strings_scope.dart';
import '../../../../core/ui/async_action.dart';
import '../../../../core/ui/we_colors.dart';
import '../../../../core/ui/we_card.dart';
import '../../../../core/ui/setting_row.dart';
import '../../application/autostart_notifier.dart';
import '../../domain/autostart_exception.dart';

part 'startup_card_state.dart';

class StartupCard extends ConsumerStatefulWidget {
  const StartupCard({super.key});

  @override
  ConsumerState<StartupCard> createState() => _StartupCardState();
}
