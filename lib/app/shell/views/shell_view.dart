import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/app_strings_scope.dart';
import '../../../core/persistence/config_store.dart';
import '../../../features/explore/explore.dart';
import '../../../features/fans/fans.dart';
import '../../../features/lighting/lighting.dart';
import '../../../features/monitoring/monitoring.dart';
import '../../navigation/app_route.dart';
import '../view_models/shell_view_model.dart';
import 'settings_view.dart';
import '../widgets/sidebar.dart';
import '../widgets/top_bar.dart';

part 'shell_view_state.dart';

class ShellView extends ConsumerStatefulWidget {
  const ShellView({super.key});

  @override
  ConsumerState<ShellView> createState() => _ShellViewState();
}
