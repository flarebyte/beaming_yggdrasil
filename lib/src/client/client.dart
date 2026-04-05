import 'model.dart';

/// Primary public API.
///
/// This file intentionally defines interfaces only. Concrete transport, retry,
/// cache sync, and server-integration behavior should be added later.
///
/// This surface is intentionally pure Dart so it can be embedded in Flutter
/// apps without coupling the core library to widgets or BuildContext.
abstract class BeamingYggdrasilClient {
  Future<List<BeamingValue>> getSnapshot(String rootKeyId);

  Future<List<BeamingValue>> getNode(
    String rootKeyId,
    List<String> keyIds,
  );

  Future<List<BeamingWriteResult>> setNode(
    String rootKeyId,
    List<BeamingValue> values,
  );

  Future<List<BeamingWriteResult>> createChildren(
    String rootKeyId,
    List<BeamingClientKey> provisionalKeys,
  );

  Stream<BeamingEvent> watch(List<String> rootKeyIds);
}
