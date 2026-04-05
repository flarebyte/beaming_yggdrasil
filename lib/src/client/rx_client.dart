import 'model.dart';

/// Optional Rx-friendly adapter surface.
///
/// Keep this as a companion API layered on top of the classic client rather
/// than the only public entrypoint.
abstract class BeamingYggdrasilRxClient {
  Stream<List<BeamingValue>> snapshot$(String rootKeyId);

  Stream<List<BeamingValue>> node$(String rootKeyId, List<String> keyIds);

  Stream<List<BeamingWriteResult>> setNode$(
    String rootKeyId,
    List<BeamingValue> values,
  );

  Stream<BeamingEvent> watch$(List<String> rootKeyIds);
}
