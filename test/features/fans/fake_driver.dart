import 'package:flutter_test/flutter_test.dart';
import 'package:lumivent/features/fans/fans.dart';

class FakeDriver implements FanDriver {
  final duties = <(int, int)>[];
  int syncOffCalls = 0;
  bool ok = true;

  /// Time the (fake) hub worker takes to answer.
  Duration latency = Duration.zero;

  @override
  Future<bool> setDuty(int group, int duty) async {
    duties.add((group, duty));
    await Future<void>.delayed(latency);
    return ok;
  }

  @override
  Future<bool> disableMotherboardSync() async {
    syncOffCalls++;
    await Future<void>.delayed(latency);
    return ok;
  }

  /// Last duty sent to [group].
  int lastDuty(int group) => duties.lastWhere((e) => e.$1 == group).$2;
}
