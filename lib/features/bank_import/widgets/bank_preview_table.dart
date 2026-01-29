// lib/features/bank_import/widgets/bank_preview_table.dart
import 'package:flutter/material.dart';

class BankPreviewTable extends StatelessWidget {
  const BankPreviewTable({
    super.key,
    required this.previewData,
    this.maxRows = 5,
  });

  final List<List<String>> previewData;
  final int maxRows;

  @override
  Widget build(BuildContext context) {
    if (previewData.isEmpty) {
      return const Text('Žiadne dáta na zobrazenie');
    }

    final displayRows = previewData.take(maxRows).toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: _buildColumns(displayRows.first.length),
        rows: displayRows.map((row) => _buildRow(row)).toList(),
        columnSpacing: 12,
        horizontalMargin: 12,
        dataRowMaxHeight: 40,
        headingRowHeight: 48,
      ),
    );
  }

  List<DataColumn> _buildColumns(int count) {
    final columns = <DataColumn>[];
    for (int i = 0; i < count; i++) {
      columns.add(DataColumn(
        label: Text(
          'Stĺpec ${i + 1}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        ),
      ));
    }
    return columns;
  }

  DataRow _buildRow(List<String> rowData) {
    return DataRow(
      cells: rowData.map((cell) {
        return DataCell(
          Text(
            cell,
            style: const TextStyle(fontSize: 12),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        );
      }).toList(),
    );
  }
}
