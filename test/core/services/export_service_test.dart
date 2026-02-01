import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:bizagent/core/services/export_service.dart';

// ExportService API changed: uses ExportDataSource + buildZip (no exportInvoicesToCSV etc.)
// Full test rewrite pending. See lib/core/services/export_service.dart and export_models.dart.
class MockExportDataSource extends Mock implements ExportDataSource {}

void main() {
  late MockExportDataSource mockDataSource;
  late ExportService exportService;

  setUp(() {
    mockDataSource = MockExportDataSource();
    exportService = ExportService(mockDataSource);
  });

  test('ExportService builds with ExportDataSource', () {
    expect(exportService.dataSource, mockDataSource);
  });
}
