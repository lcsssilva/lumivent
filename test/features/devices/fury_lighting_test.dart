import 'package:flutter_test/flutter_test.dart';
import 'package:lumivent/core/platform/smbus_ffi.dart';
import 'package:lumivent/features/devices/infrastructure/drivers/kingston_fury/controller.dart';
import 'package:lumivent/features/devices/infrastructure/drivers/kingston_fury/protocol.dart';

class FakeBus implements FuryBus {
  FakeBus({this.dd = 0x00, this.id = const [0x46, 0x55, 0x52, 0x59]});
  int dd;
  List<int> id;
  bool failNext = false;
  bool failAlways = false;
  bool failOnReadWord = false;
  bool closed = false;
  final ops = <String>[];

  void _maybeFail() {
    if (failAlways) throw SmbusException('falha', 5);
    if (failNext) {
      failNext = false;
      throw SmbusException('falha', 5);
    }
  }

  @override
  int readByte(int a, int r) {
    ops.add('R $a ${r.toRadixString(16)}');
    _maybeFail();
    return r == furyGuardRegister ? dd : 0;
  }

  @override
  int readWord(int a, int r) {
    ops.add('RW $a ${r.toRadixString(16)}');
    _maybeFail();
    if (failOnReadWord) throw SmbusException('read failed', 5);
    return (id[r - 1] << 8) | 0x34;
  }

  @override
  void writeByte(int a, int r, int v) {
    ops.add('W $a ${r.toRadixString(16)}=${v.toRadixString(16)}');
    _maybeFail();
  }

  @override
  void quick(int a) {
    ops.add('Q $a');
    _maybeFail();
  }

  @override
  void close() => closed = true;

  List<String> get writes => ops.where((o) => o.startsWith('W')).toList();
}

