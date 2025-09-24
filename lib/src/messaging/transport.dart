import 'dart:async';
import 'transport_types.dart';

/// Protocol-agnostic, string-based realtime transport.
///
/// Responsibilities:
/// - Deliver inbound string messages via [messages].
/// - Emit connection lifecycle via [states].
/// - Write outbound strings via [send].
/// - Open/close the underlying connection via [connect]/[close].
///
/// Non-goals:
/// - Message encoding/decoding (JSON, etc.) — keep outside this interface.
/// - Reconnection/backoff — compose above this layer.
/// - Auth/session — inject via headers/URL or protocol-specific config.
///
/// Stream contracts:
/// - [states] MUST be a broadcast stream. It SHOULD emit `connecting` then `open`
///   on successful connection; `closing` then `closed` on graceful shutdown.
///   Errors MUST be observable both as:
///     1) a `TransportState.error` emission and
///     2) `states.addError(error, stackTrace)`
/// - [messages] MUST be a broadcast stream. It MUST complete after `closed`.
///   It MUST deliver messages **in order** of arrival for a given connection.
/// - Both streams MUST be re-created or kept valid across reconnects only if
///   your implementation explicitly supports reconnect inside `connect()`.
///   (Recommended: **do not** auto-reconnect here; keep one connection per instance.)
abstract class Transport {
  /// Inbound messages from the remote endpoint.
  ///
  /// Semantics:
  /// - Broadcast stream.
  /// - Only string payloads (binary not supported here).
  /// - MUST cease emissions after the transport reaches `closed` for a session.
  Stream<String> get messages;

  /// Connection lifecycle events.
  ///
  /// Semantics:
  /// - Broadcast stream.
  /// - Emits `connecting -> open` after a successful [connect()].
  /// - Emits `closing -> closed` after a [close()].
  /// - On failures, MUST emit `error` and also add the underlying error to the stream.
  Stream<TransportState> get states;

  /// Establishes the connection.
  ///
  /// Requirements:
  /// - Idempotent: calling while `connecting` or `open` MUST be a no-op.
  /// - On success, MUST cause [states] to emit `connecting` (if not already) and `open`.
  /// - On failure, MUST:
  ///   - throw a [TransportException] (preferred) or other [Exception], and
  ///   - emit `error` and add the same error to [states].
  ///
  /// Timeouts:
  /// - If implemented, throw a [TransportException] with kind `io` or `handshake`.
  Future<void> connect();

  /// Sends a raw string to the remote endpoint.
  ///
  /// Requirements:
  /// - MUST NOT buffer indefinitely. If not `open`, either:
  ///   - throw [StateError] (recommended), or
  ///   - throw [TransportException] with kind `usage`.
  /// - When `open`, MUST write in-order and as-is (no mutation).
  ///
  /// Backpressure:
  /// - If the underlying protocol blocks, you MAY apply bounded buffering,
  ///   but MUST surface overflow as an error (throw) rather than unbounded growth.
  void send(String data);

  /// Closes the connection gracefully.
  ///
  /// Requirements:
  /// - Idempotent: repeated calls after `closing/closed` MUST be a no-op.
  /// - SHOULD attempt a protocol-appropriate graceful close (e.g., WS close frame).
  /// - MUST result in [states] emitting `closing` then `closed`.
  ///
  /// Arguments:
  /// - [code] and [reason] are protocol-specific advisory hints and MAY be ignored.
  Future<void> close([int? code, String? reason]);
}
