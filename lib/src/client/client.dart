import 'model.dart';

/// Primary public API.
///
/// This file intentionally defines interfaces only. Concrete transport, retry,
/// cache sync, and server-integration behavior should be added later.
///
/// This surface is intentionally pure Dart so it can be embedded in Flutter
/// apps without coupling the core library to widgets or BuildContext.
abstract class BeamingYggdrasilClient {
  /// Reads the current server-produced snapshot for a root key.
  Future<List<BeamingValue>> getSnapshot(String rootKeyId);

  /// Reads selected values under a root key while preserving the request order.
  Future<List<BeamingValue>> getNode(
    String rootKeyId,
    List<String> keyIds,
  );

  /// Writes one or more values under a root key.
  Future<List<BeamingWriteResult>> setNode(
    String rootKeyId,
    List<BeamingValue> values,
  );

  /// Requests server-side creation of child keys under a root key.
  Future<List<BeamingWriteResult>> createChildren(
    String rootKeyId,
    List<BeamingClientKey> provisionalKeys,
  );

  /// Subscribes to lightweight change events for one or more roots.
  Stream<BeamingEvent> watch(List<String> rootKeyIds);
}
