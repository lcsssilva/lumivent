import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/app_strings_scope.dart';
import '../../../core/persistence/config_store.dart';
import '../../../core/persistence/config_write_failure.dart';
import '../../../core/ui/async_action.dart';
import '../../../core/ui/we_card.dart';
import '../../../core/ui/setting_row.dart';
import '../../config_transfer.dart';

part 'config_transfer_card_state.dart';

/// Export/import of the whole configuration. An import applies at once: the
/// modules reload their section and resend it to the engine.
class ConfigTransferCard extends ConsumerStatefulWidget {
  const ConfigTransferCard({super.key});

  @override
  ConsumerState<ConfigTransferCard> createState() => _ConfigTransferCardState();
}
