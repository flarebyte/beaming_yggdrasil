/// Coarse connection lifecycle states.
///
/// Contract:
/// - `states` MUST be a broadcast stream.
/// - First emitted state after `connect()` MUST be `connecting` (or `open` when
///   connection completes synchronously).
/// - Transitions MUST be monotonic and consistent with the lifecycle:
///   `connecting -> open -> closing -> closed`
///   Errors can occur at any point and MUST be surfaced via:
///   (a) an `error` state emission, and
///   (b) `states.addError(...)` on the states stream.
///
/// Notes:
/// - Implementations MAY emit `error` followed by `closed`.
/// - After `closed`, no further states MUST be emitted (except errors).
enum TransportState {
  connecting,
  open,
  closing,
  closed,
  error,
}

/// Categorizes failures for better diagnostics and policy decisions.
enum TransportErrorKind {
  handshake,     // TLS/WS/SSE negotiation, auth, protocol, bad handshake
  io,            // network I/O, DNS, socket closed, timeouts
  framing,       // invalid frame/payload for the protocol
  usage,         // API misuse (send while closed, etc.)
  unknown,       // uncategorized
}

/// Exception thrown by implementations to communicate failures.
///
/// Guidance:
/// - Throw `TransportException` (with [kind]) for operational failures.
/// - Throw `StateError` for API misuse (e.g., send() when not open), unless you
///   intentionally report misuse as a `usage` kind.
class TransportException implements Exception {
  final TransportErrorKind kind;
  final String message;
  final Object? cause;      // underlying error (e.g., SocketException)
  final StackTrace? stackTrace;

  const TransportException(
    this.kind,
    this.message, {
    this.cause,
    this.stackTrace,
  });

  @override
  String toString() =>
      'TransportException(kind: $kind, message: $message, cause: $cause)';
}