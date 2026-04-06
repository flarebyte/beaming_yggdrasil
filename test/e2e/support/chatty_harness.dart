import 'dart:async';
import 'dart:convert';
import 'dart:io';

final String _chattyRepoDir =
    Platform.environment['CHATTY_REPO_DIR'] ?? '../chatty-ratatoskr';

final String _chattyBinaryPath = Platform.environment['CHATTY_BINARY_PATH'] ??
    '$_chattyRepoDir/.e2e-bin/chatty';

class ChattyResponse {
  final int statusCode;
  final String body;

  const ChattyResponse({
    required this.statusCode,
    required this.body,
  });
}

class ChattyHarness {
  final String baseUrl;
  final String eventsUrl;
  final Process _process;

  ChattyHarness._({
    required this.baseUrl,
    required this.eventsUrl,
    required Process process,
  }) : _process = process;

  static bool isAvailable() {
    return File(_chattyBinaryPath).existsSync();
  }

  static Future<ChattyHarness?> start({
    bool websocketEnabled = false,
  }) async {
    if (!isAvailable()) {
      return null;
    }
    final port = await _allocatePort();
    if (port == null) {
      return null;
    }
    final listen = '127.0.0.1:$port';
    final arguments = <String>[
      'serve',
      '--listen',
      listen,
      if (websocketEnabled) ...[
        '--config',
        '$_chattyRepoDir/testdata/config/basic.cue',
      ],
    ];
    final process = await Process.start(
      _chattyBinaryPath,
      arguments,
      workingDirectory: _chattyRepoDir,
    );
    final harness = ChattyHarness._(
      baseUrl: 'http://$listen',
      eventsUrl: 'ws://$listen/events',
      process: process,
    );
    final ready = await harness._waitForReady();
    if (!ready) {
      await harness.stop();
      return null;
    }
    return harness;
  }

  Future<ChattyResponse> requestJson(
    String method,
    String path, {
    Map<String, Object?>? jsonBody,
  }) async {
    final client = HttpClient();
    try {
      final request = await client.openUrl(
        method,
        Uri.parse('$baseUrl$path'),
      );
      request.headers.contentType = ContentType.json;
      if (jsonBody != null) {
        request.write(jsonEncode(jsonBody));
      }
      final response = await request.close();
      final body = await utf8.decodeStream(response);
      return ChattyResponse(
        statusCode: response.statusCode,
        body: body,
      );
    } finally {
      client.close(force: true);
    }
  }

  Future<void> stop() async {
    _process.kill(ProcessSignal.sigterm);
    final exited = await Future.any<bool>([
      _process.exitCode.then((_) => true),
      Future<bool>.delayed(const Duration(seconds: 2), () => false),
    ]);
    if (!exited) {
      _process.kill(ProcessSignal.sigkill);
      await _process.exitCode;
    }
  }

  Future<bool> _waitForReady() async {
    final deadline = DateTime.now().add(const Duration(seconds: 10));
    while (DateTime.now().isBefore(deadline)) {
      try {
        final response = await requestJson('GET', '/snapshot');
        if (response.statusCode >= 200) {
          return true;
        }
      } on SocketException {
        // Ignore while the process is still starting.
      } on ProcessException {
        return false;
      }
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    return false;
  }

  static Future<int?> _allocatePort() async {
    try {
      final socket = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      final port = socket.port;
      await socket.close();
      return port;
    } on SocketException {
      return null;
    }
  }
}
