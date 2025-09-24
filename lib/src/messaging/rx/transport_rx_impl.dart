part of 'transport_rx.dart';


import 'package:rxdart/rxdart.dart';

import '../transport.dart';
import '../transport_types.dart';
import 'transport_rx.dart';

final class _TransportRxImpl implements TransportRx {
  final Transport _transport;
  final TransportRxConfig _config;

  late final ValueStream<TransportState> state$;
  late final Stream<String> messages$;

  final _outboundCtrl = PublishSubject<String>();
  final _outboundErrCtrl = PublishSubject<Object>();
  @override
  Stream<Object> get outboundErrors$ => _outboundErrCtrl.stream;

  // FIFO buffer for messages while not open.
  final _buffer = Queue<String>();

  late final StreamSubscription<String> _sendSub;
  late final StreamSubscription<TransportState> _stateSub;

  _TransportRxImpl(this._transport, {TransportRxConfig config = const TransportRxConfig()})
      : _config = config {
    // Hot streams
    state$ = _transport.states.shareValueSeeded(TransportState.closed);
    messages$ = _transport.messages.share();

    // Drain buffer on open, monitor states for optional auto-connect.
    _stateSub = state$.listen((s) {
      if (s == TransportState.open) _flushBuffer();
    }, onError: (e, st) {
      // Surface state errors but do not dispose.
    });

    // Outbound pipeline
    _sendSub = _outboundCtrl.listen(_handleOutbound);
  }

  @override
  Sink<String> get send => _outboundCtrl.sink;

  @override
  Transport get transport => _transport;

  // ---- lifecycle passthrough ----
  @override
  Future<void> connect() => _transport.connect();

  @override
  Future<void> close([int? code, String? reason]) => _transport.close(code, reason);

  // ---- internal ----
  void _handleOutbound(String data) async {
    final isOpen = state$.value == TransportState.open;

    if (!isOpen) {
      if (_config.autoConnect) {
        try {
          await _transport.connect();
        } catch (_) {
          // Failure is already surfaced on state$; continue to buffer/error below.
        }
      }

      if (state$.value != TransportState.open) {
        if (_config.bufferWhileNotOpen) {
          _enqueue(data);
          return;
        } else {
          _outboundErrCtrl.add(StateError('send() while not open'));
          return;
        }
      }
    }

    // Open now; forward immediately.
    _safeSend(data);
  }

  void _safeSend(String data) {
    try {
      _transport.send(data);
    } catch (e) {
      _outboundErrCtrl.add(e);
    }
  }

  void _enqueue(String data) {
    if (_buffer.length >= _config.maxBuffered) {
      switch (_config.onOverflow) {
        case TransportRxOverflow.dropOldest:
          _buffer.removeFirst();
          _buffer.addLast(data);
          return;
        case TransportRxOverflow.dropNewest:
          // drop incoming (no-op)
          return;
        case TransportRxOverflow.error:
          _outboundErrCtrl.add(StateError('Outbound buffer overflow'));
          return;
      }
    } else {
      _buffer.addLast(data);
    }
  }

  void _flushBuffer() {
    while (_buffer.isNotEmpty && state$.value == TransportState.open) {
      final m = _buffer.removeFirst();
      _safeSend(m);
    }
  }

  @override
  void dispose() {
    // Idempotent
    _sendSub.cancel();
    _stateSub.cancel();
    _outboundCtrl.close();
    _outboundErrCtrl.close();
    _buffer.clear();
  }
}