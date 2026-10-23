import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumivent/core/engine/isolate_engine.dart';
import 'package:lumivent/core/ui/theme.dart';
import 'package:lumivent/features/lighting/application/installed_effects_notifier.dart';
import 'package:lumivent/features/lighting/application/lighting_notifier.dart';
import 'package:lumivent/features/lighting/domain/effect_compatibility.dart';
import 'package:lumivent/features/lighting/domain/effect_library.dart';
import 'package:lumivent/features/lighting/domain/effect_property.dart';
import 'package:lumivent/features/lighting/domain/effect_source.dart';
import 'package:lumivent/features/lighting/domain/installed_effect.dart';
import 'package:lumivent/features/lighting/domain/lighting_config.dart';
import 'package:lumivent/features/lighting/domain/lighting_config_repository.dart';
import 'package:lumivent/features/lighting/presentation/widgets/effect_panel.dart';
import 'package:lumivent/features/preferences/application/preferences_notifier.dart';
import 'package:lumivent/features/preferences/domain/preferences.dart';
import 'package:lumivent/features/preferences/domain/preferences_repository.dart';

import '../../fake_engine.dart';

import '../../support/app_harness.dart';

part 'panel_effect_library.dart';
part 'panel_preferences_repository.dart';
part 'panel_lighting_repository.dart';

void main() {
  testWidgets(
    'generated HTML effect controls edit number, hue, boolean, color, '
    'combobox, and text',
    (tester) async {
      tester.view.physicalSize = const Size(700, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final effect = InstalledEffect(
        id: 'test',
        title: 'Teste',
        source: EffectSource(
          title: 'Teste',
          script: 'var a = 1;',
          properties: [
            EffectProperty(
              name: 'speed',
              type: 'number',
              label: 'Velocidade',
              min: 0,
              max: 100,
              defaultValue: '50',
            ),
            EffectProperty(
              name: 'hue',
              type: 'hue',
              label: 'Matiz',
              defaultValue: '120',
            ),
            EffectProperty(
              name: 'enabled',
              type: 'boolean',
              label: 'Ativo',
              defaultValue: '1',
            ),
            EffectProperty(
              name: 'mode',
              type: 'combobox',
              label: 'Modo',
              values: ['A', 'B'],
              defaultValue: 'B',
            ),
            EffectProperty(
              name: 'color',
              type: 'color',
              label: 'Cor',
              defaultValue: '#ff0000',
            ),
            EffectProperty(
              name: 'note',
              type: 'textfield',
              label: 'Texto',
              defaultValue: 'oi',
            ),
          ],
        ),
        compatibility: const EffectCompatibility(EffectSupport.compatible, []),
      );
      final repo = _PanelLightingRepository();
      final container = ProviderContainer(
        overrides: [
          engineProvider.overrideWithValue(FakeEngine()),
          lightingRepositoryProvider.overrideWithValue(repo),
          preferencesRepositoryProvider.overrideWithValue(
            _PanelPreferencesRepository(),
          ),
          effectLibraryProvider.overrideWithValue(_PanelEffectLibrary(effect)),
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: withPortuguese(
            MaterialApp(
              theme: buildTheme(),
              home: const Scaffold(
                body: SingleChildScrollView(child: EffectPanel()),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      for (final key in ['speed', 'hue', 'enabled', 'mode', 'color', 'note']) {
        expect(find.byKey(ValueKey('param-$key')), findsOneWidget);
      }

      Map<String, Object?> values() =>
          container.read(lightingProvider).effectValues['html:test']!;

      // Hue slider (0–360) starts at 120 and moves right.
      final hue = find.descendant(
        of: find.byKey(const ValueKey('param-hue')),
        matching: find.byType(Slider),
      );
      await tester.drag(hue, const Offset(80, 0));
      await tester.pump();
      expect((values()['hue'] as num).toDouble(), greaterThan(120));

      // Number slider moves left from 50.
      final speed = find.descendant(
        of: find.byKey(const ValueKey('param-speed')),
        matching: find.byType(Slider),
      );
      await tester.drag(speed, const Offset(-80, 0));
      await tester.pump();
      expect((values()['speed'] as num).toInt(), lessThan(50));

      // Boolean switch.
      await tester.tap(find.byType(Switch));
      await tester.pump();
      expect(values()['enabled'], false);

      // Combobox.
      await tester.tap(
        find.descendant(
          of: find.byKey(const ValueKey('param-mode')),
          matching: find.byType(DropdownButton<String>),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('A').last);
      await tester.pumpAndSettle();
      expect(values()['mode'], 'A');

      // Text field.
      await tester.enterText(
        find.descendant(
          of: find.byKey(const ValueKey('param-note')),
          matching: find.byType(TextFormField),
        ),
        'novo',
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(values()['note'], 'novo');

      await tester.pump(const Duration(seconds: 1));
    },
  );
}
