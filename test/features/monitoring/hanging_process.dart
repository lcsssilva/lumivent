part of 'nvme_test.dart';

class _HangingProcess implements Process {
  final _stdout = StreamController<List<int>>();
  final _stderr = StreamController<List<int>>();
  final _exit = Completer<int>();
  ProcessSignal? killedWith;

  @override
  bool kill([ProcessSignal signal = ProcessSignal.sigterm]) {
    killedWith = signal;
    _stdout.close();
    _stderr.close();
    _exit.complete(-9);
    return true;
  }

  @override
  Future<int> get exitCode => _exit.future;
  @override
  int get pid => 4242;
  @override
  Stream<List<int>> get stdout => _stdout.stream;
  @override
  Stream<List<int>> get stderr => _stderr.stream;
  @override
  IOSink get stdin => throw UnimplementedError();
}
