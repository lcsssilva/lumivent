import 'metrics.dart';

class MetricDef {
  const MetricDef(this.id, this.label, this.unit);
  final String id;
  final String label;
  final MetricUnit unit;
}
