part of 'async_action_test.dart';

class _ProbeState extends State<_Probe> with AsyncActionMixin<_Probe> {
  int calls = 0;

  Future<void> start() {
    calls++;
    return run(widget.body);
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    home: Scaffold(
      body: TextButton(
        key: const Key('start'),
        onPressed: isRunning ? null : start,
        child: const Text('start'),
      ),
    ),
  );
}
