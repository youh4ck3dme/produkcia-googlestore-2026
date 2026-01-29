import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../invoices/providers/invoices_repository.dart';
import '../../invoices/models/invoice_model.dart';
import '../models/invoice_like.dart';

final invoiceLikeRepoProvider =
    StreamProvider.family<List<InvoiceLike>, String>((ref, userId) {
  final repo = ref.watch(invoicesRepositoryProvider);
  return repo
      .watchInvoices(userId)
      .map((items) => items.map(_mapInvoice).toList());
});

InvoiceLike _mapInvoice(InvoiceModel inv) {
  return InvoiceLike(
    id: inv.id,
    number: inv.number,
    variableSymbol: inv.variableSymbol ?? '',
    total: inv.totalAmount, // Use totalAmount from InvoiceModel
    clientName: inv.clientName,
  );
}
