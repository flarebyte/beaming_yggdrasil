import 'dart:async';

import 'package:beaming_yggdrasil/beaming_yggdrasil.dart';
import 'package:test/test.dart';

import '../../support/in_memory_harness.dart';

void main() {
  test('diagnostics hook observes request session and error activity',
      () async {
    final events = <BeamingDiagnosticEvent>[];
    final harness = createBeamingInMemoryHarness(
      diagnosticsHook: events.add,
    );
    addTearDown(harness.close);

    await harness.client.getSnapshot('roots/oak');
    unawaited(
      harness.webSocketSession.messages().take(1).drain<void>(),
    );
    await harness.webSocketSession.send(
      const BeamingSubscribeMessage(rootKeys: ['roots/oak']),
    );
    await harness.client.createChildren(
      'roots/oak',
      const [
        BeamingClientKey(keyId: 'roots/oak/missing-local'),
      ],
    );

    expect(
      events.map((event) => event.kind).toList(),
      [
        BeamingDiagnosticEventKind.request,
        BeamingDiagnosticEventKind.session,
        BeamingDiagnosticEventKind.request,
        BeamingDiagnosticEventKind.error,
      ],
    );
    expect(events[0].action, 'getSnapshot');
    expect(events[1].action, 'subscribe');
    expect(events[2].action, 'createChildren');
    expect(events[3].action, 'createChildren');
  });

  test('diagnostics redactor can scrub event details before emission',
      () async {
    final events = <BeamingDiagnosticEvent>[];
    final harness = createBeamingInMemoryHarness(
      diagnosticsHook: events.add,
      diagnosticsRedactor: (event) => event.copyWith(
        details: <String, Object?>{
          ...event.details,
          'rootKeyId': '[redacted]',
        },
      ),
    );
    addTearDown(harness.close);

    await harness.client.getSnapshot('roots/oak');

    expect(events.single.details['rootKeyId'], '[redacted]');
  });

  test('diagnostics hook failures do not break core client behavior', () async {
    final harness = createBeamingInMemoryHarness(
      diagnosticsHook: (_) => throw StateError('hook failure'),
    );
    addTearDown(harness.close);

    await harness.testingClient.replaceSnapshot(
      'roots/oak',
      const [
        BeamingValue(
          key: BeamingClientKey(keyId: 'roots/oak/title'),
          value: 'oak',
        ),
      ],
    );

    final snapshot = await harness.client.getSnapshot('roots/oak');
    expect(snapshot.single.value, 'oak');
  });
}
