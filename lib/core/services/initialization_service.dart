import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../services/local_persistence_service.dart';
import '../debug/perf_probe.dart';

// Progress state class
class InitState {
  final double progress; // 0.0 to 1.0
  final String message;
  final bool isCompleted;

  const InitState({
    required this.progress,
    required this.message,
    this.isCompleted = false,
  });

  InitState copyWith({double? progress, String? message, bool? isCompleted}) {
    return InitState(
      progress: progress ?? this.progress,
      message: message ?? this.message,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

class InitializationService extends Notifier<InitState> {
  @override
  InitState build() =>
      const InitState(progress: 0.0, message: 'Inicializácia...');

  Future<void> initializeApp() async {
    // 1. Start
    state = const InitState(progress: 0.1, message: 'Štartujem BizAgenta...');
    // #region agent log
    perfProbe('D', 'initialization_service.dart', 'init_state_update', {
      'progress': state.progress,
      'isCompleted': state.isCompleted,
    });
    // #endregion
    await Future.delayed(const Duration(milliseconds: 500)); // Visual delay

    // 2. Connectivity Check (Simulating network stabilization)
    state = state.copyWith(progress: 0.3, message: 'Stabilizujem pripojenie...');
    await Connectivity().checkConnectivity();
    // In a real app we might ping a server here
    await Future.delayed(const Duration(milliseconds: 800));

    // 3. Database Warmup
    state = state.copyWith(progress: 0.6, message: 'Načítavam lokálne dáta...');
    ref.read(localPersistenceServiceProvider);
    // Ensure boxes are open (they are init in main, but we can verify)
    await Future.delayed(const Duration(milliseconds: 600));

    // 4. Asset Caching (Simulated for this context, but represents SW work)
    state = state.copyWith(progress: 0.8, message: ' optimalizácia cache...');
    await Future.delayed(const Duration(milliseconds: 400));

    // 5. Finalizing
    state = state.copyWith(progress: 0.95, message: 'Pripravujem prostredie...');
    await Future.delayed(const Duration(milliseconds: 300));

    // Done
    state = state.copyWith(progress: 1.0, message: 'Hotovo!', isCompleted: true);
    // #region agent log
    perfProbe('D', 'initialization_service.dart', 'init_state_update', {
      'progress': state.progress,
      'isCompleted': state.isCompleted,
    });
    // #endregion
  }
}

final initializationServiceProvider =
    NotifierProvider<InitializationService, InitState>(InitializationService.new);
