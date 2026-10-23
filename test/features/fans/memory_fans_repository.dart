import 'package:lumivent/features/fans/fans.dart';

/// Keeps the configuration in memory and counts the saves.
class MemoryFansRepository implements FansRepository {
  FansConfig config = FansConfig.defaults();
  int saves = 0;

  @override
  FansConfig load() => config;

  @override
  Future<void> save(FansConfig c) async {
    config = c;
    saves++;
  }
}
