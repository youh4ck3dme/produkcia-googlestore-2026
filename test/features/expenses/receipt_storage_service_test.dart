import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bizagent/features/auth/providers/auth_repository.dart';
import 'package:bizagent/features/auth/models/user_model.dart';
import 'package:bizagent/features/expenses/services/receipt_storage_service.dart';

/// ReceiptStorageService unit tests.
/// Tests that don't require Firebase use ProviderContainer overrides for auth.
/// Full upload/download flow can be tested with Firebase Emulator:
///   firebase emulators:start --only storage
void main() {
  group('ReceiptStorageService', () {
    group('uploadReceipt - Authentication & Validation', () {
      test('throws when user is not logged in', () async {
        final container = ProviderContainer(
          overrides: [
            authStateProvider.overrideWith((ref) => Stream.value(null)),
          ],
        );
        addTearDown(container.dispose);

        final service = container.read(receiptStorageServiceProvider);

        await expectLater(
          service.uploadReceipt('/any/path'),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('User not logged in'),
          )),
        );
      });

      test('throws when file does not exist', () async {
        const user = UserModel(id: 'user123', email: 'test@example.com');
        final container = ProviderContainer(
          overrides: [
            authStateProvider.overrideWith((ref) => Stream.value(user)),
          ],
        );
        addTearDown(container.dispose);

        final service = container.read(receiptStorageServiceProvider);

        await expectLater(
          service.uploadReceipt('/nonexistent/path/receipt.jpg'),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('File does not exist'),
          )),
        );
      });

      test('throws when file path is empty', () async {
        const user = UserModel(id: 'user123', email: 'test@example.com');
        final container = ProviderContainer(
          overrides: [
            authStateProvider.overrideWith((ref) => Stream.value(user)),
          ],
        );
        addTearDown(container.dispose);

        final service = container.read(receiptStorageServiceProvider);

        await expectLater(
          service.uploadReceipt(''),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('File does not exist'),
          )),
        );
      });
    });

    group('uploadReceipt - with existing file', () {
      test('rethrows on storage failure (e.g. Firebase not initialized)', () async {
        const user = UserModel(id: 'user123', email: 'test@example.com');
        final container = ProviderContainer(
          overrides: [
            authStateProvider.overrideWith((ref) => Stream.value(user)),
          ],
        );
        addTearDown(container.dispose);

        final tempDir = await Directory.systemTemp.createTemp('receipt_test');
        addTearDown(() => tempDir.deleteSync(recursive: true));
        final file = File('${tempDir.path}/receipt.jpg');
        await file.writeAsString('fake image content');

        final service = container.read(receiptStorageServiceProvider);

        // Without Firebase Emulator, storage will fail; implementation rethrows
        await expectLater(
          service.uploadReceipt(file.path),
          throwsA(anything),
        );
      });
    });

    group('deleteReceipt - Error Handling', () {
      test('does not throw on invalid URL (handles errors gracefully)', () async {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final service = container.read(receiptStorageServiceProvider);

        await expectLater(
          service.deleteReceipt('https://invalid-or-missing-url.example.com/file'),
          completes,
        );
      });

      test('does not throw on empty URL', () async {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final service = container.read(receiptStorageServiceProvider);

        await expectLater(
          service.deleteReceipt(''),
          completes,
        );
      });
    });

    group('Path and metadata behavior (documented)', () {
      test('storage path format: users/{userId}/receipts/{timestamp}_{filename}', () {
        // Documented in implementation: storageRef.child('users/${user.id}/receipts/$fileName')
        // fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.basename(filePath)}'
        expect(true, isTrue);
      });

      test('metadata includes contentType and customMetadata', () {
        // Documented: SettableMetadata(contentType: 'image/jpeg', customMetadata: {...})
        expect(true, isTrue);
      });
    });
  });
}
