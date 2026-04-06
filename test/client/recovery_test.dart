import 'package:beaming_yggdrasil/beaming_yggdrasil.dart';
import 'package:test/test.dart';

void main() {
  test('recovery executor proceeds explicitly and emits stable recovery events',
      () async {
    final events = <BeamingDiagnosticEvent>[];
    final executor = BeamingRecoveryExecutor(
      diagnosticsHook: events.add,
      policy: (_) => BeamingRecoveryDecision.proceed,
    );

    final result = await executor.run<String>(
      const BeamingRecoveryAction(
        kind: BeamingRecoveryActionKind.refreshSnapshot,
        rootKeyIds: ['roots/oak'],
        attempt: 1,
        reason: 'stale local state',
      ),
      () async => 'refreshed',
    );

    expect(result, 'refreshed');
    expect(
      events.map((event) => event.action).toList(),
      ['requested', 'proceed', 'succeeded'],
    );
    expect(
      events
          .every((event) => event.kind == BeamingDiagnosticEventKind.recovery),
      isTrue,
    );
  });

  test('recovery executor can skip actions through policy', () async {
    final events = <BeamingDiagnosticEvent>[];
    final executor = BeamingRecoveryExecutor(
      diagnosticsHook: events.add,
      policy: (_) => BeamingRecoveryDecision.skip,
    );

    final result = await executor.run<String>(
      const BeamingRecoveryAction(
        kind: BeamingRecoveryActionKind.resubscribe,
        rootKeyIds: ['roots/oak'],
        attempt: 2,
        reason: 'connection resumed',
      ),
      () async => 'should-not-run',
    );

    expect(result, isNull);
    expect(
      events.map((event) => event.action).toList(),
      ['requested', 'skip'],
    );
  });

  test('recovery executor reports failure without swallowing it', () async {
    final events = <BeamingDiagnosticEvent>[];
    final executor = BeamingRecoveryExecutor(
      diagnosticsHook: events.add,
    );

    await expectLater(
      executor.run<void>(
        const BeamingRecoveryAction(
          kind: BeamingRecoveryActionKind.reconnectSession,
          rootKeyIds: ['roots/oak'],
          attempt: 3,
          reason: 'websocket closed',
        ),
        () async => throw const BeamingClientError(
          kind: BeamingClientErrorKind.protocolViolation,
          message: 'connection closed',
        ),
      ),
      throwsA(isA<BeamingClientError>()),
    );

    expect(
      events.map((event) => event.action).toList(),
      ['requested', 'proceed', 'failed'],
    );
    expect(events.last.details['error'], contains('connection closed'));
  });
}
