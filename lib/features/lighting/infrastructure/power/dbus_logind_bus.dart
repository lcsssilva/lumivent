import 'dart:async';

import 'package:dbus/dbus.dart';

import 'inhibitor_lock.dart';
import 'logind_bus.dart';
import 'fd_lock.dart';

/// Real [LogindBus]: system bus, `org.freedesktop.login1.Manager`.
class DBusLogindBus implements LogindBus {
  DBusLogindBus() : _client = DBusClient.system() {
    _object = DBusRemoteObject(
      _client,
      name: 'org.freedesktop.login1',
      path: DBusObjectPath('/org/freedesktop/login1'),
    );
  }

  static const _iface = 'org.freedesktop.login1.Manager';
  final DBusClient _client;
  late final DBusRemoteObject _object;

  Stream<bool> _signal(String name) => DBusRemoteObjectSignalStream(
    object: _object,
    interface: _iface,
    name: name,
    signature: DBusSignature('b'),
  ).map((s) => s.values[0].asBoolean());

  @override
  Stream<bool> get prepareForSleep => _signal('PrepareForSleep');

  @override
  Stream<bool> get prepareForShutdown => _signal('PrepareForShutdown');

  @override
  Future<InhibitorLock> inhibit() async {
    final r = await _object.callMethod(_iface, 'Inhibit', [
      DBusString('sleep:shutdown'),
      DBusString('Lumivent'),
      DBusString('Apagar os ARGB'),
      DBusString('delay'),
    ], replySignature: DBusSignature('h'));
    return FdLock(r.values[0].asUnixFd());
  }

  @override
  Future<void> close() => _client.close();
}
