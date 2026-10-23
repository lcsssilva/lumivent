// Converts the `<meta property>` declarations of an HTML effect into the
// control declarations the lighting panel draws (pure Dart).

import 'effect_property.dart';
import 'effect_param.dart';

extension EffectPropertyParam on EffectProperty {
  /// The control declaration for this property, or null when the type has no
  /// generated control (`textfield` and `sensor` are drawn separately).
  EffectParam? toParam() {
    final title = label ?? name;
    switch (type) {
      case 'number':
        final minimum = (min ?? 0).toDouble();
        final requestedMaximum = (max ?? 100).toDouble();
        final maximum = requestedMaximum <= minimum
            ? minimum + 1
            : requestedMaximum;
        final initial = initialValue;
        final start = initial is num ? initial.toDouble() : minimum;
        return EffectParam.number(
          name,
          title,
          min: minimum,
          max: maximum,
          defaultValue: start.clamp(minimum, maximum),
        );
      case 'hue':
        final initial = initialValue;
        return EffectParam.hue(
          name,
          title,
          defaultValue: initial is num ? initial.toDouble() : 0.0,
        );
      case 'color':
        final resolved = resolve(null);
        return EffectParam.color(
          name,
          title,
          defaultValue: resolved is String ? resolved : '#FFFFFF',
        );
      case 'boolean':
        return EffectParam.boolean(
          name,
          title,
          defaultValue: resolve(null) == true,
        );
      case 'combobox':
        final options = values;
        final resolved = resolve(null);
        return EffectParam.combobox(
          name,
          title,
          options: options,
          defaultValue: resolved is String && options.contains(resolved)
              ? resolved
              : (options.isEmpty ? '' : options.first),
        );
      default:
        return null;
    }
  }
}
