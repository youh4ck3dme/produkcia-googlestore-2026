import 'package:universal_io/io.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;

import '../../auth/providers/auth_repository.dart';
import '../../../core/supabase/supabase_storage_client.dart';

final receiptStorageServiceProvider = Provider<ReceiptStorageService>((ref) {
  return ReceiptStorageService(
    ref,
    ref.read(supabaseStorageClientProvider),
  );
});

class ReceiptStorageService {
  final Ref _ref;
  final SupabaseStorageClient _storage;

  ReceiptStorageService(this._ref, this._storage);

  Future<String?> uploadReceipt(String filePath) async {
    try {
      final user = _ref.read(authStateProvider).value;
      if (user == null) throw Exception('User not logged in');

      final file = File(filePath);
      if (!file.existsSync()) {
        throw Exception('File does not exist');
      }

      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${path.basename(filePath)}';

      final downloadUrl = await _storage.uploadReceipt(
        userId: user.id,
        file: file,
        fileName: fileName,
      );

      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading receipt: $e');
      rethrow;
    }
  }

  Future<void> deleteReceipt(String downloadUrl) async {
    try {
      await _storage.deleteReceipt(downloadUrl);
    } catch (e) {
      debugPrint('Error deleting receipt: $e');
      // Don't rethrow, just log. It's not critical if delete fails.
    }
  }
}
