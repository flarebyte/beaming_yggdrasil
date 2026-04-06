/// Optional structured diagnostics hook.
typedef BeamingDiagnosticsHook = void Function(BeamingDiagnosticEvent event);

/// Optional redaction hook applied before diagnostics leave the library.
typedef BeamingDiagnosticsRedactor = BeamingDiagnosticEvent Function(
  BeamingDiagnosticEvent event,
);

enum BeamingDiagnosticEventKind {
  request,
  session,
  error,
  recovery,
}

class BeamingDiagnosticEvent {
  final BeamingDiagnosticEventKind kind;
  final String action;
  final Map<String, Object?> details;

  const BeamingDiagnosticEvent({
    required this.kind,
    required this.action,
    required this.details,
  });

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
