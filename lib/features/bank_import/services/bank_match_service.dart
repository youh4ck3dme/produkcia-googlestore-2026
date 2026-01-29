// lib/features/bank_import/services/bank_match_service.dart
import '../models/bank_models.dart';

class BankMatchResult {
  final BankTx tx;
  final InvoiceLike? invoice;
  final double confidence; // 0..1
  final String reason;

  const BankMatchResult({
    required this.tx,
    required this.invoice,
    required this.confidence,
    required this.reason,
  });
}

class BankMatchService {
  const BankMatchService();

  List<BankMatchResult> match({
    required List<BankTx> txs,
    required List<InvoiceLike> invoices,
    double amountTolerance = 0.01,
  }) {
    final results = <BankMatchResult>[];

    for (final tx in txs) {
      final candidates = invoices
          .map((inv) => _score(tx, inv, amountTolerance))
          .toList()
        ..sort((a, b) => b.confidence.compareTo(a.confidence));

      final best = candidates.isEmpty ? null : candidates.first;
      if (best == null || best.confidence < 0.55) {
        results.add(BankMatchResult(
            tx: tx,
            invoice: null,
            confidence: best?.confidence ?? 0,
            reason: 'No strong match'));
      } else {
        results.add(best);
      }
    }

    return results;
  }

  BankMatchResult _score(BankTx tx, InvoiceLike inv, double tol) {
    double score = 0;
    final reasons = <String>[];

    // 1) VS exact
    final txVs = _digits(tx.variableSymbol ?? '');
    final invVs = _digits(inv.variableSymbol);
    if (txVs.isNotEmpty && invVs.isNotEmpty && txVs == invVs) {
      score += 0.65;
      reasons.add('VS match');
    }

    // 2) Amount equals invoice total (bank tx usually income is +)
    if ((tx.amount - inv.total).abs() <= tol) {
      score += 0.35;
      reasons.add('Amount match');
    }

    // 3) Counterparty fuzzy (simple token overlap)
    final s = _tokenScore(tx.counterpartyName, inv.clientName);
    if (s > 0) {
      score += (0.20 * s);
      reasons.add('Name similarity ${(s * 100).round()}%');
    }

    // small boost if message contains invoice number or VS
    final msg = tx.message.toLowerCase();
    if (inv.number.isNotEmpty && msg.contains(inv.number.toLowerCase())) {
      score += 0.10;
      reasons.add('Message contains invoice number');
    }
    if (invVs.isNotEmpty && msg.contains(invVs)) {
      score += 0.10;
      reasons.add('Message contains VS');
    }

    if (score > 1) score = 1;
    return BankMatchResult(
      tx: tx,
      invoice: inv,
      confidence: score,
      reason: reasons.isEmpty ? 'Weak match' : reasons.join(', '),
    );
  }

  String _digits(String s) => s.replaceAll(RegExp(r'[^0-9]'), '');

  double _tokenScore(String a, String b) {
    final ta = _tokens(a);
    final tb = _tokens(b);
    if (ta.isEmpty || tb.isEmpty) return 0;

    final inter = ta.intersection(tb).length;
    final union = ta.union(tb).length;
    if (union == 0) return 0;
    return inter / union;
  }

  Set<String> _tokens(String s) {
    final x = s
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9áäčďéíĺľňóôŕšťúýž ]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (x.isEmpty) return {};
    return x.split(' ').where((t) => t.length >= 3).toSet();
  }
}
