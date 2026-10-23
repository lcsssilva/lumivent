/// A reading of all sensors. Missing metric = no reading now.
class SensorSample {
  const SensorSample(this.at, this.values);
  final DateTime at;
  final Map<String, double> values;

  double? operator [](String id) => values[id];
}
