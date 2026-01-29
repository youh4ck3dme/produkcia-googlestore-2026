import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../invoices/models/invoice_model.dart';
import '../../invoices/providers/invoices_repository.dart';
import '../models/invoice_like.dart';

/// "Firestore provider" je v praxi napojeny na existujuci InvoicesRepository.
/// (uprav mapovanie fieldov ked budes chciet 100% presnost)
final invoiceLikeFirestoreProvider =
    StreamProvider.family<List<InvoiceLike>, String>((ref, userId) {
  final repo = ref.watch(invoicesRepositoryProvider);
  return repo
      .watchInvoices(userId)
      .map((items) => items.map(_mapInvoice).toList());
});

InvoiceLike _mapInvoice(InvoiceModel inv) {
  // tieto fieldy su najcastejsie v tvojom invoice modele – ak sa lisia, uprav iba tu mapu.
  final number = inv.number.toString();
  final vs = (inv.variableSymbol ?? '').toString();
  final total = inv.totalAmount.toDouble();

  // klient: clientName je priamo v InvoiceModel
  final clientName = inv.clientName.toString();

  return InvoiceLike(
    id: inv.id,
    number: number,
    variableSymbol: vs,
    total: total,
    clientName: clientName,
  );
}
