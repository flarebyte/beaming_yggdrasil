import 'package:beaming_yggdrasil/beaming_yggdrasil.dart';

const rootKeyId = 'tenant:t8f3a1c2:group:g4b7d9e1:dashboard:d1e52f07';

Future<BeamingServerMessage> readServerMessage(
  Stream<BeamingServerMessage> messages,
) {
  return messages.first.timeout(const Duration(seconds: 5));
}
