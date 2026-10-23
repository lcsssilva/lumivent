// Explore: installed HTML/Canvas effects (plan §5.6). Grid with thumbnails,
// search and filters, local import (HTML, folder, ZIP) and the read-only import
// from an effects cache on a mounted Windows partition.

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/i18n/app_strings_scope.dart';
import '../../../../core/i18n/catalogs/explore_strings.dart';
import '../../../../core/ui/async_action.dart';
import '../../../../core/ui/we_colors.dart';
import '../../../../core/ui/we_sizes.dart';
import '../../../../core/ui/we_card.dart';
import '../../../lighting/lighting.dart';
import '../explore_labels.dart';
import '../view_models/explore_ui_state.dart';
import '../view_models/explore_view_model.dart';
import '../widgets/effect_card.dart';
import '../widgets/explore_empty_state.dart';
import '../widgets/explore_filters.dart';

part 'explore_view_state.dart';

class ExploreView extends ConsumerStatefulWidget {
  const ExploreView({super.key});

  @override
  ConsumerState<ExploreView> createState() => _ExploreViewState();
}
