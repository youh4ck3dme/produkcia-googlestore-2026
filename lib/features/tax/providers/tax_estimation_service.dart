import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../invoices/providers/invoices_provider.dart';
import '../../expenses/providers/expenses_provider.dart';
import '../../settings/providers/settings_provider.dart';
import '../../invoices/models/invoice_model.dart';

class TaxEstimationModel {
  final double ytdRevenue;
  final double ytdExpenses;
  final double estimatedIncomeTax;
  final double estimatedVatLiability;
  final double vatTurnoverLtm;
  final bool isVatPayer;
  final double netProfit;

  TaxEstimationModel({
    required this.ytdRevenue,
    required this.ytdExpenses,
    required this.estimatedIncomeTax,
    required this.estimatedVatLiability,
    required this.vatTurnoverLtm,
    required this.isVatPayer,
    required this.netProfit,
  });

  factory TaxEstimationModel.empty() => TaxEstimationModel(
    ytdRevenue: 0,
    ytdExpenses: 0,
    estimatedIncomeTax: 0,
    estimatedVatLiability: 0,
    vatTurnoverLtm: 0,
    isVatPayer: false,
    netProfit: 0,
  );
}

final taxEstimationProvider = Provider<AsyncValue<TaxEstimationModel>>((ref) {
  final invoicesAsync = ref.watch(invoicesProvider);
  final expensesAsync = ref.watch(expensesProvider);
  final settings = ref.watch(settingsProvider).valueOrNull;

  return invoicesAsync.when(
    loading: () => const AsyncValue.loading(),
    error: (err, stack) => AsyncValue.error(err, stack),
    data: (invoices) {
      return expensesAsync.when(
        loading: () => const AsyncValue.loading(),
        error: (err, stack) => AsyncValue.error(err, stack),
        data: (expenses) {
          final now = DateTime.now();
          final startOfYear = DateTime(now.year, 1, 1);
          final startOfLtm = now.subtract(const Duration(days: 365));

          // 1. YTD Revenue & Expenses
          final ytdInvoices = invoices.where((i) => 
            i.dateIssued.isAfter(startOfYear.subtract(const Duration(days: 1))) && 
            i.status != InvoiceStatus.draft && 
            i.status != InvoiceStatus.cancelled
          );
          
          final ytdExpensesList = expenses.where((e) => 
            e.date.isAfter(startOfYear.subtract(const Duration(days: 1)))
          );

          final revenue = ytdInvoices.fold(0.0, (sum, i) => sum + i.totalAmount);
          final costs = ytdExpensesList.fold(0.0, (sum, e) => sum + e.amount);
          final profit = revenue - costs;

          // 2. VAT Turnover (LTM)
          final ltmInvoices = invoices.where((i) => 
            i.dateIssued.isAfter(startOfLtm) && 
            i.status != InvoiceStatus.draft && 
            i.status != InvoiceStatus.cancelled
          );
          final vatTurnover = ltmInvoices.fold(0.0, (sum, i) => sum + i.totalAmount);

          // 3. Tax Estimates
          // Simplified: 15% income tax on profit for small business
          final double incomeTax = profit > 0 ? profit * 0.15 : 0;
          
          // VAT Estimate: Assume 20% rate if payer
          final double vatLiability;
          final isVatPayer = settings?.isVatPayer ?? false;
          if (isVatPayer) {
             // In Slovakia, for a simplified estimate: (Output VAT - Input VAT)
             // We estimate based on total amounts (gross / 1.2 * 0.2)
             final double outputVat = (revenue / 1.2) * 0.2;
             final double inputVat = (costs / 1.2) * 0.2;
             vatLiability = outputVat - inputVat;
          } else {
            vatLiability = 0;
          }

          return AsyncValue.data(TaxEstimationModel(
            ytdRevenue: revenue,
            ytdExpenses: costs,
            estimatedIncomeTax: incomeTax,
            estimatedVatLiability: vatLiability,
            vatTurnoverLtm: vatTurnover,
            isVatPayer: isVatPayer,
            netProfit: profit,
          ));
        },
      );
    },
  );
});
