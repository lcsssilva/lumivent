import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumivent/core/i18n/app_strings.dart';
import 'package:lumivent/core/i18n/app_strings_scope.dart';
import 'package:lumivent/core/i18n/ui_language.dart';
import 'package:lumivent/features/lighting/domain/native_effects.dart';
import 'package:lumivent/features/preferences/domain/preferences.dart';

void main() {
  group('language', () {
    test('English is the default for new and invalid configurations', () {
      expect(const Preferences().language, AppLanguage.en);
      expect(Preferences.fromJson(const {}).language, AppLanguage.en);
      expect(
        Preferences.fromJson(const {'language': 'fr'}).language,
        AppLanguage.en,
      );
      expect(
        Preferences.fromJson(const {'language': 1}).language,
        AppLanguage.en,
      );
      expect(
        Preferences.fromJson(const {'language': 'pt'}).language,
        AppLanguage.pt,
      );
    });

    test('the preference round-trips through JSON', () {
      const prefs = Preferences(language: AppLanguage.pt);
      expect(Preferences.fromJson(prefs.toJson()), prefs);
      expect(prefs.toJson()['language'], 'pt');
    });

    test('catalogs expose the matching locale and separators', () {
      expect(AppStrings.en.language, UiLanguage.en);
      expect(AppStrings.en.localeName, 'en_US');
      expect(AppStrings.en.locale, const Locale('en', 'US'));
      expect(AppStrings.en.decimalSeparator, '.');
      expect(AppStrings.en.groupingSeparator, ',');

      expect(AppStrings.pt.language, UiLanguage.pt);
      expect(AppStrings.pt.localeName, 'pt_BR');
      expect(AppStrings.pt.locale, const Locale('pt', 'BR'));
      expect(AppStrings.pt.decimalSeparator, ',');
      expect(AppStrings.pt.groupingSeparator, '.');

      expect(AppStrings.of(UiLanguage.en), same(AppStrings.en));
      expect(AppStrings.of(UiLanguage.pt), same(AppStrings.pt));
      expect(AppStrings.supportedLocales, [
        const Locale('en', 'US'),
        const Locale('pt', 'BR'),
      ]);
    });
  });

  group('numbers', () {
    test('decimal separators follow the language', () {
      expect(AppStrings.en.decimal(1234.5, 1), '1234.5');
      expect(AppStrings.pt.decimal(1234.5, 1), '1234,5');
      expect(AppStrings.en.decimal(0.5, 2), '0.50');
      expect(AppStrings.pt.decimal(0.5, 2), '0,50');
    });

    test('grouped integers follow the language', () {
      expect(AppStrings.en.grouped(999), '999');
      expect(AppStrings.en.grouped(1234567), '1,234,567');
      expect(AppStrings.en.grouped(-1000), '-1,000');
      expect(AppStrings.pt.grouped(999), '999');
      expect(AppStrings.pt.grouped(1234567), '1.234.567');
      expect(AppStrings.pt.grouped(-1000), '-1.000');
    });
  });

  group('native effects', () {
    test('every effect and parameter has a label in both catalogs', () {
      for (final effect in nativeEffects) {
        final en = AppStrings.en.lighting.effectLabel(effect.id, effect.name);
        final pt = AppStrings.pt.lighting.effectLabel(effect.id, effect.name);
        expect(en, isNotEmpty, reason: 'en ${effect.id}');
        expect(pt, isNotEmpty, reason: 'pt ${effect.id}');
        expect(pt, isNot(en), reason: 'pt ${effect.id} must be translated');

        for (final param in effect.params) {
          final enParam = AppStrings.en.lighting.paramLabel(
            param.id,
            param.label,
          );
          final ptParam = AppStrings.pt.lighting.paramLabel(
            param.id,
            param.label,
          );
          expect(enParam, isNotEmpty, reason: 'en ${effect.id}/${param.id}');
          expect(ptParam, isNotEmpty, reason: 'pt ${effect.id}/${param.id}');
          expect(
            ptParam,
            isNot(enParam),
            reason: 'pt ${effect.id}/${param.id} must be translated',
          );
        }
      }
    });

    test('unknown effects and parameters keep the fallback', () {
      expect(
        AppStrings.en.lighting.effectLabel('unknown', 'Fallback'),
        'Fallback',
      );
      expect(
        AppStrings.pt.lighting.effectLabel('unknown', 'Fallback'),
        'Fallback',
      );
      expect(
        AppStrings.en.lighting.paramLabel('unknown', 'Fallback'),
        'Fallback',
      );
      expect(
        AppStrings.pt.lighting.paramLabel('unknown', 'Fallback'),
        'Fallback',
      );
    });

    test('direction options are localized and legacy values are accepted', () {
      expect(AppStrings.en.lighting.optionLabel('Left'), 'Left');
      expect(AppStrings.en.lighting.optionLabel('Right'), 'Right');
      expect(AppStrings.en.lighting.optionLabel('Up'), 'Up');
      expect(AppStrings.en.lighting.optionLabel('Down'), 'Down');
      expect(AppStrings.en.lighting.optionLabel('custom'), 'custom');

      expect(AppStrings.pt.lighting.optionLabel('Left'), 'Esquerda');
      expect(AppStrings.pt.lighting.optionLabel('Right'), 'Direita');
      expect(AppStrings.pt.lighting.optionLabel('Up'), 'Cima');
      expect(AppStrings.pt.lighting.optionLabel('Down'), 'Baixo');
      expect(AppStrings.pt.lighting.optionLabel('custom'), 'custom');

      final direction = nativeEffects
          .expand((e) => e.params)
          .firstWhere((p) => p.id == 'direction');
      expect(direction.resolve('Esquerda'), 'Left');
      expect(direction.resolve('Direita'), 'Right');
      expect(direction.resolve('Cima'), 'Up');
      expect(direction.resolve('Baixo'), 'Down');
    });
  });

  group('explore import report', () {
    test('summary uses the singular and plural of each language', () {
      final en = AppStrings.en.explore;
      expect(
        en.importSummary(
          imported: 0,
          replaced: 0,
          skipped: 0,
          paidSkipped: 0,
          errors: 0,
        ),
        'Nothing to import.',
      );
      expect(
        en.importSummary(
          imported: 1,
          replaced: 1,
          skipped: 1,
          paidSkipped: 1,
          errors: 1,
        ),
        '1 imported, 1 replaced, 1 skipped, 1 paid not imported, 1 error',
      );
      expect(
        en.importSummary(
          imported: 2,
          replaced: 0,
          skipped: 2,
          paidSkipped: 2,
          errors: 2,
        ),
        '2 imported, 2 skipped, 2 paid not imported, 2 errors',
      );

      final pt = AppStrings.pt.explore;
      expect(
        pt.importSummary(
          imported: 0,
          replaced: 0,
          skipped: 0,
          paidSkipped: 0,
          errors: 0,
        ),
        'Nada para importar.',
      );
      expect(
        pt.importSummary(
          imported: 1,
          replaced: 1,
          skipped: 1,
          paidSkipped: 1,
          errors: 1,
        ),
        '1 importado, 1 substituído, 1 ignorado, 1 pago não importado, 1 erro',
      );
      expect(
        pt.importSummary(
          imported: 2,
          replaced: 0,
          skipped: 2,
          paidSkipped: 2,
          errors: 2,
        ),
        '2 importados, 2 ignorados, 2 pagos não importados, 2 erros',
      );
    });

    test('every import issue kind is formatted in both catalogs', () {
      const kinds = [
        'notHtmlOrZip',
        'notFound',
        'folderNotFound',
        'chooseWindowsCache',
        'catalogMissing',
        'noEffectHtml',
        'invalidZip',
        'noHtmlInZip',
      ];
      for (final kind in kinds) {
        expect(
          AppStrings.en.explore.importIssue(kind, 'effect.zip', error: 'bad'),
          isNotEmpty,
          reason: 'en $kind',
        );
        expect(
          AppStrings.pt.explore.importIssue(kind, 'effect.zip', error: 'bad'),
          isNotEmpty,
          reason: 'pt $kind',
        );
      }

      expect(
        AppStrings.en.explore.importIssue(
          'invalidZip',
          'effect.zip',
          error: 'truncated',
        ),
        'effect.zip: invalid ZIP. Technical details: truncated',
      );
      expect(
        AppStrings.pt.explore.importIssue(
          'invalidZip',
          'effect.zip',
          error: 'truncated',
        ),
        'effect.zip: ZIP inválido. Detalhes técnicos: truncated',
      );
      expect(
        AppStrings.en.explore.importIssue('unknown', 'effect.zip', error: 'x'),
        'effect.zip. Technical details: x',
      );
      expect(
        AppStrings.pt.explore.importIssue('unknown', 'effect.zip', error: 'x'),
        'effect.zip. Detalhes técnicos: x',
      );
    });

    test('runtime errors label technical details in both languages', () {
      expect(
        AppStrings.en.lighting.effectLoadFailed('Bad state'),
        contains('Technical details: Bad state'),
      );
      expect(
        AppStrings.pt.lighting.effectLoadFailed('Bad state'),
        contains('Detalhes técnicos: Bad state'),
      );
      expect(
        AppStrings.en.system.autostartFailed('systemctl', 'failed'),
        contains('Technical details: systemctl: failed'),
      );
      expect(
        AppStrings.pt.system.autostartFailed('systemctl', 'failed'),
        contains('Detalhes técnicos: systemctl: failed'),
      );
    });
  });

  group('AppStringsScope', () {
    testWidgets('provides the wrapped catalog', (tester) async {
      late AppStrings seen;
      await tester.pumpWidget(
        AppStringsScope(
          strings: AppStrings.en,
          child: Builder(
            builder: (context) {
              seen = context.strings;
              return const SizedBox();
            },
          ),
        ),
      );
      expect(seen, same(AppStrings.en));
    });

    testWidgets('standalone widgets fall back to English', (tester) async {
      late AppStrings seen;
      await tester.pumpWidget(
        Builder(
          builder: (context) {
            seen = context.strings;
            return const SizedBox();
          },
        ),
      );
      expect(seen, same(AppStrings.en));
    });
  });
}
