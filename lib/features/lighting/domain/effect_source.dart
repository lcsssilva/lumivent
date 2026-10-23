import 'effect_property.dart';

class EffectSource {
  EffectSource({
    required this.title,
    required this.properties,
    required this.script,
    this.description,
    this.publisher,
  });

  final String title;
  final String? description, publisher;
  final List<EffectProperty> properties;

  /// All inline `<script>` blocks, in document order.
  final String script;
}
