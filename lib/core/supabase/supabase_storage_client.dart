import 'package:universal_io/io.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'supabase_config.dart';

/// Abstrakcia Supabase Storage pre bločky (bucket `receipts`).
abstract class SupabaseStorageClient {
  Future<String> uploadReceipt({
    required String userId,
    required File file,
    required String fileName,
  });

  Future<void> deleteReceipt(String urlOrPath);

  factory SupabaseStorageClient.fromSupabase(SupabaseClient? client) {
    if (client == null) return _UnavailableSupabaseStorageClient();
    return _LiveSupabaseStorageClient(client);
  }
}

class _UnavailableSupabaseStorageClient implements SupabaseStorageClient {
  @override
  Future<void> deleteReceipt(String urlOrPath) async {}

  @override
  Future<String> uploadReceipt({
    required String userId,
    required File file,
    required String fileName,
  }) async {
    throw Exception('Supabase storage not configured');
  }
}

class _LiveSupabaseStorageClient implements SupabaseStorageClient {
  _LiveSupabaseStorageClient(this._client);

  final SupabaseClient _client;
  static const _bucket = 'receipts';

  String _objectPath(String userId, String fileName) => '$userId/$fileName';

  String? _pathFromReference(String urlOrPath) {
    if (urlOrPath.isEmpty) return null;
    if (!urlOrPath.contains('://')) return urlOrPath;

    final uri = Uri.tryParse(urlOrPath);
    if (uri == null) return null;

    final segments = uri.pathSegments;
    final bucketIndex = segments.indexOf(_bucket);
    if (bucketIndex >= 0 && bucketIndex + 1 < segments.length) {
      return segments.sublist(bucketIndex + 1).join('/');
    }

    final marker = '/$_bucket/';
    final idx = urlOrPath.indexOf(marker);
    if (idx >= 0) {
      return urlOrPath.substring(idx + marker.length).split('?').first;
    }
    return null;
  }

  @override
  Future<void> deleteReceipt(String urlOrPath) async {
    final path = _pathFromReference(urlOrPath);
    if (path == null || path.isEmpty) return;
    await _client.storage.from(_bucket).remove([path]);
  }

  @override
  Future<String> uploadReceipt({
    required String userId,
    required File file,
    required String fileName,
  }) async {
    final path = _objectPath(userId, fileName);
    await _client.storage.from(_bucket).upload(
          path,
          file,
          fileOptions: const FileOptions(
            contentType: 'image/jpeg',
            upsert: false,
          ),
        );

    final signed = await _client.storage.from(_bucket).createSignedUrl(
          path,
          60 * 60 * 24 * 365,
        );
    return signed;
  }
}

final supabaseStorageClientProvider = Provider<SupabaseStorageClient>((ref) {
  return SupabaseStorageClient.fromSupabase(
    SupabaseConfig.isReady ? SupabaseConfig.client : null,
  );
});
