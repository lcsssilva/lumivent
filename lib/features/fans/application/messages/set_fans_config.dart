import '../../../../core/engine/engine_command.dart';
import '../../domain/fans_config.dart';

/// New fan configuration (the engine uses it on the next cycle).
class SetFansConfig extends EngineCommand {
  const SetFansConfig(this.config);
  final FansConfig config;
}
