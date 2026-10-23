part of 'monitoring_engine_test.dart';

class _ScriptedLink implements Alv2HubLink {
  _ScriptedLink(this.replies);

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
