import 'package:flutter_test/flutter_test.dart';
import 'package:bizagent/features/settings/providers/settings_repository.dart';
import 'package:bizagent/features/settings/models/user_settings_model.dart';

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
}
