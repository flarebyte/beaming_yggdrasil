// purpose: Define the transport-agnostic WebSocket session boundary used by
// the rest of the protocol types.
// responsibilities: Expose typed send, receive, and close operations for a
// live session.
// architecture notes: This remains interface-only so socket lifecycle,
// reconnect, and transport implementation details stay outside the protocol
// model.
part of 'websocket.dart';

/// Optional light WebSocket session boundary.
abstract class BeamingYggdrasilWebSocketSession {
  /// Sends a typed client message over the session.
  Future<void> send(BeamingClientMessage message);

  /// Returns the decoded server message stream for this session.
  Stream<BeamingServerMessage> messages();

  /// Closes the session and releases any resources.
  Future<void> close();
}
