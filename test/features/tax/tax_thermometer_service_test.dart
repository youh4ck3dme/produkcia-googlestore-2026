import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bizagent/features/invoices/models/invoice_model.dart';
import 'package:bizagent/features/invoices/providers/invoices_provider.dart';
import 'package:bizagent/features/tax/providers/tax_thermometer_service.dart';

void main() {
  group('TaxThermometerService', () {
    test('calculates turnover for last 12 months correctly', () async {
      final now = DateTime.now();
      final mockInvoices = [
        InvoiceModel(
            id: '1',
            userId: 'u',
            createdAt: now,
            number: '001',
            clientName: 'C',
            dateIssued: now,
            dateDue: now,
            items: [],
            totalAmount: 1000,
            status: InvoiceStatus.sent),
        InvoiceModel(
            id: '2',
            userId: 'u',
            createdAt: now.subtract(const Duration(days: 180)),
            number: '002',
            clientName: 'C',
            dateIssued: now.subtract(const Duration(days: 180)),
            dateDue: now,
            items: [],
            totalAmount: 2000,
            status: InvoiceStatus.paid),
        InvoiceModel(
            id: '3',
            userId: 'u',
            createdAt: now.subtract(const Duration(days: 364)),
            number: '003',
            clientName: 'C',
            dateIssued: now.subtract(const Duration(days: 364)),
            dateDue: now,
            items: [],
            totalAmount: 500,
            status: InvoiceStatus.sent),
        InvoiceModel(
            id: '4',
            userId: 'u',
            createdAt: now.subtract(const Duration(days: 366)),
            number: '004',
            clientName: 'C',
            dateIssued: now.subtract(const Duration(days: 366)),
            dateDue: now,
            items: [],
            totalAmount: 10000,
            status: InvoiceStatus.sent),
        InvoiceModel(
            id: '5',
            userId: 'u',
            createdAt: now,
            number: '005',
            clientName: 'C',
            dateIssued: now,
            dateDue: now,
            items: [],
            totalAmount: 5000,
            status: InvoiceStatus.cancelled),
      ];

      final container = ProviderContainer(
        overrides: [
          invoicesProvider.overrideWith((ref) => Stream.value(mockInvoices)),
        ],
      );

      final completer = Completer<TaxThermometerResult>();
      final sub = container.listen<AsyncValue<TaxThermometerResult>>(
        taxThermometerProvider,
        (previous, next) {
          if (next is AsyncData<TaxThermometerResult>) {
            if (!completer.isCompleted) completer.complete(next.value);
          }
        },
        fireImmediately: true,
      );

      final result = await completer.future.timeout(const Duration(seconds: 5));
      expect(result.currentTurnover, 3500.0);
      expect(result.isSafe, true);
      sub.close();
    });

    test('identifies critical status correctly', () async {
      final mockInvoices = [
        InvoiceModel(
            id: '1',
            userId: 'u',
            createdAt: DateTime.now(),
            number: '001',
            clientName: 'C',
            dateIssued: DateTime.now(),
            dateDue: DateTime.now(),
            items: [],
            totalAmount: 50000,
            status: InvoiceStatus.sent),
      ];

      final container = ProviderContainer(
        overrides: [
          invoicesProvider.overrideWith((ref) => Stream.value(mockInvoices)),
        ],
      );

      final completer = Completer<TaxThermometerResult>();
      final sub = container.listen<AsyncValue<TaxThermometerResult>>(
        taxThermometerProvider,
        (previous, next) {
          if (next is AsyncData<TaxThermometerResult>) {
            if (!completer.isCompleted) completer.complete(next.value);
          }
        },
        fireImmediately: true,
      );

      final result = await completer.future.timeout(const Duration(seconds: 5));
      expect(result.currentTurnover, 50000.0);
      expect(result.isCritical, true);
      sub.close();
    });

    test('identifies warning status correctly', () async {
      final mockInvoices = [
        InvoiceModel(
            id: '1',
            userId: 'u',
            createdAt: DateTime.now(),
            number: '001',
            clientName: 'C',
            dateIssued: DateTime.now(),
            dateDue: DateTime.now(),
            items: [],
            totalAmount: 40000,
            status: InvoiceStatus.sent),
      ];

      final container = ProviderContainer(
        overrides: [
          invoicesProvider.overrideWith((ref) => Stream.value(mockInvoices)),
        ],
      );

      final completer = Completer<TaxThermometerResult>();
      final sub = container.listen<AsyncValue<TaxThermometerResult>>(
        taxThermometerProvider,
        (previous, next) {
          if (next is AsyncData<TaxThermometerResult>) {
            if (!completer.isCompleted) completer.complete(next.value);
          }
        },
        fireImmediately: true,
      );

      final result = await completer.future.timeout(const Duration(seconds: 5));
      expect(result.currentTurnover, 40000.0);
      expect(result.isWarning, true);
      sub.close();
    });
  });
}
