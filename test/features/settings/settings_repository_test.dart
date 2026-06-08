import 'package:flutter_test/flutter_test.dart';
import 'package:bizagent/features/settings/providers/settings_repository.dart';
import 'package:bizagent/features/settings/models/user_settings_model.dart';

import '../../helpers/in_memory_supabase_store.dart';

void main() {
  group('SettingsRepository (offline — bez Supabase)', () {
    late SettingsRepository repository;

    setUp(() {
      repository = SettingsRepository(null);
    });

    test('getSettings vracia prázdne nastavenia bez Supabase', () async {
      final settings = await repository.getSettings('user123');
      expect(settings.companyName, '');
      expect(settings.isVatPayer, isFalse);
      expect(settings.language, 'sk');
    });

    test('watchSettings emituje prázdne nastavenia', () async {
      final settings = await repository.watchSettings('user123').first;
      expect(settings.companyName, '');
      expect(settings.isVatPayer, isFalse);
    });

    test('updateSettings je no-op bez chyby (offline)', () async {
      final settings = UserSettingsModel(
        companyName: 'Test Company',
        companyAddress: '',
        companyIco: '12345678',
        companyDic: '',
        companyIcDph: '',
        bankAccount: '',
        swift: '',
        registerInfo: '',
      );

      await expectLater(
        repository.updateSettings('user123', settings),
        completes,
      );

      // Bez Supabase sa dáta neuložia — stále prázdne.
      final loaded = await repository.getSettings('user123');
      expect(loaded.companyName, '');
    });
  });

  group('SettingsRepository (with Supabase store)', () {
    late InMemorySupabaseStore store;
    late SettingsRepository repository;
    const userId = 'user123';

    setUp(() {
      store = InMemorySupabaseStore();
      repository = SettingsRepository(store);
    });

    test('updateSettings persists to store and getSettings reads back', () async {
      final settings = UserSettingsModel(
        companyName: 'Test Company',
        companyAddress: 'Bratislava',
        companyIco: '12345678',
        companyDic: '',
        companyIcDph: '',
        bankAccount: '',
        swift: '',
        registerInfo: '',
        isVatPayer: true,
      );

      await repository.updateSettings(userId, settings);
      final loaded = await repository.getSettings(userId);

      expect(loaded.companyName, 'Test Company');
      expect(loaded.companyIco, '12345678');
      expect(loaded.isVatPayer, isTrue);
    });

    test('watchSettings emits updated settings', () async {
      final settings = UserSettingsModel.empty().copyWith(
        companyName: 'Stream Co',
        companyIco: '87654321',
      );

      final values = <UserSettingsModel>[];
      final sub = repository.watchSettings(userId).listen(values.add);

      await repository.updateSettings(userId, settings);
      await Future<void>.delayed(Duration.zero);

      expect(values.any((s) => s.companyName == 'Stream Co'), isTrue);
      await sub.cancel();
    });
  });
}
