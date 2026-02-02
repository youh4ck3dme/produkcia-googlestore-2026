import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Minimal debug-mode logger for mobile runtime diagnostics.
///
/// IMPORTANT:
/// - Do NOT log secrets (tokens, passwords) or PII.
/// - Intended to send NDJSON-like events to the local debug ingest via `adb reverse`.
Future<void> agentLog({
  required String hypothesisId,
  required String location,
  required String message,
  Map<String, Object?> data = const {},
  String sessionId = 'debug-session',
  String runId = 'run1',
}) async {
  // Never attempt local debug ingestion in release builds.
  if (kReleaseMode) return;
  try {
    // Device will reach host via: `adb reverse tcp:7246 tcp:7246`
    final uri = Uri.parse(
      'http://127.0.0.1:7246/ingest/1dee0676-1231-4418-8757-c6e8de9d16ad',
    );
    await http.post(
      uri,
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'sessionId': sessionId,
        'runId': runId,
        'hypothesisId': hypothesisId,
        'location': location,
        'message': message,
        'data': data,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      }),
    );
  } catch (e) {
    // Best-effort logging only; do not throw in production flows.
    debugPrint('agentLog failed: ${e.runtimeType}: ${e.toString()}');
  }
}

