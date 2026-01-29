import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/services/tutorial_service.dart';
import '../providers/settings_provider.dart';
import '../models/user_settings_model.dart';
import '../../../shared/utils/biz_snackbar.dart';
import '../../../shared/widgets/biz_widgets.dart';
import '../../../core/services/company_lookup_service.dart';
import '../../../core/services/local_persistence_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _icoController;
  late TextEditingController _dicController;
  late TextEditingController _icDphController;
  late TextEditingController _ibanController;
  late TextEditingController _swiftController;
  bool _isLookingUp = false;

  final GlobalKey _saveKey = GlobalKey();
  final GlobalKey _sectionKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    final settings =
        ref.read(settingsProvider).valueOrNull ?? UserSettingsModel.empty();
    _nameController = TextEditingController(text: settings.companyName);
    _addressController = TextEditingController(text: settings.companyAddress);
    _icoController = TextEditingController(text: settings.companyIco);
    _dicController = TextEditingController(text: settings.companyDic);
    _icDphController = TextEditingController(text: settings.companyIcDph);
    _ibanController = TextEditingController(text: settings.bankAccount);
    _swiftController = TextEditingController(text: settings.swift);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _icoController.dispose();
    _dicController.dispose();
    _icDphController.dispose();
    _ibanController.dispose();
    _swiftController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final current =
        ref.read(settingsProvider).valueOrNull ?? UserSettingsModel.empty();
    final updated = current.copyWith(
      companyName: _nameController.text,
      companyAddress: _addressController.text,
      companyIco: _icoController.text,
      companyDic: _dicController.text,
      companyIcDph: _icDphController.text,
      bankAccount: _ibanController.text,
      swift: _swiftController.text,
    );

    await ref.read(settingsControllerProvider.notifier).updateSettings(updated);
    if (mounted) {
      BizSnackbar.showSuccess(context, 'Nastavenia úspešne uložené');
    }
  }

  Future<void> _lookupCompany() async {
    final ico = _icoController.text.trim();
    if (ico.isEmpty) {
      BizSnackbar.showInfo(context, 'Zadajte IČO');
      return;
    }

    setState(() => _isLookingUp = true);
    try {
      final service = ref.read(companyLookupServiceProvider);
      final company = await service.lookupByIco(ico);

      if (mounted) {
        // Result is never null or throws exception
        setState(() {
          _nameController.text = company.name;
          _addressController.text = company.fullAddress;
          if (company.dic != null) _dicController.text = company.dic!;
          if (company.icDph != null) _icDphController.text = company.icDph!;
        });
        BizSnackbar.showSuccess(context, 'Našli sme: ${company.name}');
      }
    } catch (e) {
      if (mounted) {
        BizSnackbar.showError(context, 'Chyba pri hľadaní: $e');
      }
    } finally {
      if (mounted) setState(() => _isLookingUp = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nastavenia'),
        actions: [
          BizTutorialButton(
            onPressed: () {
              TutorialService.showSettingsTutorial(
                context: context,
                saveKey: _saveKey,
                sectionKey: _sectionKey,
              );
            },
          ),
          IconButton(key: _saveKey, onPressed: _save, icon: const Icon(Icons.save)),
        ],
      ),
      body: settingsAsync.when(
        data: (settings) => Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSectionTitle('Firma', key: _sectionKey),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Obchodné meno'),
                validator: (v) => v!.isEmpty ? 'Povinné' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Adresa sídla'),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _icoController,
                      decoration: InputDecoration(
                        labelText: 'IČO',
                        suffixIcon: _isLookingUp
                            ? const Padding(
                                padding: EdgeInsets.all(12.0),
                                child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                ),
                              )
                            : IconButton(
                                icon: const Icon(Icons.search),
                                tooltip: 'Vyhľadať firmu (Automaticky)',
                                onPressed: _lookupCompany,
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _dicController,
                      decoration: const InputDecoration(labelText: 'DIČ'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _icDphController,
                decoration: const InputDecoration(labelText: 'IČ DPH'),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Platca DPH'),
                value: settings.isVatPayer,
                onChanged: (val) {
                  ref
                      .read(settingsControllerProvider.notifier)
                      .updateVatPayer(val);
                },
              ),
              const Divider(height: 32),
              _buildSectionTitle('Bankové údaje'),
              TextFormField(
                controller: _ibanController,
                decoration: const InputDecoration(labelText: 'IBAN'),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _swiftController,
                decoration: const InputDecoration(labelText: 'SWIFT / BIC'),
              ),
              const Divider(height: 32),
              _buildSectionTitle('Aplikácia'),
              ListTile(
                title: const Text('Téma aplikácie'),
                trailing: const Icon(Icons.brightness_6),
                subtitle: Text(ref.watch(themeProvider).name.toUpperCase()),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Vyberte tému'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            title: const Text('Systémová'),
                            onTap: () {
                              ref
                                  .read(themeProvider.notifier)
                                  .setTheme(ThemeMode.system);
                              Navigator.pop(context);
                            },
                          ),
                          ListTile(
                            title: const Text('Svetlá'),
                            onTap: () {
                              ref
                                  .read(themeProvider.notifier)
                                  .setTheme(ThemeMode.light);
                              Navigator.pop(context);
                            },
                          ),
                          ListTile(
                            title: const Text('Tmavá'),
                            onTap: () {
                              ref
                                  .read(themeProvider.notifier)
                                  .setTheme(ThemeMode.dark);
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                title: const Text('Jazyk'),
                trailing: const Text('Slovenčina'),
                onTap: () {},
              ),
              const Divider(height: 32),
              _buildSectionTitle('Správa dát'),
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Kôš (obnovenie zmazaných položiek)'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/settings/trash'),
              ),
              const Divider(height: 32),
              _buildSectionTitle('Právne dokumenty'),
              ListTile(
                leading: const Icon(Icons.description_outlined),
                title: const Text('Obchodné podmienky'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/legal/terms'),
              ),
              ListTile(
                leading: const Icon(Icons.privacy_tip_outlined),
                title: const Text('Ochrana osobných údajov (GDPR)'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/legal/privacy'),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _save,
                style:
                    ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
                child: const Text('Uložiť zmeny'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => _confirmReset(context),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Resetovať aplikáciu (Smazať všetky dáta)'),
              ),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Chyba: $err')),
      ),
    );
  }

  Future<void> _confirmReset(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Naozaj resetovať?'),
        content: const Text(
            'Týmto nenávratne vymažete všetky faktúry, výdavky a nastavenia firmy. Aplikácia bude ako po prvej inštalácii.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Zrušiť')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Vymazať všetko'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(localPersistenceServiceProvider).clearAll();
      // Restart app or invalidate providers
      if (!context.mounted) return;
      BizSnackbar.showSuccess(context, 'Dáta boli vymazané. Reštartujte aplikáciu.');
    }
  }

  Widget _buildSectionTitle(String title, {Key? key}) {
    return Padding(
      key: key,
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.blueGrey,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}
