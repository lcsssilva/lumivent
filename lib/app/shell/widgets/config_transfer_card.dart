import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../core/i18n/app_strings.dart';
import '../../../core/i18n/app_strings_scope.dart';
import '../../config_transfer.dart' show exportFileName;
import '../../../core/persistence/config_write_failure.dart';
import '../../../core/ui/async_action.dart';
import '../../../core/ui/we_card.dart';
import '../../../core/ui/setting_row.dart';

part 'config_transfer_card_state.dart';

/// Export/import of the whole configuration. An import applies at once: the
/// modules reload their section and resend it to the engine.
class ConfigTransferCard extends StatefulWidget {
  const ConfigTransferCard({
    super.key,
    required this.exportConfiguration,
    required this.importConfiguration,
  });

  /// The configuration as JSON, ready to save.
  final String Function() exportConfiguration;

  /// Imports a picked file and returns the path of the backup taken first.
  final Future<String> Function(
    Stream<List<int>> file, {
    required AppStrings strings,
  })
  importConfiguration;

  @override
  State<ConfigTransferCard> createState() => _ConfigTransferCardState();
}
