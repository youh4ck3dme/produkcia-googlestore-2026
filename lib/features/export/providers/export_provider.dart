import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/export_models.dart';
import '../../../core/services/export_service.dart';
import '../../../core/supabase/supabase_config.dart';
import '../../../core/supabase/supabase_providers.dart';
import 'supabase_export_data_source.dart';

final exportProvider =
    StateNotifierProvider<ExportController, ExportState>((ref) {
  return ExportController(ref);
});

// ... exportPeriodsProvider remains the same ...

class ExportController extends StateNotifier<ExportState> {
  ExportController(this._ref) : super(ExportState.idle());

  final Ref _ref;

  Future<void> run({
    required String uid,
    required ExportPeriod period,
  }) async {
    state = state.copyWith(
      isRunning: true,
      error: null,
      result: null,
      progress: ExportProgress.idle()
          .copyWith(message: 'Pripravujem dáta…', percent: 0.1),
    );

    try {
      if (!SupabaseConfig.isReady) {
        throw StateError('Supabase nie je inicializovaný — export nie je dostupný');
      }
      final dataSource = SupabaseExportDataSource(
        _ref.read(supabaseTableStoreProvider),
        uid,
      );
      final service = ExportService(dataSource);

      final result = await service.buildZip(
        uid: uid,
        period: period,
        onStep: (msg) {
          state =
              state.copyWith(progress: state.progress.copyWith(message: msg));
        },
        onProgress: (p) {
          state = state.copyWith(progress: p);
        },
      );

      state = state.copyWith(
        isRunning: false,
        progress: state.progress.copyWith(percent: 1.0, message: 'Hotovo'),
        result: result,
      );
    } catch (e) {
      state = state.copyWith(isRunning: false, error: e.toString());
    }
  }

  void reset() {
    state = ExportState.idle();
  }
}
