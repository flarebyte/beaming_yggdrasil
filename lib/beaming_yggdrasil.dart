library;

/// Pure Dart client primitives intended to embed cleanly inside Flutter apps.
///
/// Keep Flutter framework concepts out of this package so application code can
/// compose the client with its own widget tree and state-management approach.
///
/// The main entrypoints are:
/// - [BeamingYggdrasilClient] for classic `Future` and `Stream` workflows
/// - [BeamingYggdrasilRxClient] for optional Rx-style composition
/// - [BeamingYggdrasilTestingClient] for test-only snapshot control
/// - [createBeamingInMemoryHarness] for examples, acceptance tests, and early
///   integration work
export 'src/client/client.dart';
export 'src/client/diagnostics.dart';
export 'src/client/error.dart';
export 'src/client/in_memory.dart';
export 'src/client/model.dart';
export 'src/client/recovery.dart';
export 'src/client/rest.dart';
export 'src/client/rx_client.dart';
export 'src/client/testing_client.dart';
export 'src/client/websocket.dart';
