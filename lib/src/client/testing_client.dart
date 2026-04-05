import 'model.dart';

/// Mock-control and testing-only surface.
///
/// Real end-user clients should read snapshots created by the server. Snapshot
/// replacement belongs here so tests can seed state against mock servers.
abstract class BeamingYggdrasilTestingClient {
  Future<void> replaceSnapshot(
    String rootKeyId,
    List<BeamingValue> values,
  );
}
