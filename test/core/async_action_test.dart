import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumivent/core/ui/async_action.dart';

class _Probe extends StatefulWidget {
  const _Probe({super.key, required this.body});

  final Future<void> Function() body;

  @override
  State<_Probe> createState() => _ProbeState();
}

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

void main() {
  testWidgets('disables the control and ignores a second run', (tester) async {
    final completer = Completer<void>();
    final key = GlobalKey<_ProbeState>();
    await tester.pumpWidget(_Probe(key: key, body: () => completer.future));

    await tester.tap(find.byKey(const Key('start')));
    await tester.pump();
    expect(key.currentState!.isRunning, isTrue);
    expect(key.currentState!.calls, 1);
    expect(
      tester.widget<TextButton>(find.byKey(const Key('start'))).onPressed,
      isNull,
    );

    await key.currentState!.run(() async => key.currentState!.calls++);
    expect(key.currentState!.calls, 1);

    completer.complete();
    await tester.pump();
    expect(key.currentState!.isRunning, isFalse);
    expect(
      tester.widget<TextButton>(find.byKey(const Key('start'))).onPressed,
      isNotNull,
    );
  });

  testWidgets('clears the running state when the action fails', (tester) async {
    final key = GlobalKey<_ProbeState>();
    await tester.pumpWidget(_Probe(key: key, body: () async {}));

    await expectLater(
      key.currentState!.run(() async => throw StateError('boom')),
      throwsStateError,
    );
    expect(key.currentState!.isRunning, isFalse);
  });
}
