# beaming_yggdrasil

![Experimental](https://img.shields.io/badge/status-experimental-blue)

![beaming_yggdrasil illustration](https://raw.githubusercontent.com/flarebyte/beaming_yggdrasil/main/doc/beaming-yggdrasil.jpeg)

Pure Dart client primitives for a Yggdrasil-style service, designed to embed
cleanly inside Flutter applications.

This package is currently best understood as a spec-aligned client foundation:
it provides immutable models, typed wire DTOs, an optional Rx adapter, and a
testing-only snapshot control surface. It does not yet ship production HTTP or
WebSocket transport implementations.

The package currently provides:

- immutable client-side key, value, result, and event models
- a classic `Future` and `Stream` client surface
- an optional Rx-friendly adapter layered on top of the classic client
- a separate testing client for snapshot seeding in tests
- typed REST and light WebSocket DTOs

The package does not currently provide:

- a production HTTP implementation
- a production WebSocket transport
- an offline cache engine
- Flutter widgets or `BuildContext` integrations

## Package Scope

- pure Dart library, intended to run inside Flutter apps
- current value payload contract is string-only
- recovery and diagnostics are explicit hooks, not hidden framework behavior
- snapshot replacement is testing-only and not part of the real client API

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

See `example/example.dart` for a complete example showing:

- snapshot bootstrap
- watch subscription
- create flow
- the optional Rx adapter

The example uses a local support harness outside `lib/`. That harness is not
part of the published runtime API.

## Public API Overview

- `BeamingYggdrasilClient`
  Main consumer surface using `Future` and `Stream`.
- `BeamingYggdrasilRxClient`
  Optional adapter for Rx-style composition over the classic client.
- `BeamingYggdrasilTestingClient`
  Testing-only snapshot seeding surface.
- `BeamingRestEnvelope` and related DTOs
  Typed REST request and response models.
- `BeamingServerMessage` and related DTOs
  Typed light WebSocket protocol models.
- `BeamingRecoveryExecutor`
  Explicit recovery-policy boundary for refresh and resubscribe flows.

## Development

Useful commands:

- `make format-dart`
- `make analyze`
- `make test-unit`
- `make test-e2e`
- `make package-check`
- `make publish-dry-run`
- `make publish-check`

`make test-e2e` expects the sibling mock-server repo at `../chatty-ratatoskr`.

## License

`beaming_yggdrasil` is available under the [LICENSE](LICENSE).
