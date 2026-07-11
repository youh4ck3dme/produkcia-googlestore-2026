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
    NotifierProvider<SettingsController, AsyncValue<void>>(SettingsController.new);

class SettingsController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  void _refreshSettings() => ref.invalidate(settingsProvider);

  Future<void> updateSettings(UserSettingsModel settings) async {
    final user = ref.read(authStateProvider).value;
    if (user == null) return;

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => ref
        .read(settingsRepositoryProvider)
        .updateSettings(user.id, settings));
    _refreshSettings();
  }

  Future<void> updateIban(String iban) async {
    final user = ref.read(authStateProvider).value;
    if (user == null) return;

    final currentSettings =
        await ref.read(settingsRepositoryProvider).getSettings(user.id);
    final updatedSettings = currentSettings.copyWith(iban: iban);

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => ref
        .read(settingsRepositoryProvider)
        .updateSettings(user.id, updatedSettings));
    _refreshSettings();
  }

  Future<void> updateShowQrOnInvoice(bool showQrOnInvoice) async {
    final user = ref.read(authStateProvider).value;
    if (user == null) return;

    final currentSettings =
        await ref.read(settingsRepositoryProvider).getSettings(user.id);
    final updatedSettings =
        currentSettings.copyWith(showQrOnInvoice: showQrOnInvoice);

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => ref
        .read(settingsRepositoryProvider)
        .updateSettings(user.id, updatedSettings));
    _refreshSettings();
  }

  Future<void> updateVatPayer(bool isVatPayer) async {
    final user = ref.read(authStateProvider).value;
    if (user == null) return;

    final currentSettings =
        await ref.read(settingsRepositoryProvider).getSettings(user.id);
    final updatedSettings = currentSettings.copyWith(isVatPayer: isVatPayer);

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => ref
        .read(settingsRepositoryProvider)
        .updateSettings(user.id, updatedSettings));
    _refreshSettings();
  }

  Future<void> updateBiometricEnabled(bool enabled) async {
    final user = ref.read(authStateProvider).value;
    if (user == null) return;

    final currentSettings =
        await ref.read(settingsRepositoryProvider).getSettings(user.id);
    final updatedSettings = currentSettings.copyWith(biometricEnabled: enabled);

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => ref
        .read(settingsRepositoryProvider)
        .updateSettings(user.id, updatedSettings));
    _refreshSettings();
  }

  Future<void> updateLanguage(String language) async {
    final user = ref.read(authStateProvider).value;
    if (user == null) return;

    final currentSettings =
        await ref.read(settingsRepositoryProvider).getSettings(user.id);
    final updatedSettings = currentSettings.copyWith(language: language);

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => ref
        .read(settingsRepositoryProvider)
        .updateSettings(user.id, updatedSettings));
    _refreshSettings();
  }
}
