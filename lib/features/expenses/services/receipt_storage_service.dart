import 'package:universal_io/io.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;
import '../../auth/providers/auth_repository.dart';

final receiptStorageServiceProvider = Provider<ReceiptStorageService>((ref) {
  return ReceiptStorageService(ref);
});

class ReceiptStorageService {
  final Ref _ref;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  ReceiptStorageService(this._ref);

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
      final storageRef =
          _storage.ref().child('users/${user.id}/receipts/$fileName');

      // Upload file
      // Setup metadata if needed (e.g. content type)
      final metadata = SettableMetadata(
        contentType: 'image/jpeg', // Assuming jpeg mostly from camera
        customMetadata: {
          'uploadedBy': user.id,
          'originalName': path.basename(filePath),
        },
      );

      final uploadTask = await storageRef.putFile(file, metadata);
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading receipt: $e');
      rethrow;
    }
  }

  Future<void> deleteReceipt(String downloadUrl) async {
    try {
      final ref = _storage.refFromURL(downloadUrl);
      await ref.delete();
    } catch (e) {
      debugPrint('Error deleting receipt: $e');
      // Don't rethrow, just log. It's not critical if delete fails.
    }
  }
}
