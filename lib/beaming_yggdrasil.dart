/// purpose: Expose the stable public library surface and route consumers to the
/// package entrypoints they should import from Flutter-compatible Dart code.
///
/// responsibilities: Export the supported client-facing modules and define the
/// package-level scope of the public API.
///
/// architecture notes: This file stays thin on purpose so the public surface
/// is explicit here while implementation details remain under `lib/src`.
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
