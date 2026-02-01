import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'dart:io';
import 'package:bizagent/core/services/local_persistence_service.dart';

void main() {
  group('LocalPersistenceService', () {
    late LocalPersistenceService service;
    late Directory tempDir;

    setUpAll(() async {
      // Use temp directory for testing
      tempDir = await Directory.systemTemp.createTemp('hive_test_');
      Hive.init(tempDir.path);
    });

    tearDownAll(() async {
      // Clean up temp directory
      await tempDir.delete(recursive: true);
    });

    setUp(() async {
      service = LocalPersistenceService();
      await service.init();
      await service.clearAll(); // Clean state before each test
    });

    tearDown(() async {
      await service.clearAll();
    });

    group('Invoices', () {
      test('should save and retrieve invoices', () async {
        // Arrange
        const invoiceId = 'invoice1';
        final invoiceData = {
          'number': '2026/001',
          'totalAmount': 1000.0,
          'clientName': 'Test Client',
        };

        // Act
        await service.saveInvoice(invoiceId, invoiceData);
        final invoices = service.getInvoices();

        // Assert
        expect(invoices.length, 1);
        expect(invoices.first['number'], '2026/001');
        expect(invoices.first['totalAmount'], 1000.0);
      });

      test('should delete invoice', () async {
        // Arrange
        const invoiceId = 'invoice1';
        await service.saveInvoice(invoiceId, {'number': '2026/001'});

        // Act
        await service.deleteInvoice(invoiceId);
        final invoices = service.getInvoices();

        // Assert
        expect(invoices.length, 0);
      });

      test('should clear all invoices', () async {
        // Arrange
        await service.saveInvoice('invoice1', {'number': '2026/001'});
        await service.saveInvoice('invoice2', {'number': '2026/002'});

        // Act
        await service.clearInvoices();
        final invoices = service.getInvoices();

        // Assert
        expect(invoices.length, 0);
      });

      test('should handle multiple invoices', () async {
        // Arrange
        await service.saveInvoice('invoice1', {'number': '2026/001'});
        await service.saveInvoice('invoice2', {'number': '2026/002'});
        await service.saveInvoice('invoice3', {'number': '2026/003'});

        // Act
        final invoices = service.getInvoices();

        // Assert
        expect(invoices.length, 3);
      });
    });

    group('Expenses', () {
      test('should save and retrieve expenses', () async {
        // Arrange
        const expenseId = 'expense1';
        final expenseData = {
          'description': 'Test Expense',
          'amount': 50.0,
          'category': 'Office',
        };

        // Act
        await service.saveExpense(expenseId, expenseData);
        final expenses = service.getExpenses();

        // Assert
        expect(expenses.length, 1);
        expect(expenses.first['description'], 'Test Expense');
        expect(expenses.first['amount'], 50.0);
      });

      test('should delete expense', () async {
        // Arrange
        const expenseId = 'expense1';
        await service.saveExpense(expenseId, {'description': 'Test'});

        // Act
        await service.deleteExpense(expenseId);
        final expenses = service.getExpenses();

        // Assert
        expect(expenses.length, 0);
      });
    });

    group('Settings', () {
      test('should save and retrieve setting', () async {
        // Arrange
        const key = 'test_setting';
        const value = 'test_value';

        // Act
        await service.saveSetting(key, value);
        final retrieved = service.getSetting(key);

        // Assert
        expect(retrieved, value);
      });

      test('should return default value when setting not found', () {
        // Act
        final value = service.getSetting('non_existent', defaultValue: 'default');

        // Assert
        expect(value, 'default');
      });

      test('should return null when setting not found and no default', () {
        // Act
        final value = service.getSetting('non_existent');

        // Assert
        expect(value, isNull);
      });

      test('should handle different data types', () async {
        // Test string
        await service.saveSetting('string_key', 'test');
        expect(service.getSetting('string_key'), 'test');

        // Test number
        await service.saveSetting('number_key', 123);
        expect(service.getSetting('number_key'), 123);

        // Test boolean
        await service.saveSetting('bool_key', true);
        expect(service.getSetting('bool_key'), true);

        // Test map
        await service.saveSetting('map_key', {'key': 'value'});
        expect(service.getSetting('map_key'), {'key': 'value'});
      });
    });

    group('Business Profile', () {
      test('should save and retrieve business profile', () async {
        // Arrange
        final profile = {
          'companyName': 'Test Company',
          'ico': '12345678',
          'dic': '2020123456',
          'address': 'Test Address',
        };

        // Act
        await service.saveBusinessProfile(profile);
        final retrieved = service.getBusinessProfile();

        // Assert
        expect(retrieved, isNotNull);
        expect(retrieved?['companyName'], 'Test Company');
        expect(retrieved?['ico'], '12345678');
      });

      test('should return null when business profile not set', () {
        // Act
        final profile = service.getBusinessProfile();

        // Assert
        expect(profile, isNull);
      });

      test('should update existing business profile', () async {
        // Arrange
        final initialProfile = {
          'companyName': 'Old Company',
          'ico': '11111111',
        };
        final updatedProfile = {
          'companyName': 'New Company',
          'ico': '22222222',
        };

        // Act
        await service.saveBusinessProfile(initialProfile);
        await service.saveBusinessProfile(updatedProfile);
        final retrieved = service.getBusinessProfile();

        // Assert
        expect(retrieved?['companyName'], 'New Company');
        expect(retrieved?['ico'], '22222222');
      });
    });

    group('clearAll', () {
      test('should clear all data', () async {
        // Arrange
        await service.saveInvoice('invoice1', {'number': '2026/001'});
        await service.saveExpense('expense1', {'description': 'Test'});
        await service.saveSetting('test_key', 'test_value');
        await service.saveBusinessProfile({'companyName': 'Test'});

        // Act
        await service.clearAll();

        // Assert
        expect(service.getInvoices().length, 0);
        expect(service.getExpenses().length, 0);
        expect(service.getSetting('test_key'), isNull);
        expect(service.getBusinessProfile(), isNull);
      });
    });
  });
}
