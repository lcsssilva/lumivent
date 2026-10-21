import 'package:flutter/material.dart';

import '../../core/ui/widgets.dart';

/// Project license and the licenses of everything bundled with the app.
class AboutCard extends StatelessWidget {
  const AboutCard({super.key});

  static const legalese =
      'Licença MIT · © 2026 Lucas Silva (lcsssilva)\n'
      'Projeto independente, sem afiliação com os fabricantes do hardware.';

  @override
  Widget build(BuildContext context) => WeCard(
    title: 'Sobre',
    child: SettingRow(
      title: 'Lumivent',
      subtitle: const Text(legalese),
      control: OutlinedButton(
        key: const Key('open-licenses'),
        onPressed: () => showLicensePage(
          context: context,
          applicationName: 'Lumivent',
          applicationLegalese: legalese,
        ),
        child: const Text('Licenças…'),
      ),
    ),
  );
}
