import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:bizagent/core/services/export_service.dart';
import 'package:bizagent/core/services/local_persistence_service.dart';

class MockLocalPersistenceService extends Mock implements LocalPersistenceService {}

void main() {
  group('ExportService', () {
    late MockLocalPersistenceService mockLocalPersistenceService;
    late ExportService exportService;

    setUp(() {
      mockLocalPersistenceService = MockLocalPersistenceService();
      exportService = ExportService(mockLocalPersistenceService);
    });

    group('CSV export', () {
      test('should export invoices to CSV format', () async {
        // Arrange
        final invoices = [
          {
            'number': '2026/001',
            'date': '2026-01-15',
            'clientName': 'Test Client 1',
            'totalAmount': 1000.0,
            'status': 'paid',
          },
          {
            'number': '2026/002',
            'date': '2026-01-20',
            'clientName': 'Test Client 2',
            'totalAmount': 1500.0,
            'status': 'unpaid',
          },
        ];

        when(mockLocalPersistenceService.getInvoices())
            .thenReturn(invoices);

        // Act
        final csvContent = await exportService.exportInvoicesToCSV('user123');

        // Assert
        expect(csvContent, isNotEmpty);
        expect(csvContent.contains('Číslo faktúry'), isTrue);
        expect(csvContent.contains('Dátum'), isTrue);
        expect(csvContent.contains('Klient'), isTrue);
        expect(csvContent.contains('Suma'), isTrue);
        expect(csvContent.contains('Status'), isTrue);
        expect(csvContent.contains('2026/001'), isTrue);
        expect(csvContent.contains('2026/002'), isTrue);
      });

      test('should export expenses to CSV format', () async {
        // Arrange
        final expenses = [
          {
            'description': 'Office supplies',
            'date': '2026-01-10',
            'amount': 50.0,
            'category': 'Office',
            'vatRate': 20.0,
          },
          {
            'description': 'Lunch',
            'date': '2026-01-15',
            'amount': 25.0,
            'category': 'Food',
            'vatRate': 10.0,
          },
        ];

        when(mockLocalPersistenceService.getExpenses())
            .thenReturn(expenses);

        // Act
        final csvContent = await exportService.exportExpensesToCSV('user123');

        // Assert
        expect(csvContent, isNotEmpty);
        expect(csvContent.contains('Popis'), isTrue);
        expect(csvContent.contains('Dátum'), isTrue);
        expect(csvContent.contains('Suma'), isTrue);
        expect(csvContent.contains('Kategória'), isTrue);
        expect(csvContent.contains('Office supplies'), isTrue);
        expect(csvContent.contains('Lunch'), isTrue);
      });

      test('should handle empty invoice list', () async {
        // Arrange
        when(mockLocalPersistenceService.getInvoices())
            .thenReturn([]);

        // Act
        final csvContent = await exportService.exportInvoicesToCSV('user123');

        // Assert
        expect(csvContent, isNotEmpty);
        expect(csvContent.contains('Číslo faktúry'), isTrue);
        expect(csvContent.split('\n').length, 2); // Header + empty line
      });

      test('should handle empty expense list', () async {
        // Arrange
        when(mockLocalPersistenceService.getExpenses())
            .thenReturn([]);

        // Act
        final csvContent = await exportService.exportExpensesToCSV('user123');

        // Assert
        expect(csvContent, isNotEmpty);
        expect(csvContent.contains('Popis'), isTrue);
        expect(csvContent.split('\n').length, 2); // Header + empty line
      });

      test('should format currency correctly in CSV', () async {
        // Arrange
        final invoices = [
          {
            'number': '2026/001',
            'date': '2026-01-15',
            'clientName': 'Test Client',
            'totalAmount': 1234.56,
            'status': 'paid',
          },
        ];

        when(mockLocalPersistenceService.getInvoices())
            .thenReturn(invoices);

        // Act
        final csvContent = await exportService.exportInvoicesToCSV('user123');

        // Assert
        expect(csvContent.contains('1234.56'), isTrue);
      });
    });

    group('PDF export', () {
      test('should export invoices to PDF format', () async {
        // Arrange
        final invoices = [
          {
            'number': '2026/001',
            'date': '2026-01-15',
            'clientName': 'Test Client 1',
            'totalAmount': 1000.0,
            'status': 'paid',
          },
        ];

        when(mockLocalPersistenceService.getInvoices())
            .thenReturn(invoices);

        // Act
        final pdfBytes = await exportService.exportInvoicesToPDF('user123');

        // Assert
        expect(pdfBytes, isNotNull);
        expect(pdfBytes.length, greaterThan(0));
        // PDF files start with %PDF
        expect(String.fromCharCodes(pdfBytes).startsWith('%PDF'), isTrue);
      });

      test('should export expenses to PDF format', () async {
        // Arrange
        final expenses = [
          {
            'description': 'Office supplies',
            'date': '2026-01-10',
            'amount': 50.0,
            'category': 'Office',
          },
        ];

        when(mockLocalPersistenceService.getExpenses())
            .thenReturn(expenses);

        // Act
        final pdfBytes = await exportService.exportExpensesToPDF('user123');

        // Assert
        expect(pdfBytes, isNotNull);
        expect(pdfBytes.length, greaterThan(0));
        expect(String.fromCharCodes(pdfBytes).startsWith('%PDF'), isTrue);
      });

      test('should handle empty invoice list in PDF export', () async {
        // Arrange
        when(mockLocalPersistenceService.getInvoices())
            .thenReturn([]);

        // Act
        final pdfBytes = await exportService.exportInvoicesToPDF('user123');

        // Assert
        expect(pdfBytes, isNotNull);
        expect(pdfBytes.length, greaterThan(0));
        expect(String.fromCharCodes(pdfBytes).startsWith('%PDF'), isTrue);
      });
    });

    group('Data formatting', () {
      test('should format date correctly', () async {
        // Arrange
        final invoices = [
          {
            'number': '2026/001',
            'date': '2026-01-15T10:30:00.000Z',
            'clientName': 'Test Client',
            'totalAmount': 1000.0,
            'status': 'paid',
          },
        ];

        when(mockLocalPersistenceService.getInvoices())
            .thenReturn(invoices);

        // Act
        final csvContent = await exportService.exportInvoicesToCSV('user123');

        // Assert
        expect(csvContent.contains('15.01.2026'), isTrue);
      });

      test('should format status correctly', () async {
        // Arrange
        final invoices = [
          {
            'number': '2026/001',
            'date': '2026-01-15',
            'clientName': 'Test Client',
            'totalAmount': 1000.0,
            'status': 'paid',
          },
          {
            'number': '2026/002',
            'date': '2026-01-16',
            'clientName': 'Test Client',
            'totalAmount': 1000.0,
            'status': 'unpaid',
          },
        ];

        when(mockLocalPersistenceService.getInvoices())
            .thenReturn(invoices);

        // Act
        final csvContent = await exportService.exportInvoicesToCSV('user123');

        // Assert
        expect(csvContent.contains('Zaplatená'), isTrue);
        expect(csvContent.contains('Nezaplatená'), isTrue);
      });

      test('should handle null values gracefully', () async {
        // Arrange
        final invoices = [
          {
            'number': '2026/001',
            'date': null,
            'clientName': null,
            'totalAmount': null,
            'status': null,
          },
        ];

        when(mockLocalPersistenceService.getInvoices())
            .thenReturn(invoices);

        // Act
        final csvContent = await exportService.exportInvoicesToCSV('user123');

        // Assert
        expect(csvContent, isNotEmpty);
        expect(csvContent.contains('2026/001'), isTrue);
      });
    });

    group('Error handling', () {
      test('should handle export errors gracefully', () async {
        // Arrange
        when(mockLocalPersistenceService.getInvoices())
            .thenThrow(Exception('Database error'));

        // Act & Assert
        expect(
          () => exportService.exportInvoicesToCSV('user123'),
          throwsA(isA<Exception>()),
        );
      });

      test('should handle malformed data', () async {
        // Arrange
        final invoices = [
          {
            'number': '2026/001',
            // Missing other required fields
          },
        ];

        when(mockLocalPersistenceService.getInvoices())
            .thenReturn(invoices);

        // Act
        final csvContent = await exportService.exportInvoicesToCSV('user123');

        // Assert
        expect(csvContent, isNotEmpty);
        expect(csvContent.contains('2026/001'), isTrue);
      });
    });

    group('Export options', () {
      test('should export with custom date range', () async {
        // Arrange
        final invoices = [
          {
            'number': '2026/001',
            'date': '2026-01-10',
            'clientName': 'Test Client',
            'totalAmount': 1000.0,
            'status': 'paid',
          },
          {
            'number': '2026/002',
            'date': '2026-01-20',
            'clientName': 'Test Client',
            'totalAmount': 1000.0,
            'status': 'paid',
          },
        ];

        when(mockLocalPersistenceService.getInvoices())
            .thenReturn(invoices);

        final startDate = DateTime(2026, 1, 15);
        final endDate = DateTime(2026, 1, 25);

        // Act
        final csvContent = await exportService.exportInvoicesToCSV(
          'user123',
          startDate: startDate,
          endDate: endDate,
        );

        // Assert
        expect(csvContent.contains('2026/001'), isFalse); // Before range
        expect(csvContent.contains('2026/002'), isTrue); // Within range
      });

      test('should export with custom format options', () async {
        // Arrange
        final invoices = [
          {
            'number': '2026/001',
            'date': '2026-01-15',
            'clientName': 'Test Client',
            'totalAmount': 1000.0,
            'status': 'paid',
          },
        ];

        when(mockLocalPersistenceService.getInvoices())
            .thenReturn(invoices);

        final formatOptions = ExportFormatOptions(
          includeVAT: true,
          currency: 'EUR',
          dateFormat: 'dd.MM.yyyy',
        );

        // Act
        final csvContent = await exportService.exportInvoicesToCSV(
          'user123',
          formatOptions: formatOptions,
        );

        // Assert
        expect(csvContent, isNotEmpty);
        expect(csvContent.contains('EUR'), isTrue);
      });
    });

    group('File naming', () {
      test('should generate appropriate file names', () async {
        // Arrange
        final invoices = [
          {
            'number': '2026/001',
            'date': '2026-01-15',
            'clientName': 'Test Client',
            'totalAmount': 1000.0,
            'status': 'paid',
          },
        ];

        when(mockLocalPersistenceService.getInvoices())
            .thenReturn(invoices);

        // Act
        final csvContent = await exportService.exportInvoicesToCSV('user123');

        // Assert
        expect(csvContent, isNotEmpty);
        // The service should provide appropriate file naming suggestions
        final suggestedName = exportService.getSuggestedFileName(
          ExportType.invoices,
          ExportFormat.csv,
          DateTime(2026, 1, 15),
        );
        expect(suggestedName, contains('faktury'));
        expect(suggestedName, contains('2026'));
      });
    });
  });
}

class ExportFormatOptions {
  final bool includeVAT;
  final String currency;
  final String dateFormat;

  ExportFormatOptions({
    required this.includeVAT,
    required this.currency,
    required this.dateFormat,
  });
}