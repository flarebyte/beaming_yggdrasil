/// purpose: Provide one small client-visible error model so validation and
/// protocol failures are reported consistently across the package.
///
/// responsibilities: Enumerate error kinds and carry structured exception data
/// for request, response, state, and protocol failures.
///
/// architecture notes: This replaces ad hoc exception types so callers and
/// tests can reason about failures without transport-specific exception
/// parsing.
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
