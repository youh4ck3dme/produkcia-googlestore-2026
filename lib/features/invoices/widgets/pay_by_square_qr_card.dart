import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/i18n/app_strings.dart';
import '../../../core/i18n/l10n.dart';
import '../../../core/services/pay_by_square_service.dart';

class PayBySquareQrCard extends StatelessWidget {
  const PayBySquareQrCard({
    super.key,
    required this.iban,
    required this.swift,
    required this.amountEur,
    required this.variableSymbol,
    required this.recipientName,
    required this.dateDue,
    this.note,
    this.qrSize = 120,
  });

  final String iban;
  final String swift;
  final double amountEur;
  final String variableSymbol;
  final String recipientName;
  final DateTime dateDue;
  final String? note;
  final double qrSize;

  String get _payload => PayBySquareService.generateString(
        iban: iban,
        swift: swift.isEmpty ? 'UNKNOWNSWIFT' : swift,
        amount: amountEur,
        variableSymbol: variableSymbol,
        recipientName: recipientName,
        note: note,
        dateDue: DateFormat('yyyy-MM-dd').format(dateDue),
      );

  @override
  Widget build(BuildContext context) {
    final amountLabel = NumberFormat.currency(symbol: '€').format(amountEur);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                QrImageView(
                  data: _payload,
                  size: qrSize,
                  backgroundColor: Colors.white,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.t(AppStr.qrPaymentTitle),
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        context.t(AppStr.qrPaymentHint),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 12),
                      Text('IBAN: $iban',
                          style: Theme.of(context).textTheme.bodySmall),
                      if (variableSymbol.trim().isNotEmpty)
                        Text('VS: ${variableSymbol.trim()}',
                            style: Theme.of(context).textTheme.bodySmall),
                      Text('Suma: $amountLabel',
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _CopyChip(
                  label: context.t(AppStr.copyIban),
                  value: iban,
                ),
                if (variableSymbol.trim().isNotEmpty)
                  _CopyChip(
                    label: context.t(AppStr.copyVs),
                    value: variableSymbol.trim(),
                  ),
                _CopyChip(
                  label: context.t(AppStr.copyAmount),
                  value: amountEur.toStringAsFixed(2),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CopyChip extends StatelessWidget {
  const _CopyChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      avatar: const Icon(Icons.copy, size: 16),
      onPressed: () {
        Clipboard.setData(ClipboardData(text: value));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$label: $value')),
        );
      },
    );
  }
}