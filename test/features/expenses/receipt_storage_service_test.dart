import 'dart:io';

import 'package:bizagent/core/supabase/supabase_storage_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bizagent/features/auth/providers/auth_repository.dart';
import 'package:bizagent/features/auth/models/user_model.dart';
import 'package:bizagent/features/expenses/services/receipt_storage_service.dart';

class FakeSupabaseStorageClient implements SupabaseStorageClient {
  FakeSupabaseStorageClient({this.shouldFailUpload = false});

  bool shouldFailUpload;
  final List<String> uploadedPaths = [];
  final List<String> deletedReferences = [];

  @override
  Future<void> deleteReceipt(String urlOrPath) async {
    if (urlOrPath.contains('fail-delete')) {
      throw Exception('Simulated delete failure');
    }
    deletedReferences.add(urlOrPath);
  }

  @override
  Future<String> uploadReceipt({
    required String userId,
    required File file,
    required String fileName,
  }) async {
    if (shouldFailUpload) throw Exception('Simulated upload failure');
    final objectPath = '$userId/$fileName';
    uploadedPaths.add(objectPath);
    return 'https://example.supabase.co/storage/v1/object/sign/receipts/$objectPath?token=fake';
  }
}

void main() {
  group('ReceiptStorageService', () {
    late FakeSupabaseStorageClient fakeStorage;

    setUp(() {
      fakeStorage = FakeSupabaseStorageClient();
    });

    group('uploadReceipt - Authentication & Validation', () {
      test('throws when user is not logged in', () async {
        final container = ProviderContainer(
          overrides: [
            supabaseStorageClientProvider.overrideWithValue(fakeStorage),
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
            supabaseStorageClientProvider.overrideWithValue(fakeStorage),
            authStateProvider.overrideWith((ref) => Stream.value(user)),
          ],
        );
        addTearDown(container.dispose);

        await container.read(authStateProvider.future);
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
            supabaseStorageClientProvider.overrideWithValue(fakeStorage),
            authStateProvider.overrideWith((ref) => Stream.value(user)),
          ],
        );
        addTearDown(container.dispose);

        await container.read(authStateProvider.future);
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
      test('uploads to user-scoped Supabase path', () async {
        const user = UserModel(id: 'user123', email: 'test@example.com');
        final container = ProviderContainer(
          overrides: [
            supabaseStorageClientProvider.overrideWithValue(fakeStorage),
            authStateProvider.overrideWith((ref) => Stream.value(user)),
          ],
        );
        addTearDown(container.dispose);

        await container.read(authStateProvider.future);
        final tempDir = await Directory.systemTemp.createTemp('receipt_test');
        addTearDown(() => tempDir.deleteSync(recursive: true));
        final file = File('${tempDir.path}/receipt.jpg');
        await file.writeAsString('fake image content');

        final service = container.read(receiptStorageServiceProvider);
        final url = await service.uploadReceipt(file.path);

        expect(url, contains('receipts/user123/'));
        expect(fakeStorage.uploadedPaths.single, startsWith('user123/'));
      });

      test('rethrows on storage failure', () async {
        fakeStorage.shouldFailUpload = true;
        const user = UserModel(id: 'user123', email: 'test@example.com');
        final container = ProviderContainer(
          overrides: [
            supabaseStorageClientProvider.overrideWithValue(fakeStorage),
            authStateProvider.overrideWith((ref) => Stream.value(user)),
          ],
        );
        addTearDown(container.dispose);

        await container.read(authStateProvider.future);
        final tempDir = await Directory.systemTemp.createTemp('receipt_test');
        addTearDown(() => tempDir.deleteSync(recursive: true));
        final file = File('${tempDir.path}/receipt.jpg');
        await file.writeAsString('fake image content');

        final service = container.read(receiptStorageServiceProvider);

        await expectLater(
          service.uploadReceipt(file.path),
          throwsA(anything),
        );
      });
    });

    group('deleteReceipt - Error Handling', () {
      test('does not throw on invalid URL (handles errors gracefully)', () async {
        final container = ProviderContainer(
          overrides: [
            supabaseStorageClientProvider.overrideWithValue(fakeStorage),
          ],
        );
        addTearDown(container.dispose);

        final service = container.read(receiptStorageServiceProvider);

        await expectLater(
          service.deleteReceipt('https://invalid-or-missing-url.example.com/file'),
          completes,
        );
      });

      test('does not throw on empty URL', () async {
        final container = ProviderContainer(
          overrides: [
            supabaseStorageClientProvider.overrideWithValue(fakeStorage),
          ],
        );
        addTearDown(container.dispose);

        final service = container.read(receiptStorageServiceProvider);

        await expectLater(
          service.deleteReceipt(''),
          completes,
        );
      });

      test('does not throw when backend delete fails', () async {
        final container = ProviderContainer(
          overrides: [
            supabaseStorageClientProvider.overrideWithValue(fakeStorage),
          ],
        );
        addTearDown(container.dispose);

        final service = container.read(receiptStorageServiceProvider);

        await expectLater(
          service.deleteReceipt('fail-delete'),
          completes,
        );
      });
    });
  });
}
