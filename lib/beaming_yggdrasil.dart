library;

/// Pure Dart client primitives intended to embed cleanly inside Flutter apps.
///
/// Keep Flutter framework concepts out of this package so application code can
/// compose the client with its own widget tree and state-management approach.
export 'src/client/client.dart';
export 'src/client/model.dart';
export 'src/client/rx_client.dart';
export 'src/client/testing_client.dart';
