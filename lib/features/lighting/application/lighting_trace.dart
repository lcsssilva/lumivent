// Optional timing trace on stderr (LUMIVENT_LIGHTING_TRACE=1), for tuning the
// latency compensation and effect timing on real hardware.

import 'dart:io';

/// Whether the trace is enabled (read once, on startup).
final bool lightingTrace =
    Platform.environment['LUMIVENT_LIGHTING_TRACE'] == '1';

/// Writes one trace line with the standard `lighting:` prefix.
void traceLighting(String message) {
  if (lightingTrace) stderr.writeln('lighting: $message');
}
