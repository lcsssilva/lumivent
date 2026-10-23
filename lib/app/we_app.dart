import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/i18n/app_strings.dart';
import '../core/i18n/app_strings_scope.dart';
import '../core/i18n/strings_provider.dart';
import '../core/ui/theme.dart';
import 'shell/views/shell_view.dart';

class WeApp extends ConsumerWidget {
  const WeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(stringsProvider);
    return AppStringsScope(
      strings: strings,
      child: MaterialApp(
        title: 'Lumivent',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        locale: strings.locale,
        supportedLocales: AppStrings.supportedLocales,
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: const ShellView(),
      ),
    );
  }
}
