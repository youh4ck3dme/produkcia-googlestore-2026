// lib/features/bank_import/widgets/bank_match_suggestions.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/money.dart';
import '../../../shared/widgets/biz_badge.dart';
import '../../../shared/widgets/biz_card.dart';
import '../models/bank_models.dart';

class BankMatchSuggestions extends StatelessWidget {
  const BankMatchSuggestions({
    super.key,
    required this.matches,
    required this.onManualMatch,
  });

  final List<BankMatch> matches;
  final void Function(String txId, String? invoiceId, String? expenseId)
      onManualMatch;

  @override
  Widget build(BuildContext context) {
    final confidentMatches =
        matches.where((m) => m.isMatched && m.confidence >= 0.8).toList();
    final uncertainMatches =
        matches.where((m) => m.isUnmatched || m.confidence < 0.8).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary
        BizCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Súhrn párovania',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildSummaryItem(
                      'Spárované', confidentMatches.length, Colors.green),
                  const SizedBox(width: 16),
                  _buildSummaryItem(
                      'Neisté', uncertainMatches.length, Colors.orange),
                ],
              ),
            ],
          ),
        ),

        // Confident matches
        if (confidentMatches.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'Spárované transakcie',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          ...confidentMatches.map((match) => _buildMatchCard(context, match)),
        ],

        // Uncertain matches
        if (uncertainMatches.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'Vyžadujú manuálne overenie',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          ...uncertainMatches.map((match) =>
              _buildMatchCard(context, match, showManualOptions: true)),
        ],
      ],
    );
  }

  Widget _buildSummaryItem(String label, int count, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text('$count $label'),
      ],
    );
  }

  Widget _buildMatchCard(BuildContext context, BankMatch match,
      {bool showManualOptions = false}) {
    final tx = match.transaction;
    final confidencePercent = (match.confidence * 100).round();

    return BizCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Transaction info
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('dd.MM.yyyy').format(tx.date),
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    ...[
                      const SizedBox(height: 2),
                      Text(
                        tx.counterparty,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                    if (tx.message.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        tx.message,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Colors.grey),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${Money.eur(tx.amount)} €',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: tx.isIncome ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  ...[
                    const SizedBox(height: 2),
                    Text(
                      '$confidencePercent% istota',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: _getConfidenceColor(match.confidence),
                          ),
                    ),
                  ],
                ],
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Match status
          Row(
            children: [
              BizBadge(
                label: _getMatchStatusText(match),
                tone: _getMatchStatusTone(match),
              ),
              ...[
                const SizedBox(width: 8),
                BizBadge(
                  label: _getMatchTypeText(match.matchType),
                  tone: BizBadgeTone.neutral,
                ),
              ],
              const Spacer(),
              if (match.transaction.variableSymbol != null) ...[
                const Icon(Icons.tag, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  'VS: ${match.transaction.variableSymbol ?? ''}',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Colors.grey),
                ),
              ],
            ],
          ),

          // Manual override options
          if (showManualOptions) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () => _showManualMatchDialog(context, match),
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Manuálne spárovanie'),
                  style: OutlinedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _getMatchStatusText(BankMatch match) {
    if (match.isMatched) return 'Spárované';
    return 'Nespárované';
  }

  BizBadgeTone _getMatchStatusTone(BankMatch match) {
    if (match.isMatched) return BizBadgeTone.ok;
    return BizBadgeTone.warn;
  }

  String _getMatchTypeText(BankMatchType type) {
    switch (type) {
      case BankMatchType.none:
        return 'Žiadne';
      case BankMatchType.exactVs:
        return 'VS presne';
      case BankMatchType.amountVs:
        return 'VS + suma';
      case BankMatchType.fuzzyName:
        return 'Podobný názov';
      case BankMatchType.amountOnly:
        return 'Len suma';
      case BankMatchType.manual:
        return 'Manuálne';
    }
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.8) return Colors.green;
    if (confidence >= 0.6) return Colors.orange;
    return Colors.red;
  }

  void _showManualMatchDialog(BuildContext context, BankMatch match) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Manuálne spárovanie'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Transakcia: ${Money.eur(match.transaction.amount)} €'),
            const SizedBox(height: 8),
            const Text('Vyberte čo sa má spárovať:'),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      // Future: Implement invoice picker dialog
                      Navigator.of(context).pop();
                      onManualMatch(
                          match.transaction.id ?? '', 'mock_invoice_id', null);
                    },
                    child: const Text('Faktúra'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      // Future: Implement expense picker dialog
                      Navigator.of(context).pop();
                      onManualMatch(
                          match.transaction.id ?? '', null, 'mock_expense_id');
                    },
                    child: const Text('Výdavok'),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Zrušiť'),
          ),
        ],
      ),
    );
  }
}
