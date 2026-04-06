/// Unified client-visible error kinds for validation and transport decoding.
enum BeamingClientErrorKind {
  invalidState,
  invalidRequest,
  invalidResponse,
  protocolViolation,
}

/// Small structured error used across the package instead of ad hoc exceptions.
class BeamingClientError implements Exception {
  final BeamingClientErrorKind kind;
  final String message;
  final Object? cause;

  const BeamingClientError({
    required this.kind,
    required this.message,
    this.cause,
  });

  @override
  String toString() {
    return 'BeamingClientError(kind: $kind, message: $message)';
  }
}
