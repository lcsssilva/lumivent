import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:lumivent/features/devices/infrastructure/drivers/alv2/alv2_hub_command.dart';
import 'package:lumivent/features/devices/infrastructure/drivers/alv2/alv2_hub_reply.dart';
import 'package:lumivent/features/devices/infrastructure/drivers/alv2/alv2_hub_link.dart';

class ScriptedLink implements Alv2HubLink {
  ScriptedLink(this.replies);

  /// Each entry is a reply, or an error to throw.
  final List<Object> replies;

  @override
  Future<Alv2HubReply> request(Alv2HubCommand command) async {
    final next = replies.removeAt(0);
    if (next is Alv2HubReply) return next;
    throw next;
  }

  @override
  void dispose() {}
}
