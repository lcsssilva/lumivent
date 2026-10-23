import 'package:flutter_test/flutter_test.dart';
import 'package:lumivent/features/lighting/infrastructure/html_effects/quickjs_interrupt.dart';

void main() {
  group('virtualMemoryBytes', () {
    test('reads VmSize in kB, independent of the page size', () {
      const status = '''
Name:	lumivent
VmPeak:	 9000000 kB
VmSize:	 8388608 kB
VmRSS:	  204800 kB
''';
      expect(virtualMemoryBytes(status), 8388608 * 1024);
    });

    test('rejects a status without a readable VmSize', () {
      expect(
        () => virtualMemoryBytes('Name:\tlumivent\nVmRSS:\t1 kB\n'),
        throwsFormatException,
      );
      expect(
        () => virtualMemoryBytes('VmSize:\tlots kB\n'),
        throwsFormatException,
      );
    });
  });
}
