import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_repository.dart';
import '../models/invoice_model.dart';
import 'invoices_repository.dart';
import '../../../core/services/soft_delete_service.dart';
import '../../../core/services/local_persistence_service.dart';
import '../../../core/demo_mode/demo_mode_service.dart';

final invoicesProvider = StreamProvider<List<InvoiceModel>>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value([]);
  return ref.watch(invoicesRepositoryProvider).watchInvoices(user.id);
});

final invoicesControllerProvider =
    StateNotifierProvider<InvoicesController, AsyncValue<void>>((ref) {
  return InvoicesController(ref);
});

class InvoicesController extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  InvoicesController(this._ref) : super(const AsyncValue.data(null));

  Future<void> addInvoice(InvoiceModel invoice) async {
    final user = _ref.read(authStateProvider).valueOrNull;
    if (user == null) return;

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() =>
        _ref.read(invoicesRepositoryProvider).addInvoice(user.id, invoice));
  }

  Future<void> updateInvoice(InvoiceModel invoice) async {
    final user = _ref.read(authStateProvider).valueOrNull;
    if (user == null) return;

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() =>
        _ref.read(invoicesRepositoryProvider).updateInvoice(user.id, invoice));
  }

  Future<void> updateStatus(String invoiceId, InvoiceStatus status) async {
    final user = _ref.read(authStateProvider).valueOrNull;
    if (user == null) return;

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _ref
        .read(invoicesRepositoryProvider)
        .updateInvoiceStatus(user.id, invoiceId, status));
  }

  Future<void> softDeleteInvoice(String invoiceId, {String? reason}) async {
    final user = _ref.read(authStateProvider).valueOrNull;
    if (user == null) return;

    state = const AsyncValue.loading();
    if (DemoModeService.instance.isDemoMode) {
      state = await AsyncValue.guard(() async {
        final persistence = _ref.read(localPersistenceServiceProvider);
        final localData = persistence.getInvoices();
        final index = localData.indexWhere((inv) => inv['id'] == invoiceId);
        if (index != -1) {
          localData[index]['deletedAt'] = DateTime.now().toIso8601String();
          localData[index]['deleteReason'] = reason;
          await persistence.saveInvoice(invoiceId, localData[index]);
        }
      });
    } else {
      state = await AsyncValue.guard(() => _ref
          .read(softDeleteServiceProvider)
          .softDeleteItem(SoftDeleteCollections.invoices, user.id, invoiceId, reason: reason));
    }
  }

  Future<void> deleteInvoices(List<String> invoiceIds, {String? reason}) async {
    final user = _ref.read(authStateProvider).valueOrNull;
    if (user == null) return;

    state = const AsyncValue.loading();
    if (DemoModeService.instance.isDemoMode) {
      state = await AsyncValue.guard(() async {
        final persistence = _ref.read(localPersistenceServiceProvider);
        final localData = persistence.getInvoices();
        for (final id in invoiceIds) {
          final index = localData.indexWhere((inv) => inv['id'] == id);
          if (index != -1) {
            localData[index]['deletedAt'] = DateTime.now().toIso8601String();
            localData[index]['deleteReason'] = reason;
            await persistence.saveInvoice(id, localData[index]);
          }
        }
      });
    } else {
      state = await AsyncValue.guard(() async {
        final service = _ref.read(softDeleteServiceProvider);
        for (final id in invoiceIds) {
          await service.softDeleteItem(SoftDeleteCollections.invoices, user.id, id, reason: reason);
        }
      });
    }
  }

  // Legacy method for backward compatibility - now does soft delete
  Future<void> deleteInvoice(String invoiceId) async {
    await softDeleteInvoice(invoiceId);
  }
}
