// lib/features/bank_import/widgets/bank_tx_table.dart
import 'package:flutter/material.dart';

import '../../../core/i18n/app_strings.dart';
import '../../../core/i18n/l10n.dart';
import '../models/bank_tx.dart';

class BankTxTable extends StatelessWidget {
  final List<BankTx> txs;

  const BankTxTable({super.key, required this.txs});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: [
          DataColumn(label: Text(context.t(AppStr.bankColDate))),
          DataColumn(label: Text(context.t(AppStr.bankColAmount))),
          DataColumn(label: Text(context.t(AppStr.bankColCurrency))),
          DataColumn(label: Text(context.t(AppStr.bankColVs))),
          DataColumn(label: Text(context.t(AppStr.bankColCounterparty))),
          DataColumn(label: Text(context.t(AppStr.bankColMessage))),
        ],
        rows: txs.take(200).map((t) {
          return DataRow(cells: [
            DataCell(Text(
                '${t.date.year}-${_pad2(t.date.month)}-${_pad2(t.date.day)}')),
            DataCell(Text(t.amount.toStringAsFixed(2))),
            DataCell(Text(t.currency ?? '')),
            DataCell(Text(t.variableSymbol ?? '')),
            DataCell(Text(t.counterpartyName)),
            DataCell(
                Text(t.message, maxLines: 2, overflow: TextOverflow.ellipsis)),
          ]);
        }).toList(),
      ),
    );
  }

  String _pad2(int v) => v.toString().padLeft(2, '0');
}