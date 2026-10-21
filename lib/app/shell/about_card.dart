import 'package:flutter/material.dart';

import '../../core/i18n/app_strings_scope.dart';
import '../../core/ui/widgets.dart';

/// Project license and the licenses of everything bundled with the app.
class AboutCard extends StatelessWidget {
  const AboutCard({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.strings.shell;
    return WeCard(
      title: s.about,
      child: SettingRow(
        title: 'Lumivent',
        subtitle: Text(s.legalese),
        control: OutlinedButton(
          key: const Key('open-licenses'),
          onPressed: () => showLicensePage(
            context: context,
            applicationName: 'Lumivent',
            applicationLegalese: s.legalese,
          ),
          child: Text(s.licenses),
        ),
      ),
    );
  }
}
