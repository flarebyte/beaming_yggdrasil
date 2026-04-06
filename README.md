# beaming_yggdrasil

![Experimental](https://img.shields.io/badge/status-experimental-blue)

Pure Dart client primitives for a Yggdrasil-style service, designed to embed
cleanly inside Flutter applications.

The package currently provides:

- immutable client-side key, value, result, and event models
- a classic `Future` and `Stream` client surface
- an optional Rx-friendly adapter layered on top of the classic client
- a separate testing client for snapshot seeding in tests
- typed REST and light WebSocket DTOs
- an in-memory harness for early workflow validation

The package does not currently provide:

- a production HTTP implementation
- a production WebSocket transport
- an offline cache engine
- Flutter widgets or `BuildContext` integrations

## Flutter-Friendly Usage

The core library stays pure Dart, so a Flutter app can wrap it in its own
controller, view model, or state-management layer.

```dart
import 'dart:async';

import 'package:beaming_yggdrasil/beaming_yggdrasil.dart';

class TreeController {
  final BeamingYggdrasilClient client;

  StreamSubscription<BeamingEvent>? _subscription;
  List<BeamingValue> snapshot = const [];

  TreeController(this.client);

  Future<void> load(String rootKeyId) async {
    snapshot = await client.getSnapshot(rootKeyId);
  }

  Future<void> startWatching(String rootKeyId) async {
    await _subscription?.cancel();
    _subscription = client.watch([rootKeyId]).listen((event) {
      if (event is BeamingSetEvent) {
        _applyValue(event.keyValue);
      }
    });
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
  }

  void _applyValue(BeamingValue nextValue) {
    final current = snapshot.toList();
    final index = current.indexWhere(
      (value) => value.key.keyId == nextValue.key.keyId,
    );
    if (index == -1) {
      current.add(nextValue);
    } else {
      current[index] = nextValue;
    }
    snapshot = List<BeamingValue>.unmodifiable(current);
  }
}
```

## Local Example

See `example/example.dart` for a complete in-memory example showing:

- snapshot bootstrap
- watch subscription
- create flow
- the optional Rx adapter

## Development

Useful commands:

- `make format-dart`
- `make analyze`
- `make test-unit`
- `make package-check`

## License

`beaming_yggdrasil` is available under the [LICENSE](LICENSE).
