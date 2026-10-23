import 'fans_config.dart';

/// Persistence for fan configuration.
abstract interface class FansRepository {
  FansConfig load();
  Future<void> save(FansConfig config);
}
