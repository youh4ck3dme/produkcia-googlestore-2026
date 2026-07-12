import 'dart:convert';
import 'dart:io' show File, FileMode;

import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;

const _logPath =
    '/Users/erikbabcan/Projects/02_Products/bizagent/.cursor/debug-6933f9.log';

/// Lightweight NDJSON perf probe for debug sessions.
void perfProbe(
  String hypothesisId,
  String location,
  String message, [
  Map<String, Object?> data = const {},
]) {
  // #region agent log
  debugPrint('[perf:$hypothesisId] $location — $message $data');
  if (kIsWeb) return;
  try {
    File(_logPath).writeAsStringSync(
      '${jsonEncode({
        'sessionId': '6933f9',
        'hypothesisId': hypothesisId,
        'location': location,
        'message': message,
        'data': data,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      })}\n',
      mode: FileMode.append,
    );
  } catch (_) {}
  // #endregion
}
