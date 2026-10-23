import 'package:flutter_test/flutter_test.dart';
import 'package:lumivent/core/i18n/app_strings.dart';
import 'package:lumivent/features/explore/presentation/explore_labels.dart';
import 'package:lumivent/features/lighting/application/light_output_state.dart';
import 'package:lumivent/features/lighting/domain/effect_compatibility.dart';
import 'package:lumivent/features/lighting/domain/effect_library.dart';
import 'package:lumivent/features/lighting/domain/import_issue.dart';
import 'package:lumivent/features/lighting/domain/lighting_config.dart';
import 'package:lumivent/features/lighting/presentation/lighting_labels.dart';

/// Every enum value must have its own non-empty text in both catalogs.
void expectDistinctLabels<T>(
  List<T> values,
  String Function(AppStrings strings, T value) label,
) {
  for (final strings in [AppStrings.en, AppStrings.pt]) {
    final texts = [for (final value in values) label(strings, value)];
    expect(texts, everyElement(isNotEmpty));
    expect(texts.toSet(), hasLength(values.length));
  }
}

void main() {
  test('board modes', () {
    expectDistinctLabels(BoardEffectMode.values, boardModeLabel);
  });

  test('GPU effects', () {
    expectDistinctLabels(GpuEffect.values, gpuEffectLabel);
  });

  test('effect compatibility issues', () {
    expectDistinctLabels(EffectIssue.values, effectIssueLabel);
  });

  test('output issues', () {
    expectDistinctLabels(
      LightOutputIssue.values,
      (strings, issue) => outputIssueLabel(strings, issue, const ['detail']),
    );
  });

  test('import issues', () {
    expectDistinctLabels(
      ImportIssueKind.values,
      (strings, kind) => formatImportIssue(
        strings.explore,
        ImportIssue(kind, path: 'effect.zip', detail: 'bad'),
      ),
    );
  });
}
