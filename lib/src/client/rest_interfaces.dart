/// purpose: Declare the transport-facing REST client boundaries so adapters can
/// implement the wire contract without changing the main client API.
///
/// responsibilities: Expose real-client REST methods and the separate
/// testing-only snapshot seeding method.
///
/// architecture notes: The testing REST interface is split from the real one
/// on purpose so mock-only snapshot mutation does not drift into production
/// usage.
part of 'rest.dart';

/// Transport-facing REST client boundary.
///
/// This keeps the wire DTO layer explicit without committing the main public
/// client surface to any specific HTTP package yet.
abstract class BeamingYggdrasilRestClient {
  /// Reads a full snapshot through the REST wire contract.
  Future<BeamingRestEnvelope<BeamingGetSnapshotResponseData>> getSnapshot(
    BeamingGetSnapshotRequest request,
  );

  /// Writes node values through the REST wire contract.
  Future<BeamingRestEnvelope<BeamingSetKeyValueResponseData>> setNode(
    BeamingSetKeyValueRequest request,
  );

  /// Reads selected node values through the REST wire contract.
  Future<BeamingRestEnvelope<BeamingGetKeyValueResponseData>> getNode(
    BeamingGetKeyValueRequest request,
  );

  /// Requests server-side child creation through the REST wire contract.
  Future<BeamingRestEnvelope<BeamingNewKeysResponseData>> create(
    BeamingNewKeysRequest request,
  );
}

/// Test-only REST boundary for mock snapshot seeding.
abstract class BeamingYggdrasilTestingRestClient {
  /// Replaces a snapshot through the mock-only testing REST contract.
  Future<BeamingRestEnvelope<BeamingSetSnapshotResponseData>> setSnapshot(
    BeamingSetSnapshotRequest request,
  );
}
