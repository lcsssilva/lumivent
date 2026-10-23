import 'dart:async';

import 'alv2_hub_command.dart';
import 'alv2_hub_reply.dart';
import 'alv2_hub_core.dart';
import 'alv2_hub_link.dart';

/// Same-isolate link over an [Alv2HubCore] (tests; no isolate).
class LocalAlv2HubLink implements Alv2HubLink {
  LocalAlv2HubLink(this.core);
  final Alv2HubCore core;
  int _next = 0;

  @override
  Future<Alv2HubReply> request(Alv2HubCommand command) =>
      core.handle(_next++, command);

  @override
  void dispose() {}
}
