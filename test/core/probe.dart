part of 'async_action_test.dart';

class _Probe extends StatefulWidget {
  const _Probe({super.key, required this.body});

  final Future<void> Function() body;

  @override
  State<_Probe> createState() => _ProbeState();
}
