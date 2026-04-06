import 'package:rxdart/rxdart.dart';

import 'client.dart';
import 'model.dart';

/// Optional Rx-friendly adapter surface.
///
/// Keep this as a companion API layered on top of the classic client rather
/// than the only public entrypoint.
abstract class BeamingYggdrasilRxClient {
  /// Rx wrapper over [BeamingYggdrasilClient.getSnapshot].
  Stream<List<BeamingValue>> snapshot$(String rootKeyId);

  /// Rx wrapper over [BeamingYggdrasilClient.getNode].
  Stream<List<BeamingValue>> node$(String rootKeyId, List<String> keyIds);

  /// Rx wrapper over [BeamingYggdrasilClient.setNode].
  Stream<List<BeamingWriteResult>> setNode$(
    String rootKeyId,
    List<BeamingValue> values,
  );

  /// Rx wrapper over [BeamingYggdrasilClient.createChildren].
  Stream<List<BeamingWriteResult>> createChildren$(
    String rootKeyId,
    List<BeamingClientKey> provisionalKeys,
  );

  /// Rx wrapper over [BeamingYggdrasilClient.watch].
  Stream<BeamingEvent> watch$(List<String> rootKeyIds);
}

/// Default Rx adapter layered on top of a classic client.
class BeamingClassicRxClient implements BeamingYggdrasilRxClient {
  final BeamingYggdrasilClient _client;

  const BeamingClassicRxClient(this._client);

  @override
  Stream<List<BeamingWriteResult>> createChildren$(
    String rootKeyId,
    List<BeamingClientKey> provisionalKeys,
  ) {
    return Rx.fromCallable(
      () => _client.createChildren(rootKeyId, provisionalKeys),
    );
  }

  @override
  Stream<List<BeamingValue>> node$(String rootKeyId, List<String> keyIds) {
    return Rx.fromCallable(
      () => _client.getNode(rootKeyId, keyIds),
    );
  }

  @override
  Stream<List<BeamingWriteResult>> setNode$(
    String rootKeyId,
    List<BeamingValue> values,
  ) {
    return Rx.fromCallable(
      () => _client.setNode(rootKeyId, values),
    );
  }

  @override
  Stream<List<BeamingValue>> snapshot$(String rootKeyId) {
    return Rx.fromCallable(
      () => _client.getSnapshot(rootKeyId),
    );
  }

  @override
  Stream<BeamingEvent> watch$(List<String> rootKeyIds) {
    return _client.watch(rootKeyIds).share();
  }
}
