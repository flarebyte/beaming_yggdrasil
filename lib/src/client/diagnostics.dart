/// purpose: Define the structured diagnostics hook contract so callers can
/// observe library activity without committing the package to a logging
/// framework.
///
/// responsibilities: Describe diagnostic event types, event payloads, and
/// optional hook and redaction signatures.
///
/// architecture notes: Diagnostics are intentionally generic and side-effect
/// free so observability can evolve outside the core client package.
/// Optional structured diagnostics hook.
typedef BeamingDiagnosticsHook = void Function(BeamingDiagnosticEvent event);

/// Optional redaction hook applied before diagnostics leave the library.
typedef BeamingDiagnosticsRedactor = BeamingDiagnosticEvent Function(
  BeamingDiagnosticEvent event,
);

/// Kinds of diagnostic activity the package can emit.
enum BeamingDiagnosticEventKind {
  request,
  session,
  error,
  recovery,
}

/// Structured diagnostics payload passed to hooks.
class BeamingDiagnosticEvent {
  final BeamingDiagnosticEventKind kind;
  final String action;
  final Map<String, Object?> details;

  const BeamingDiagnosticEvent({
    required this.kind,
    required this.action,
    required this.details,
  });

  /// Returns a copy with selected fields replaced.
  BeamingDiagnosticEvent copyWith({
    BeamingDiagnosticEventKind? kind,
    String? action,
    Map<String, Object?>? details,
  }) {
    return BeamingDiagnosticEvent(
      kind: kind ?? this.kind,
      action: action ?? this.action,
      details: details ?? this.details,
    );
  }
}
