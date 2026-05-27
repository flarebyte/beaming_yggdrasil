/// purpose: Make recovery policy an explicit higher-layer concern so retries
/// and resubscriptions are coordinated by callers instead of hidden inside
/// transport code.
///
/// responsibilities: Describe recovery actions and decisions, execute guarded
/// recovery operations, and emit recovery diagnostics.
///
/// architecture notes: The executor intentionally asks policy first and then
/// runs a supplied operation, which prevents implicit retry loops from becoming
/// part of the transport contract.
library;

import 'diagnostics.dart';

/// Supported recovery action categories.
enum BeamingRecoveryActionKind {
  refreshSnapshot,
  resubscribe,
  reconnectSession,
}

/// Policy outcomes for a proposed recovery action.
enum BeamingRecoveryDecision {
  proceed,
  skip,
}

/// Hook that decides whether a recovery action should run.
typedef BeamingRecoveryPolicy = BeamingRecoveryDecision Function(
  BeamingRecoveryAction action,
);

/// Immutable description of a recovery action request.
class BeamingRecoveryAction {
  final BeamingRecoveryActionKind kind;
  final List<String> rootKeyIds;
  final int attempt;
  final String reason;

  const BeamingRecoveryAction({
    required this.kind,
    required this.rootKeyIds,
    required this.attempt,
    required this.reason,
  });
}

/// Explicit higher-layer recovery executor.
///
/// This does not hide retries inside transport. It gives callers one place to
/// ask a policy whether a recovery action should run, while still keeping the
/// actual recovery operation explicit.
class BeamingRecoveryExecutor {
  final BeamingRecoveryPolicy? policy;
  final BeamingDiagnosticsHook? diagnosticsHook;
  final BeamingDiagnosticsRedactor _diagnosticsRedactor;

  const BeamingRecoveryExecutor({
    this.policy,
    this.diagnosticsHook,
    BeamingDiagnosticsRedactor? diagnosticsRedactor,
  }) : _diagnosticsRedactor = diagnosticsRedactor ?? _identityRecoveryEvent;

  /// Runs a recovery operation if the policy allows it and emits diagnostics.
  Future<T?> run<T>(
    BeamingRecoveryAction action,
    Future<T> Function() operation,
  ) async {
    _emit('requested', action);
    final decision = policy?.call(action) ?? BeamingRecoveryDecision.proceed;
    _emit(decision.name, action);

    if (decision == BeamingRecoveryDecision.skip) {
      return null;
    }

    try {
      final result = await operation();
      _emit('succeeded', action);
      return result;
    } catch (error) {
      _emit(
        'failed',
        action,
        <String, Object?>{
          'error': error.toString(),
        },
      );
      rethrow;
    }
  }

  void _emit(
    String actionName,
    BeamingRecoveryAction action, [
    Map<String, Object?> extraDetails = const <String, Object?>{},
  ]) {
    final hook = diagnosticsHook;
    if (hook == null) {
      return;
    }
    try {
      hook(
        _diagnosticsRedactor(
          BeamingDiagnosticEvent(
            kind: BeamingDiagnosticEventKind.recovery,
            action: actionName,
            details: <String, Object?>{
              'recoveryKind': action.kind.name,
              'rootKeyIds': action.rootKeyIds,
              'attempt': action.attempt,
              'reason': action.reason,
              ...extraDetails,
            },
          ),
        ),
      );
    } catch (_) {
      // Diagnostics must not break recovery behavior.
    }
  }
}

BeamingDiagnosticEvent _identityRecoveryEvent(BeamingDiagnosticEvent event) =>
    event;
