// purpose: Hold the mutable in-memory state used by the support harness.
// responsibilities: Store snapshot values, emit diagnostics and events,
// implement create semantics, and manage deterministic event ids.
// architecture notes: This state is intentionally simple and process-local; it
// exists only to support tests and examples, not as a cache or persistence
// abstraction.
part of 'in_memory_harness.dart';

class _InMemoryState {
  final StreamController<BeamingEvent> _events =
      StreamController<BeamingEvent>.broadcast();
  final Map<String, List<BeamingValue>> _snapshots = {};
  final Map<String, int> _snapshotCounters = {};
  final BeamingDiagnosticsHook? _diagnosticsHook;
  final BeamingDiagnosticsRedactor _diagnosticsRedactor;
  int _eventCounter = 0;

  _InMemoryState({
    BeamingDiagnosticsHook? diagnosticsHook,
    BeamingDiagnosticsRedactor? diagnosticsRedactor,
  })  : _diagnosticsHook = diagnosticsHook,
        _diagnosticsRedactor = diagnosticsRedactor ?? _identityDiagnostics;

  Stream<BeamingEvent> get events => _events.stream;

  void emitError(String action, Object error) {
    _emitDiagnostic(
      BeamingDiagnosticEvent(
        kind: BeamingDiagnosticEventKind.error,
        action: action,
        details: <String, Object?>{
          'error': error.toString(),
        },
      ),
    );
  }

  void emitRequest(String action, Map<String, Object?> details) {
    _emitDiagnostic(
      BeamingDiagnosticEvent(
        kind: BeamingDiagnosticEventKind.request,
        action: action,
        details: details,
      ),
    );
  }

  void emitSession(String action, Map<String, Object?> details) {
    _emitDiagnostic(
      BeamingDiagnosticEvent(
        kind: BeamingDiagnosticEventKind.session,
        action: action,
        details: details,
      ),
    );
  }

  Future<List<BeamingWriteResult>> createChildren(
    String rootKeyId,
    List<BeamingClientKey> provisionalKeys,
  ) async {
    final results = List<BeamingWriteResult>.unmodifiable(
      provisionalKeys.map((key) => _createChild(rootKeyId, key)).toList(),
    );
    if (results.any((result) => result.status != 'ok')) {
      emitError('createChildren', 'partial failure');
    }
    return results;
  }

  void applyNodeValues(String rootKeyId, List<BeamingValue> values) {
    final current = List<BeamingValue>.from(_snapshots[rootKeyId] ?? const []);
    for (final value in values) {
      final index = current.indexWhere(
        (existing) => existing.key.keyId == value.key.keyId,
      );
      if (index == -1) {
        current.add(value);
      } else {
        current[index] = value;
      }
      _events.add(
        BeamingSetEvent(
          rootKey: BeamingClientKey(keyId: rootKeyId),
          keyValue: value,
        ),
      );
    }
    _snapshots[rootKeyId] = List<BeamingValue>.unmodifiable(current);
  }

  Future<void> close() async {
    await _events.close();
  }

  BeamingWriteResult _createChild(String rootKeyId, BeamingClientKey key) {
    if (key.localKeyId == null || key.localKeyId!.trim().isEmpty) {
      return BeamingWriteResult(
        key: key,
        status: 'invalid',
        message: 'localKeyId is required for createChildren',
      );
    }
    if (!_isChildKey(rootKeyId, key.keyId)) {
      return BeamingWriteResult(
        key: key,
        status: 'invalid',
        message: 'created keys must be children of the root key',
      );
    }
    return BeamingWriteResult(
      key: BeamingClientKey(
        keyId: key.keyId,
        version: key.version ?? 'created:${key.localKeyId}',
        localKeyId: key.localKeyId,
      ),
      status: 'ok',
    );
  }

  void replaceSnapshot(String rootKeyId, List<BeamingValue> values) {
    final nextCounter = (_snapshotCounters[rootKeyId] ?? 0) + 1;
    _snapshotCounters[rootKeyId] = nextCounter;
    final snapshotVersion = 'snapshot-$nextCounter';
    _snapshots[rootKeyId] = List<BeamingValue>.unmodifiable(values);
    _events.add(
      BeamingSnapshotReplacedEvent(
        rootKey: BeamingClientKey(
          keyId: rootKeyId,
          version: snapshotVersion,
        ),
        snapshotVersion: snapshotVersion,
      ),
    );
  }

  List<BeamingValue> snapshotValues(String rootKeyId) {
    return List<BeamingValue>.unmodifiable(_snapshots[rootKeyId] ?? const []);
  }

  bool _isChildKey(String rootKeyId, String keyId) {
    return keyId.startsWith('$rootKeyId/');
  }

  void _emitDiagnostic(BeamingDiagnosticEvent event) {
    final hook = _diagnosticsHook;
    if (hook == null) {
      return;
    }
    try {
      hook(_diagnosticsRedactor(event));
    } catch (_) {
      // Diagnostics must not break core client behavior.
    }
  }

  String nextCreatedMarker() {
    return 'created-$_eventCounter';
  }

  String nextEventId() {
    _eventCounter += 1;
    return 'event-$_eventCounter';
  }
}

BeamingDiagnosticEvent _identityDiagnostics(BeamingDiagnosticEvent event) =>
    event;
