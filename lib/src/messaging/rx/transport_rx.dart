import 'dart:async';
import 'dart:collection';
import 'package:rxdart/rxdart.dart';

import '../transport.dart';
import '../transport_types.dart';

/// Configuration for [TransportRx].
///
/// Defaults are conservative (no implicit buffering, no auto-connect).
class TransportRxConfig {
  /// If true, enqueue outbound messages while the transport is not `open`.
  /// Buffered messages flush FIFO when `open` is reached.
  final bool bufferWhileNotOpen;

  /// Maximum number of messages to buffer when [bufferWhileNotOpen] is true.
  /// On overflow, behavior is governed by [onOverflow].
  final int maxBuffered;

  /// Overflow policy for the outbound buffer.
  ///
  /// - [dropOldest]: evict the oldest buffered message, keep the newest.
  /// - [dropNewest]: drop the incoming message.
  /// - [error]: add an error to [outboundErrors$] and drop the incoming message.
  final TransportRxOverflow onOverflow;

  /// If true, calling [send.add] when `closed`/`connecting` will attempt
  /// to [connect] first. Connection failures are surfaced on [state$].
  final bool autoConnect;

  const TransportRxConfig({
    this.bufferWhileNotOpen = false,
    this.maxBuffered = 256,
    this.onOverflow = TransportRxOverflow.error,
    this.autoConnect = false,
  }) : assert(maxBuffered > 0, 'maxBuffered must be > 0');
}

/// Overflow policies for outbound buffering.
enum TransportRxOverflow { dropOldest, dropNewest, error }

/// RxDart façade over a plain [Transport].
///
/// Goals:
/// - Expose **hot** streams with replayed state via [state$].
/// - Provide a **send** [Sink] that can (optionally) buffer until `open`.
/// - Keep lifecycle ownership explicit: you still call [connect]/[close].
///
/// Non-goals:
/// - Silent auto-reconnect/backoff (compose this above if needed).
/// - Encoding/decoding (payloads are raw `String`).
final class TransportRx {
  /// Hot, replaying connection state (replays last value to late subscribers).
  ///
  /// Emits `TransportState` values and forwards errors from the underlying
  /// transport’s `states` stream.
  final ValueStream<TransportState> state$;

  /// Hot multicast stream of inbound messages (no replay).
  ///
  /// Completes after the underlying transport completes/tears down.
  final Stream<String> messages$;

  /// Outbound sink. Add raw `String` messages here.
  ///
  /// Behavior:
  /// - If transport is `open`, forwards synchronously to `transport.send`.
  /// - If not `open`:
  ///   - When [config.bufferWhileNotOpen] is true, buffers (bounded).
  ///   - Otherwise, adds an error to [outboundErrors$].
  final Sink<String> send;

  /// Outbound error notifications (e.g., send while closed, buffer overflow).
  ///
  /// This stream is **hot** and **broadcast**; it never completes before [dispose].
  final Stream<Object> outboundErrors$;

  /// Underlying transport (owned by the caller).
  Transport get transport => _transport;

  /// Establish connection (idempotent as per [Transport] contract).
  Future<void> connect() => _transport.connect();

  /// Close connection gracefully (idempotent as per [Transport] contract).
  Future<void> close([int? code, String? reason]) => _transport.close(code, reason);

  /// Dispose façade resources (subjects/subscriptions).
  ///
  /// Safe to call multiple times. Does **not** dispose the underlying transport.
  void dispose();

  // ---- ctor ----
  factory TransportRx(Transport transport, {TransportRxConfig config = const TransportRxConfig()}) =
      _TransportRxImpl;
}
