import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumivent/app/licenses.dart';
import 'package:lumivent/app/shell/widgets/about_card.dart';

import '../support/app_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('bundled license assets exist and are registered', () async {
    registerBundledLicenses();
    final entries = await LicenseRegistry.licenses.toList();
    String textOf(String package) => entries
        .firstWhere((e) => e.packages.contains(package))
        .paragraphs
        .map((p) => p.text)
        .join('\n');

    expect(textOf('Inter (fonte)'), contains('SIL Open Font License'));
    expect(textOf('QuickJS'), contains('Fabrice Bellard'));
  });

  testWidgets('about card opens the licenses page', (tester) async {
    await tester.pumpWidget(
      withPortuguese(const MaterialApp(home: Scaffold(body: AboutCard()))),
    );
    expect(find.textContaining('Licença MIT'), findsOneWidget);

    await tester.tap(find.byKey(const Key('open-licenses')));
    // The page keeps a progress indicator spinning while it reads the
    // licenses, so it never settles: pump past the route transition instead.
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(LicensePage), findsOneWidget);
  });
}
