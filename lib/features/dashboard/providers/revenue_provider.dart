import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../invoices/providers/invoices_provider.dart';
import '../../invoices/models/invoice_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'revenue_provider.g.dart';

class RevenueMetrics {
  final double totalRevenue;
  final double thisMonthRevenue;
  final double lastMonthRevenue;
  final double unpaidAmount;
  final int overdueCount;
  final double averageInvoiceValue;

  RevenueMetrics({
    required this.totalRevenue,
    required this.thisMonthRevenue,
    required this.lastMonthRevenue,
    required this.unpaidAmount,
    required this.overdueCount,
    required this.averageInvoiceValue,
  });
}

@riverpod
Future<RevenueMetrics> revenueMetrics(Ref ref) async {
  final invoicesAsync = ref.watch(invoicesProvider);
  final invoices = invoicesAsync.value ?? [];

  final now = DateTime.now();
  final thisMonthStart = DateTime(now.year, now.month, 1);
  final lastMonthStart = DateTime(now.year, now.month - 1, 1);
  final thisMonthInvoices = invoices.where((inv) => inv.dateIssued
      .isAfter(thisMonthStart.subtract(const Duration(seconds: 1))));

  final lastMonthInvoices = invoices.where((inv) =>
      inv.dateIssued
          .isAfter(lastMonthStart.subtract(const Duration(seconds: 1))) &&
      inv.dateIssued.isBefore(thisMonthStart));

  final totalRevenue = invoices.fold(0.0, (sum, inv) => sum + inv.totalAmount);
  final thisMonthRevenue =
      thisMonthInvoices.fold(0.0, (sum, inv) => sum + inv.totalAmount);
  final lastMonthRevenue =
      lastMonthInvoices.fold(0.0, (sum, inv) => sum + inv.totalAmount);

  final unpaidAmount = invoices
      .where((inv) =>
          inv.status == InvoiceStatus.sent ||
          inv.status == InvoiceStatus.overdue)
      .fold(0.0, (sum, inv) => sum + inv.totalAmount);

  final overdueCount = invoices
      .where((inv) =>
          (inv.status == InvoiceStatus.overdue) ||
          (inv.status == InvoiceStatus.sent && inv.dateDue.isBefore(now)))
      .length;

  final averageInvoiceValue =
      invoices.isEmpty ? 0.0 : totalRevenue / invoices.length;

  return RevenueMetrics(
    totalRevenue: totalRevenue,
    thisMonthRevenue: thisMonthRevenue,
    lastMonthRevenue: lastMonthRevenue,
    unpaidAmount: unpaidAmount,
    overdueCount: overdueCount,
    averageInvoiceValue: averageInvoiceValue,
  );
}
