import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:lumivent/features/monitoring/monitoring.dart';

import 'smart_fixture.dart';

class FakeSsds implements SsdReader {
  int reads = 0;

  /// The helper "appears" from this read on.
  int smartFrom = 1;

  @override
  Future<List<SsdInfo>> read() async {
    reads++;
    return [
      SsdInfo(
        controller: 'nvme0',
        model: 'M',
        serial: 'S',
        firmware: 'F',
        smart: reads >= smartFrom ? smartLog() : null,
        smartError: reads >= smartFrom
            ? null
            : const SsdSmartError(SsdErrorKind.helperMissing),
      ),
    ];
  }
}
