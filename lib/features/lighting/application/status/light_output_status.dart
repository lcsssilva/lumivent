import 'package:flutter/foundation.dart' show listEquals;

import 'light_output_state.dart';

class LightOutputStatus {
  const LightOutputStatus(this.state, {this.issue, this.args = const []});
  final LightOutputState state;

  /// Reason shown in the UI when [state] is not [LightOutputState.ok].
  final LightOutputIssue? issue;

  /// Optional technical detail for [issue] (not translated).
  final List<String> args;

  @override
  bool operator ==(Object other) =>
      other is LightOutputStatus &&
      other.state == state &&
      other.issue == issue &&
      listEquals(other.args, args);

  @override
  int get hashCode => Object.hash(state, issue, Object.hashAll(args));
}
