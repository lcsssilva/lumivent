import 'dart:async';

import 'alv2_hub.dart';
import 'alv2_port_write.dart';
import 'isolate_alv2_hub_link.dart';
import 'alv2_hub_command.dart';
import 'alv2_hub_reply.dart';
import 'alv2_hub_core.dart';
import 'alv2_hub_link.dart';
import 'local_alv2_hub_link.dart';

/// Asynchronous face of the hub for the engine isolate. Same semantics as
/// [Alv2Hub], with every call answered by the worker.
///
/// One instance is created by the engine composition and shared by monitoring
/// (RPM), fans (duty), and lighting (frames). Only the monitoring source
/// releases it, and the engine stops modules in reverse order, so lighting and
/// fans stop before the hub closes. Calls never throw: an unavailable worker
/// answers `false` (or a `null` RPM); driver and spawn errors go to stderr.
class Alv2HubProxy {
  Alv2HubProxy(this._link);

  /// Spawns the worker isolate. Call inside the engine isolate.
  factory Alv2HubProxy.open() => Alv2HubProxy(IsolateAlv2HubLink());

  /// Proxy over a hub in this isolate (tests; no isolate).
  factory Alv2HubProxy.local(Alv2Hub hub) =>
      Alv2HubProxy(LocalAlv2HubLink(Alv2HubCore(hub)));

  /// How long [dispose] waits for the worker before killing it.
  static const closeTimeout = Duration(seconds: 1);

  final Alv2HubLink _link;
  Future<void>? _disposing;

  bool get _closed => _disposing != null;

  /// RPM for the 4 groups, or `null` if the hub is inaccessible.
  Future<List<int>?> readRpm() async =>
      _closed ? null : (await _link.request(const HubReadRpm())).rpm;

  Future<bool> setDuty(int group, int duty) => _ok(HubSetDuty(group, duty));

  Future<bool> setMotherboardSync(List<bool> sync) =>
      _ok(HubSetMotherboardSync(List.of(sync)));

  Future<bool> setQuantity(int group, int q) => _ok(HubSetQuantity(group, q));

  Future<bool> setMergeOrder(List<int> order) =>
      _ok(HubSetMergeOrder(List.of(order)));

  Future<bool> disableArgbSync() => _ok(const HubDisableArgbSync());

  /// See [Alv2Hub.sendLighting]; [priority] skips the worker's queue.
  Future<bool> sendLighting(
    List<Alv2PortWrite> writes, {
    bool frame = true,
    bool priority = false,
  }) => _ok(HubSendLighting(List.of(writes), frame: frame, priority: priority));

  Future<bool> streamCanvas(List<Alv2PortWrite> writes) =>
      _ok(HubStreamCanvas(List.of(writes)));

  Future<bool> identify(int group, {bool merge = false}) =>
      _ok(HubIdentify(group, merge: merge));

  /// Closes the hub after everything already sent to it, then releases the
  /// worker; after [closeTimeout] the worker is killed. Safe to call twice.
  Future<void> dispose() => _disposing ??= _dispose();

  Future<void> _dispose() async {
    try {
      await _link
          .request(const HubDispose())
          .timeout(
            closeTimeout,
            onTimeout: () => const Alv2HubReply.failed(-1),
          );
    } finally {
      _link.dispose();
    }
  }

  Future<bool> _ok(Alv2HubCommand c) async =>
      _closed ? false : (await _link.request(c)).ok;
}
