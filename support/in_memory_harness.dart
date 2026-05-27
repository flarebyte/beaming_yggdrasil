/// purpose: Provide a non-production in-memory harness that exercises the
/// public client contracts for tests and examples.
///
/// responsibilities: Bind the harness API, fake clients, fake WebSocket
/// session, and mutable support state into one support-only library.
///
/// architecture notes: This support library intentionally stays outside `lib/`
/// so it can help tests and examples without becoming part of the published
/// runtime API.
library;

import 'dart:async';

import 'package:beaming_yggdrasil/beaming_yggdrasil.dart';

part 'in_memory_harness_api.dart';
part 'in_memory_harness_clients.dart';
part 'in_memory_harness_state.dart';
