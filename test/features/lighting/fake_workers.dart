part of 'shared_effect_worker_test.dart';

/// Worker connections with no worker behind them: every request is answered
/// `ok` and every message is recorded per connection.
class _FakeWorkers {
  final connections = <EffectWorkerConnection>[];
  final received = <List<String>>[];
  final _ports = <ReceivePort>[];

  Future<EffectWorkerConnection> spawn() async {
    final port = ReceivePort();
    _ports.add(port);
    final connection = EffectWorkerConnection.withPort(port.sendPort);
    final ops = <String>[];
    port.listen((message) {
      final request = EffectWorkerRequest.tryParse(message);
      if (request == null) return;
      ops.add(request.op);
      if (request.id != 0) connection.handleMessage(request.ok());
    });
    connections.add(connection);
    received.add(ops);
    return connection;
  }

  void close() {
    for (final connection in connections) {
      connection.close();
    }
    for (final port in _ports) {
      port.close();
    }
  }
}
