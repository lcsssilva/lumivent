import 'package:flutter/widgets.dart';

/// One-shot asynchronous work started by a widget (a button or a switch).
///
/// Use this for actions whose only state is "running": it ignores a second
/// invocation while the first is pending, disables the caller through
/// [isRunning], and always clears the flag, even when the body throws. Durable
/// loading/error state belongs to an `AsyncNotifier`, not to this mixin.
mixin AsyncActionMixin<T extends StatefulWidget> on State<T> {
  bool _running = false;

  /// Whether [run] is executing; widgets use it to disable their control.
  bool get isRunning => _running;

  Future<void> run(Future<void> Function() body) async {
    if (!mounted || _running) return;
    setState(() => _running = true);
    try {
      await body();
    } finally {
      if (mounted) {
        setState(() => _running = false);
      } else {
        _running = false;
      }
    }
  }
}
