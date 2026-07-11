import 'package:flutter/foundation.dart' show debugPrint;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:web/web.dart' as web;

/// Po Google OAuth na webe (hash routing `#/login`) app_links často nestihne
/// vymeniť `?code=` za session. Toto spustíme synchronne v main() pred runApp.
Future<void> recoverOAuthSessionFromBrowserUrl() async {
  final uri = Uri.base;
  if (!_isOAuthCallback(uri)) return;

  try {
    await Supabase.instance.client.auth.getSessionFromUrl(uri);
    _stripOAuthQueryFromBrowserUrl();
    debugPrint('OAuth callback: session recovered from URL');
  } on AuthException catch (e) {
    debugPrint('OAuth callback failed: ${e.message}');
    _stripOAuthQueryFromBrowserUrl();
    rethrow;
  } catch (e, st) {
    debugPrint('OAuth callback error: $e\n$st');
    rethrow;
  }
}

bool _isOAuthCallback(Uri uri) {
  return uri.queryParameters.containsKey('code') ||
      uri.queryParameters.containsKey('error') ||
      uri.queryParameters.containsKey('error_description');
}

void _stripOAuthQueryFromBrowserUrl() {
  final loc = web.window.location;
  final path = loc.pathname;
  final hash = loc.hash;
  web.window.history.replaceState(null, '', '$path$hash');
}