import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_repository.dart';
import '../models/user_settings_model.dart';
import 'settings_repository.dart';

final settingsProvider = StreamProvider<UserSettingsModel>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value(UserSettingsModel.empty());
  return ref.watch(settingsRepositoryProvider).watchSettings(user.id);
});

final settingsControllerProvider =
    StateNotifierProvider<SettingsController, AsyncValue<void>>((ref) {
  return SettingsController(ref);
});

class SettingsController extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  SettingsController(this._ref) : super(const AsyncValue.data(null));

  Future<void> updateSettings(UserSettingsModel settings) async {
    final user = _ref.read(authStateProvider).value;
    if (user == null) return;

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _ref
        .read(settingsRepositoryProvider)
        .updateSettings(user.id, settings));
  }

  Future<void> updateIban(String iban) async {
    final user = _ref.read(authStateProvider).value;
    if (user == null) return;

    final currentSettings =
        await _ref.read(settingsRepositoryProvider).getSettings(user.id);
    final updatedSettings = currentSettings.copyWith(iban: iban);

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _ref
        .read(settingsRepositoryProvider)
        .updateSettings(user.id, updatedSettings));
  }

  Future<void> updateShowQrOnInvoice(bool showQrOnInvoice) async {
    final user = _ref.read(authStateProvider).value;
    if (user == null) return;

    final currentSettings =
        await _ref.read(settingsRepositoryProvider).getSettings(user.id);
    final updatedSettings =
        currentSettings.copyWith(showQrOnInvoice: showQrOnInvoice);

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _ref
        .read(settingsRepositoryProvider)
        .updateSettings(user.id, updatedSettings));
  }

  Future<void> updateVatPayer(bool isVatPayer) async {
    final user = _ref.read(authStateProvider).value;
    if (user == null) return;

    final currentSettings =
        await _ref.read(settingsRepositoryProvider).getSettings(user.id);
    final updatedSettings = currentSettings.copyWith(isVatPayer: isVatPayer);

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _ref
        .read(settingsRepositoryProvider)
        .updateSettings(user.id, updatedSettings));
  }

  Future<void> updateBiometricEnabled(bool enabled) async {
    final user = _ref.read(authStateProvider).value;
    if (user == null) return;

    final currentSettings =
        await _ref.read(settingsRepositoryProvider).getSettings(user.id);
    final updatedSettings = currentSettings.copyWith(biometricEnabled: enabled);

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _ref
        .read(settingsRepositoryProvider)
        .updateSettings(user.id, updatedSettings));
  }

  Future<void> updateLanguage(String language) async {
    final user = _ref.read(authStateProvider).value;
    if (user == null) return;

    final currentSettings =
        await _ref.read(settingsRepositoryProvider).getSettings(user.id);
    final updatedSettings = currentSettings.copyWith(language: language);

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _ref
        .read(settingsRepositoryProvider)
        .updateSettings(user.id, updatedSettings));
  }
}
