import 'package:flutter_test/flutter_test.dart';

import 'package:bizagent/core/supabase/auth_backend.dart';
import 'package:bizagent/core/supabase/supabase_config.dart';
import 'package:bizagent/core/supabase/supabase_table_store.dart';
import 'package:bizagent/features/auth/providers/auth_repository.dart';
import 'package:bizagent/features/invoices/models/invoice_model.dart';
import 'package:bizagent/features/invoices/providers/invoices_repository.dart';

import '../../helpers/memory_local_persistence.dart';
import '../../helpers/test_supabase.dart';

/// Live Supabase integration tests — bežia len v CI s GitHub Secrets
/// alebo lokálne s `dart_defines/supabase.json`.
void main() {
  // flutter test blokuje HTTP (400 mock) — live testy cez scripts/verify_supabase_live.sh
  const skipLive = bool.fromEnvironment('SKIP_SUPABASE_LIVE', defaultValue: true);

  setUpAll(() async {
    if (skipLive) return;
    await ensureTestSupabase();
  });

  group('Supabase live integration', () {
    test('auth sign-in with test user', () async {
      if (skipLive || !SupabaseConfig.isConfigured) {
        return;
      }

      const email = String.fromEnvironment('SUPABASE_TEST_USER_EMAIL');
      const password = String.fromEnvironment('SUPABASE_TEST_USER_PASSWORD');
      if (email.isEmpty || password.isEmpty) return;

      final repo = AuthRepository(
        AuthBackend.fromClient(SupabaseConfig.client),
      );

      final user = await repo.signIn(email, password);
      expect(user, isNotNull);
      expect(user!.email, email);

      await repo.signOut();
    }, skip: skipLive ? 'SKIP_SUPABASE_LIVE=true' : null);

    test('invoice CRUD round-trip', () async {
      if (skipLive || !SupabaseConfig.isConfigured) return;

      const email = String.fromEnvironment('SUPABASE_TEST_USER_EMAIL');
      const password = String.fromEnvironment('SUPABASE_TEST_USER_PASSWORD');
      if (email.isEmpty || password.isEmpty) return;

      final auth = AuthRepository(AuthBackend.fromClient(SupabaseConfig.client));
      final user = await auth.signIn(email, password);
      expect(user, isNotNull);

      final persistence = MemoryLocalPersistenceService();
      final invoices = InvoicesRepository(
        SupabaseTableStore.fromClient(SupabaseConfig.client),
        persistence,
      );

      final invoice = InvoiceModel(
        id: 'ci-test-${DateTime.now().millisecondsSinceEpoch}',
        userId: user!.id,
        createdAt: DateTime.now(),
        number: 'CI-TEST-001',
        clientName: 'CI Client',
        dateIssued: DateTime.now(),
        dateDue: DateTime.now().add(const Duration(days: 14)),
        items: const [],
        totalAmount: 0,
        status: InvoiceStatus.draft,
      );

      await invoices.addInvoice(user.id, invoice);
      final loaded = await invoices.getInvoices(user.id);
      expect(loaded.any((i) => i.id == invoice.id), isTrue);

      await invoices.deleteInvoice(user.id, invoice.id);
      await auth.signOut();
    }, skip: skipLive ? 'SKIP_SUPABASE_LIVE=true' : null);
  });
}
