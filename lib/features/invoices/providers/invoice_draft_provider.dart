// lib/features/invoices/providers/invoice_draft_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/tax_calculation_service.dart';
import '../models/invoice_model.dart';

class InvoiceDraftState {
  InvoiceDraftState({
    required this.items,
  });

  final List<InvoiceItemModel> items;

  InvoiceDraftState copyWith({List<InvoiceItemModel>? items}) {
    return InvoiceDraftState(items: items ?? this.items);
  }
}

final taxServiceProvider = Provider((_) => TaxCalculationService());

final invoiceDraftProvider =
    StateNotifierProvider<InvoiceDraftController, InvoiceDraftState>(
  (ref) => InvoiceDraftController(ref),
);

class InvoiceDraftController extends StateNotifier<InvoiceDraftState> {
  InvoiceDraftController(this._ref) : super(InvoiceDraftState(items: []));

  final Ref _ref;

  TaxTotals get totals {
    final tax = _ref.read(taxServiceProvider);
    final lines = state.items.map((it) => it.toTaxLine(tax));
    return tax.calcTotals(lines);
  }

  void addItem(InvoiceItemModel item) {
    state = state.copyWith(items: [...state.items, item]);
  }

  void updateItemVat(int index, double vatRate) {
    final items = [...state.items];
    final old = items[index];
    items[index] = InvoiceItemModel(
        title: old.title, amount: old.amount, vatRate: vatRate);
    state = state.copyWith(items: items);
  }

  void updateItemAmount(int index, double amount) {
    final items = [...state.items];
    final old = items[index];
    items[index] = InvoiceItemModel(
        title: old.title, amount: amount, vatRate: old.vatRate);
    state = state.copyWith(items: items);
  }
}
