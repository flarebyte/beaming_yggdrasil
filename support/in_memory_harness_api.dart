// purpose: Define the public support-only harness API used by tests and the
// example app.
// responsibilities: Construct the harness, expose the fake client surfaces,
// and provide the top-level harness factory.
// architecture notes: This file keeps the support API thin while the fake
// behavior lives in separate part files.
part of 'in_memory_harness.dart';

/// Small in-memory harness for early consumer workflow testing.
///
/// This is intentionally not a production transport implementation. It exists
/// to validate the public API shape and the first useful workflow without
/// committing to HTTP or WebSocket internals too early.
class BeamingInMemoryHarness {
  final BeamingYggdrasilClient client;
  final BeamingYggdrasilRxClient rxClient;
  final BeamingYggdrasilTestingClient testingClient;
  final BeamingYggdrasilWebSocketSession webSocketSession;

  final _InMemoryState _state;

  BeamingInMemoryHarness._(
    this.client,
    this.rxClient,
    this.testingClient,
    this.webSocketSession,
    this._state,
  );

  factory BeamingInMemoryHarness() {
    return BeamingInMemoryHarness.withDiagnostics();
  }

  factory BeamingInMemoryHarness.withDiagnostics({
    BeamingDiagnosticsHook? diagnosticsHook,
    BeamingDiagnosticsRedactor? diagnosticsRedactor,
  }) {
    final state = _InMemoryState(
      diagnosticsHook: diagnosticsHook,
      diagnosticsRedactor: diagnosticsRedactor,
    );
    final client = _InMemoryClient(state);
    return BeamingInMemoryHarness._(
      client,
      BeamingClassicRxClient(client),
      _InMemoryTestingClient(state),
      _InMemoryWebSocketSession(state),
      state,
    );
  }

  /// Closes the harness and releases its internal controllers.
  Future<void> close() => _state.close();
}

/// Creates a diagnostics-aware in-memory harness for examples and tests.
BeamingInMemoryHarness createBeamingInMemoryHarness({
  BeamingDiagnosticsHook? diagnosticsHook,
  BeamingDiagnosticsRedactor? diagnosticsRedactor,
}) =>
    BeamingInMemoryHarness.withDiagnostics(
      diagnosticsHook: diagnosticsHook,
      diagnosticsRedactor: diagnosticsRedactor,
    );