void main() {
  final rgb = List<int>.generate(furyColorBytes, (i) => i + 1);
  late FakeBus bus;
  late DateTime now;
  late int opens;
  FuryController make() => FuryController(
    open: () {
      opens++;
      return bus;
    },
    clock: () => now,
    pause: (_) {},
  );
  setUp(() {
    bus = FakeBus();
    now = DateTime(2026);
    opens = 0;
  });

  test('guard rejects 0x50-0x57 and SMBus addresses', () {
    for (var a = 0x50; a <= 0x57; a++) {
      expect(isForbiddenSmbusAddress(a), isTrue);
    }
    expect(isForbiddenSmbusAddress(0x61), isFalse);
    expect(isForbiddenSmbusAddress(0x4F), isFalse);
    expect(isForbiddenSmbusAddress(0x58), isFalse);
  });

  test('LED register mapping covers every LED and channel', () {
    expect(furyLedRegister(0, 0), 0x50);
    expect(furyLedRegister(0, 2), 0x52);
    expect(furyLedRegister(11, 2), 0x73);
  });

  test('slot outside the list -> error, no I/O', () {
    final c = make();
    expect(() => c.setColors(2, rgb), throwsArgumentError);
    expect(() => c.setSingleColor(-1, 0, 0, 0), throwsArgumentError);
    expect(bus.ops, isEmpty);
    expect(opens, 0);
  });

  test('wrong color length is rejected before any I/O', () {
    final c = make();
    expect(() => c.setColors(0, [1, 2, 3]), throwsArgumentError);
    expect(bus.ops, isEmpty);
    expect(opens, 0);
  });

  test('a failing bus open is retried after the interval', () {
    var attempt = 0;
    final c = FuryController(
      open: () {
        attempt++;
        if (attempt == 1) throw SmbusException('busy', 16);
        return bus;
      },
      clock: () => now,
    );
    expect(c.setColors(0, rgb), isFalse);
    expect(attempt, 1);
    expect(c.setColors(0, rgb), isFalse); // within the retry interval
    expect(attempt, 1);
    now = now.add(const Duration(seconds: 6));
    expect(c.setColors(0, rgb), isTrue);
    expect(attempt, 2);
  });

  test('identity read failure still closes the session', () {
    final c = make();
    bus.failOnReadWord = true;
    expect(c.setColors(0, rgb), isFalse);
    expect(bus.ops.last, 'W 97 8=44');
    expect(bus.closed, isTrue);
    bus.failOnReadWord = false;
    bus.ops.clear();
    now = now.add(const Duration(seconds: 6));
    expect(c.setColors(0, rgb), isTrue);
  });

  test('0x72 and 0x78 guard: no writes, disabled permanently', () {
    for (final dd in [0x72, 0x78]) {
      bus = FakeBus(dd: dd);
      final c = make();
      expect(c.setColors(0, rgb), isFalse);
      expect(bus.ops, ['Q 97', 'R 97 dd']);
      expect(bus.writes, isEmpty);
      expect(c.activeSlots, [1]);
      expect(c.disabledReason(0), contains('PWM'));
      bus.ops.clear();
      expect(c.setColors(0, rgb), isFalse);
      expect(c.setSingleColor(0, 0, 0, 0), isFalse);
      expect(bus.ops, isEmpty);
    }
  });

  test('non-FURY: only the identity 0x08 is written', () {
    bus = FakeBus(id: [1, 2, 3, 4]);
    final c = make();
    expect(c.setColors(1, rgb), isFalse);
    expect(bus.writes, ['W 99 8=53', 'W 99 8=44']);
    expect(c.activeSlots, [0]);
    expect(c.disabledReason(1), contains('FURY'));
  });

  test('accepted identity variants', () {
    expect(furyIdMatches([0x06, 0x55, 0x52, 0x59]), isTrue);
    expect(furyIdMatches([0x07, 0xE0, 0xFF, 0xFF]), isTrue);
    expect(furyIdMatches([0x46, 0x55, 0x52, 0x58]), isFalse);
  });

  test('complete sequence: ACK, guard, identity, direct mode, colors', () {
    final c = make();
    expect(c.setColors(0, rgb), isTrue);
    final head = bus.ops.take(12).toList();
    expect(head, [
      'Q 97',
      'R 97 dd',
      'W 97 8=53',
      'RW 97 1',
      'RW 97 2',
      'RW 97 3',
      'RW 97 4',
      'W 97 8=44',
      'W 97 8=53',
      'W 97 b=0',
      'W 97 9=10',
      'W 97 c=1',
    ]);
    expect(bus.ops.skip(12).take(3).toList(), [
      'W 97 20=50',
      'W 97 8=44',
      'W 97 8=53',
    ]);
    expect(bus.writes.length, 2 + 6 + 36 + 2);
    expect(bus.writes[bus.writes.length - 37], 'W 97 50=1');
    expect(bus.writes.last, 'W 97 8=44');
  });

  test('only changed bytes; no changes means no I/O', () {
    final c = make();
    c.setColors(0, rgb);
    bus.ops.clear();
    expect(c.setColors(0, rgb), isTrue);
    expect(bus.ops, isEmpty);
    final next = [...rgb]..[3] = 200;
    c.setColors(0, next);
    expect(bus.ops, ['W 97 8=53', 'W 97 53=c8', 'W 97 8=44']);
  });

  test('single color and return to direct mode reruns the sequence', () {
    final c = make();
    c.setColors(1, rgb);
    bus.ops.clear();
    expect(c.setSingleColor(1, 0, 0, 0), isTrue);
    expect(bus.ops, [
      'W 99 8=53',
      'W 99 9=0',
      'W 99 30=1',
      'W 99 31=0',
      'W 99 32=0',
      'W 99 33=0',
      'W 99 8=44',
    ]);
    bus.ops.clear();
    c.setSingleColor(1, 0, 0, 0);
    expect(bus.ops, isEmpty);
    c.setColors(1, rgb);
    expect(bus.ops.take(6).toList(), [
      'W 99 8=53',
      'W 99 b=0',
      'W 99 9=10',
      'W 99 c=1',
      'W 99 20=50',
      'W 99 8=44',
    ]);
    expect(
      bus.writes.where((w) => w.startsWith('W 99 50=')).length,
      1,
    ); // cache rebuilt: everything rewritten
  });

  test('transient SmbusException: retries, reopens, and succeeds', () {
    final c = make();
    c.setColors(0, rgb);
    expect(opens, 1);
    bus.failNext = true;
    expect(c.setColors(0, [...rgb]..[0] = 99), isTrue);
    expect(opens, 2);
    expect(bus.closed, isTrue); // dropped before the retry
    expect(c.activeSlots, [0, 1]);
  });

  test(
    'persistent SmbusException: attempts, then waits the retry interval',
    () {
      final c = make();
      bus.failAlways = true;
      expect(c.setColors(0, rgb), isFalse);
      expect(opens, 3); // attempts
      bus.closed = false;
      bus.ops.clear();
      expect(c.setColors(0, rgb), isFalse); // within the interval
      expect(opens, 3);
      expect(bus.ops, isEmpty);
      bus.failAlways = false;
      now = now.add(const Duration(seconds: 6));
      expect(c.setColors(0, rgb), isTrue);
      expect(opens, 4);
      expect(bus.ops.take(2).toList(), ['Q 97', 'R 97 dd']);
    },
  );

  test('invalidate: next setColors resends everything; guard stays', () {
    final c = make();
    c.setColors(0, rgb);
    bus.ops.clear();
    c.setColors(0, rgb);
    expect(bus.writes, isEmpty); // cached
    c.invalidate();
    bus.ops.clear();
    expect(c.setColors(0, rgb), isTrue);
    expect(bus.writes, isNotEmpty);
    // single color is also resent
    c.setSingleColor(0, 1, 2, 3);
    c.invalidate();
    bus.ops.clear();
    c.setSingleColor(0, 1, 2, 3);
    expect(bus.writes, isNotEmpty);
  });

  test('invalidate keeps guard-disabled slots disabled', () {
    bus = FakeBus(dd: 0x72);
    final c = make();
    c.setColors(0, rgb);
    c.invalidate();
    expect(c.disabledReason(0), isNotNull);
    expect(c.setColors(0, rgb), isFalse);
  });

  test('close: no I/O and no reopen afterwards, idempotent', () {
    final c = make();
    c.setColors(0, rgb);
    c.close();
    c.close();
    bus.ops.clear();
    final before = opens;
    expect(c.setColors(0, rgb), isFalse);
    expect(c.setSingleColor(1, 0, 0, 0), isFalse);
    expect(bus.ops, isEmpty);
    expect(opens, before);
  });
}
