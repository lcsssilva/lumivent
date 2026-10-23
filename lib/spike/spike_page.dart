part of '../main_spike.dart';

class SpikePage extends StatefulWidget {
  const SpikePage({
    super.key,
    required this.files,
    required this.auto,
    this.only,
    this.dump,
  });
  final List<File> files;
  final bool auto;
  final String? only, dump;

  @override
  State<SpikePage> createState() => _SpikePageState();
}
