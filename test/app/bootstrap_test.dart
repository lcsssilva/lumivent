// bootstrap() itself needs the window and tray plugins; these tests cover the
// platform-free cleanup it runs when startup fails after the engine spawned.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumivent/app/bootstrap.dart';

import '../fakes.dart';

class _RecordingEngine extends FakeEngine {
  _RecordingEngine(this.order);
  final List<String> order;

  @override
  Future<void> shutdown() async => order.add('engine');
}

void main() {
  test(
    'a startup failure releases desktop, providers, then the engine',
    () async {
      final order = <String>[];
      final probe = Provider<int>((ref) {
        ref.onDispose(() => order.add('providers'));
        return 0;
      });
      final container = ProviderContainer()..read(probe);

      await releaseAfterStartupFailure(
        engine: _RecordingEngine(order),
        container: container,
        releaseDesktop: () async => order.add('desktop'),
      );

      expect(order, ['desktop', 'providers', 'engine']);
    },
  );

  test('the engine is shut down even when an earlier step fails', () async {
    final order = <String>[];

    await releaseAfterStartupFailure(
      engine: _RecordingEngine(order),
      releaseDesktop: () async => throw StateError('window channel gone'),
    );

    expect(order, ['engine']);
  });
}
