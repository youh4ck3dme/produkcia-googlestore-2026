import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firestore_export_data_source.dart';
import '../models/export_models.dart';
import '../../../core/services/export_service.dart';

final exportProvider =
    StateNotifierProvider<ExportController, ExportState>((ref) {
  return ExportController();
});

// ... exportPeriodsProvider remains the same ...

class ExportController extends StateNotifier<ExportState> {
  ExportController() : super(ExportState.idle());

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
      final dataSource =
          FirestoreExportDataSource(FirebaseFirestore.instance, uid);
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
