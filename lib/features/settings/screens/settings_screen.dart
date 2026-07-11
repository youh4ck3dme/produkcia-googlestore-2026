import 'package:supabase_flutter/supabase_flutter.dart' show AuthException;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/play_release_scope.dart';
import '../../../core/i18n/app_strings.dart';
import '../../../core/i18n/l10n.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/services/tutorial_service.dart';
import '../providers/settings_provider.dart';
import '../models/user_settings_model.dart';
import '../../../shared/utils/biz_snackbar.dart';
import '../../../shared/widgets/biz_widgets.dart';
import '../../../core/services/company_lookup_service.dart';
import '../../../core/services/local_persistence_service.dart';
import '../../auth/providers/auth_repository.dart';
import '../../billing/subscription_guard.dart';
import '../../billing/paywall_flow.dart';

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
        ref.read(settingsProvider).value ?? UserSettingsModel.empty();
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
        ref.read(settingsProvider).value ?? UserSettingsModel.empty();
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
      BizSnackbar.showSuccess(context, context.t(AppStr.settingsSavedToast));
    }
  }

  Future<void> _lookupCompany() async {
    final ico = _icoController.text.trim();
    if (ico.isEmpty) {
      BizSnackbar.showInfo(context, context.t(AppStr.settingsEnterIco));
      return;
    }

    setState(() => _isLookingUp = true);
    try {
      final service = ref.read(companyLookupServiceProvider);
      final company = await service.lookupByIco(ico);

      if (mounted) {
        if (company.name.isEmpty) {
          BizSnackbar.showError(context, context.t(AppStr.settingsCompanyNotFound));
          return;
        }

        setState(() {
          _nameController.text = company.name;
          _addressController.text = company.fullAddress;
          if (company.dic != null) _dicController.text = company.dic!;
          if (company.icDph != null) _icDphController.text = company.icDph!;
        });
        if (company.isVatPayer) {
          await ref.read(settingsControllerProvider.notifier).updateVatPayer(true);
        }
        BizSnackbar.showSuccess(context, context.t(AppStr.settingsCompanyFound,
            params: {'name': company.name}));
      }
    } catch (e) {
      if (mounted) {
        BizSnackbar.showError(context, context.t(AppStr.settingsLookupError,
            params: {'error': '$e'}));
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
        title: Text(context.t(AppStr.settingsTitle)),
        actions: [
          if (PlayReleaseScope.showCoachMarkTutorials)
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
              _buildSectionTitle(context.t(AppStr.settingsSectionCompany),
                  key: _sectionKey),
              TextFormField(
                controller: _nameController,
                decoration:
                    InputDecoration(labelText: context.t(AppStr.settingsCompanyName)),
                validator: (v) =>
                    v!.isEmpty ? context.t(AppStr.settingsRequired) : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _addressController,
                decoration: InputDecoration(
                    labelText: context.t(AppStr.settingsCompanyAddress)),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _icoController,
                      decoration: InputDecoration(
                        labelText: context.t(AppStr.icoLabel),
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
                                tooltip: context.t(AppStr.settingsLookupTooltip),
                                onPressed: _lookupCompany,
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _dicController,
                      decoration:
                          InputDecoration(labelText: context.t(AppStr.dicLabel)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _icDphController,
                decoration:
                    InputDecoration(labelText: context.t(AppStr.icdphLabel)),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: Text(context.t(AppStr.settingsVatPayer)),
                value: settings.isVatPayer,
                onChanged: (val) {
                  ref
                      .read(settingsControllerProvider.notifier)
                      .updateVatPayer(val);
                },
              ),
              const Divider(height: 32),
              _buildSectionTitle(context.t(AppStr.settingsSectionBank)),
              TextFormField(
                controller: _ibanController,
                decoration:
                    InputDecoration(labelText: context.t(AppStr.ibanLabel)),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _swiftController,
                decoration:
                    InputDecoration(labelText: context.t(AppStr.settingsSwift)),
              ),
              const Divider(height: 32),
              _buildSectionTitle(context.t(AppStr.settingsSectionApp)),
              ListTile(
                title: Text(context.t(AppStr.settingsTheme)),
                trailing: const Icon(Icons.brightness_6),
                subtitle: Text(_themeLabel(context, ref.watch(themeProvider))),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      title: Text(dialogContext.t(AppStr.settingsThemeSelect)),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            title: Text(
                                dialogContext.t(AppStr.settingsThemeSystem)),
                            onTap: () {
                              ref
                                  .read(themeProvider.notifier)
                                  .setTheme(ThemeMode.system);
                              Navigator.pop(dialogContext);
                            },
                          ),
                          ListTile(
                            title: Text(
                                dialogContext.t(AppStr.settingsThemeLight)),
                            onTap: () {
                              ref
                                  .read(themeProvider.notifier)
                                  .setTheme(ThemeMode.light);
                              Navigator.pop(dialogContext);
                            },
                          ),
                          ListTile(
                            title:
                                Text(dialogContext.t(AppStr.settingsThemeDark)),
                            onTap: () {
                              ref
                                  .read(themeProvider.notifier)
                                  .setTheme(ThemeMode.dark);
                              Navigator.pop(dialogContext);
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                title: Text(context.t(AppStr.settingsLanguage)),
                trailing: Text(context.t(AppStr.settingsLanguageSk)),
                onTap: () {},
              ),
              const Divider(height: 32),
              _buildSectionTitle(context.t(AppStr.settingsSectionExport)),
              ListTile(
                leading: const Icon(Icons.archive_outlined),
                title: Text(context.t(AppStr.exportForAccountantTitle)),
                subtitle: Text(context.t(AppStr.settingsExportSubtitle)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  if (await PaywallFlow.ensureAccess(
                    context,
                    ref,
                    BizFeature.exportExcel,
                  )) {
                    if (context.mounted) context.push('/export');
                  }
                },
              ),
              const Divider(height: 32),
              _buildSectionTitle(context.t(AppStr.settingsSectionData)),
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: Text(context.t(AppStr.settingsTrash)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/settings/trash'),
              ),
              const Divider(height: 32),
              _buildSectionTitle(context.t(AppStr.settingsSectionLegal)),
              ListTile(
                leading: const Icon(Icons.description_outlined),
                title: Text(context.t(AppStr.settingsTerms)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/legal/terms'),
              ),
              ListTile(
                leading: const Icon(Icons.privacy_tip_outlined),
                title: Text(context.t(AppStr.settingsPrivacy)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/legal/privacy'),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _save,
                style:
                    ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
                child: Text(context.t(AppStr.settingsSaveChanges)),
              ),
              const Divider(height: 32),
              _buildSectionTitle(context.t(AppStr.settingsSectionDeleteAccount)),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.t(AppStr.settingsDeleteAccountWarning),
                      style: const TextStyle(fontSize: 13, color: Colors.red),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _confirmDeleteAccount(),
                        icon: const Icon(Icons.delete_forever, color: Colors.red),
                        label: Text(context.t(AppStr.settingsDeleteAccountButton)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.all(14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => _confirmReset(),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: Text(context.t(AppStr.settingsResetApp)),
              ),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  context.t(AppStr.settingsLoadError),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  '$err',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => ref.invalidate(settingsProvider),
                  icon: const Icon(Icons.refresh),
                  label: Text(context.t(AppStr.retry)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmReset() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(dialogContext.t(AppStr.settingsResetTitle)),
        content: Text(dialogContext.t(AppStr.settingsResetBody)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(dialogContext.t(AppStr.cancel))),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(dialogContext.t(AppStr.settingsResetConfirm)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(localPersistenceServiceProvider).clearAll();
      // Restart app or invalidate providers
      if (!mounted) return;
      BizSnackbar.showSuccess(context, context.t(AppStr.settingsResetDone));
    }
  }

  Future<void> _confirmDeleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(dialogContext.t(AppStr.settingsDeleteAccountTitle)),
        content: Text(dialogContext.t(AppStr.settingsDeleteAccountBody)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(dialogContext.t(AppStr.cancel)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(dialogContext.t(AppStr.settingsDeleteAccountConfirm)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await ref.read(authRepositoryProvider).deleteAccount();
      if (!mounted) return;
      BizSnackbar.showSuccess(
          context, context.t(AppStr.settingsDeleteAccountSuccess));
      // Router redirect will handle navigation to login
    } on AuthException catch (e) {
      if (!mounted) return;
      BizSnackbar.showError(context, context.t(AppStr.settingsDeleteAccountError,
          params: {'message': e.message}));
    } catch (e) {
      if (!mounted) return;
      BizSnackbar.showError(context, context.t(AppStr.settingsDeleteAccountUnexpected,
          params: {'error': '$e'}));
    }
  }

  String _themeLabel(BuildContext context, ThemeMode mode) {
    return switch (mode) {
      ThemeMode.system => context.t(AppStr.settingsThemeSystem),
      ThemeMode.light => context.t(AppStr.settingsThemeLight),
      ThemeMode.dark => context.t(AppStr.settingsThemeDark),
    };
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
