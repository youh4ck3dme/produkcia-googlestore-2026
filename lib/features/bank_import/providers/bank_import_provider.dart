// lib/features/bank_import/providers/bank_import_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/bank_models.dart';
import '../services/bank_csv_parser_service.dart';
import '../services/bank_match_service.dart';

class BankImportState {
  final String csvText;
  final BankCsvProfile profile;
  final List<BankTx> txs;
  final List<String> warnings;
  final List<BankMatch> matches;
  final bool isLoading;

  const BankImportState({
    this.csvText = '',
    this.profile = BankCsvProfile.generic,
    this.txs = const [],
    this.warnings = const [],
    this.matches = const [],
    this.isLoading = false,
  });

  BankImportState copyWith({
    String? csvText,
    BankCsvProfile? profile,
    List<BankTx>? txs,
    List<String>? warnings,
    List<BankMatch>? matches,
    bool? isLoading,
  }) {
    return BankImportState(
      csvText: csvText ?? this.csvText,
      profile: profile ?? this.profile,
      txs: txs ?? this.txs,
      warnings: warnings ?? this.warnings,
      matches: matches ?? this.matches,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

final bankImportProvider =
    NotifierProvider<BankImportController, BankImportState>(
  BankImportController.new,
);

class BankImportController extends Notifier<BankImportState> {
  final _parser = const BankCsvParserService();
  final _matcher = const BankMatchService();

  @override
  BankImportState build() => const BankImportState();

  void setCsvText(String v) {
    state = state.copyWith(csvText: v);
  }

  void setProfile(BankCsvProfile p) {
    state = state.copyWith(profile: p);
  }

  void parseNow() {
    state = state.copyWith(isLoading: true);
    final res =
        _parser.parse(csvText: state.csvText, profileHint: state.profile);
    state = state.copyWith(
      isLoading: false,
      profile: res.profile,
      txs: res.txs,
      warnings: res.warnings,
      matches: const [],
    );
  }

  /// invoices: pass from your invoice repository later
  void autoMatch(List<InvoiceLike> invoices) {
    state = state.copyWith(isLoading: true);
    final results = _matcher.match(txs: state.txs, invoices: invoices);
    // Convert BankMatchResult to BankMatch for UI compatibility
    final matches = results
        .map((result) => BankMatch(
              tx: result.tx,
              profile: state.profile,
              confidence: result.confidence,
              invoice: result.invoice,
              reason: result.reason,
              matchType: BankMatchType.exactVs, // or determine based on result
            ))
        .toList();
    state = state.copyWith(isLoading: false, matches: matches);
  }

  void clear() {
    state = const BankImportState();
  }
}
