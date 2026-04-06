/// purpose: Define the lightweight WebSocket protocol boundary so real-time
/// session messages can be encoded and decoded without hard-wiring a socket
/// implementation.
///
/// responsibilities: Bind the session interface, client messages, server
/// messages, event envelopes, and shared protocol helpers into one library.
///
/// architecture notes: This library stays intentionally thin and delegates the
/// wire details to focused part files so higher-level recovery and policy stay
/// outside the protocol layer.
library;

import 'dart:async';

import 'error.dart';
import 'model.dart';

part 'websocket_common.dart';
part 'websocket_session.dart';
part 'websocket_client_messages.dart';
part 'websocket_server_messages.dart';
part 'websocket_events.dart';
