// purpose: Define the testing-only client surface for snapshot control that real consumers must not rely on in production code.
// responsibilities: Expose snapshot replacement for tests, fixtures, and mock-server setup.
// architecture notes: Snapshot mutation lives here on purpose because the real client is meant to read server-created snapshots rather than author them.
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
