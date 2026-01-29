import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_settings_model.dart';
import '../providers/settings_provider.dart';
import '../../../core/ui/biz_theme.dart';
import '../../../shared/utils/biz_snackbar.dart';
import '../../../core/services/company_lookup_service.dart';
import '../../../core/services/icoatlas_service.dart';
import '../../../shared/widgets/watched_company_button.dart';

class BusinessProfileScreen extends ConsumerStatefulWidget {
  const BusinessProfileScreen({super.key});

  @override
  ConsumerState<BusinessProfileScreen> createState() => _BusinessProfileScreenState();
}

class _BusinessProfileScreenState extends ConsumerState<BusinessProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _icoController;
  late TextEditingController _dicController;
  late TextEditingController _icDphController;
  late TextEditingController _ibanController;
  late TextEditingController _swiftController;
  late TextEditingController _registerInfoController;
  bool _isLookingUp = false;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsProvider).valueOrNull ?? UserSettingsModel.empty();
    _nameController = TextEditingController(text: settings.companyName);
    _addressController = TextEditingController(text: settings.companyAddress);
    _icoController = TextEditingController(text: settings.companyIco);
    _dicController = TextEditingController(text: settings.companyDic);
    _icDphController = TextEditingController(text: settings.companyIcDph);
    _ibanController = TextEditingController(text: settings.bankAccount);
    _swiftController = TextEditingController(text: settings.swift);
    _registerInfoController = TextEditingController(text: settings.registerInfo);
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
    _registerInfoController.dispose();
    super.dispose();
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
        BizSnackbar.showSuccess(context, 'Údaje firmy boli aktualizované');
      }
    } catch (e) {
      if (mounted) {
        BizSnackbar.showError(context, 'Chyba pri hľadaní: $e');
      }
    } finally {
      if (mounted) setState(() => _isLookingUp = false);
    }
  }

  void _save() async {
    if (_formKey.currentState!.validate()) {
      final current = ref.read(settingsProvider).valueOrNull ?? UserSettingsModel.empty();
      final updated = current.copyWith(
        companyName: _nameController.text,
        companyAddress: _addressController.text,
        companyIco: _icoController.text,
        companyDic: _dicController.text,
        companyIcDph: _icDphController.text,
        bankAccount: _ibanController.text,
        swift: _swiftController.text,
        registerInfo: _registerInfoController.text,
      );

      await ref.read(settingsControllerProvider.notifier).updateSettings(updated);
      
      if (mounted) {
        BizSnackbar.showSuccess(context, 'Profil firmy bol úspešne uložený');
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = ref.watch(settingsProvider).valueOrNull ?? UserSettingsModel.empty();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil firmy'),
        actions: [
          if (settings.companyIco.isNotEmpty)
            WatchedCompanyButton(
              icoNorm: settings.companyIco.replaceAll(RegExp(r'\D'), ''),
              name: settings.companyName,
              activeColor: Colors.white,
              inactiveColor: Colors.white70,
            ),
          IconButton(
            onPressed: _save,
            icon: const Icon(Icons.check),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(BizTheme.spacingLg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, 'Základné údaje'),
              const SizedBox(height: BizTheme.spacingMd),
              Autocomplete<Map<String, dynamic>>(
                optionsBuilder: (TextEditingValue textEditingValue) async {
                  if (textEditingValue.text.length < 2) return [];
                  return await ref.read(icoAtlasServiceProvider).autocomplete(textEditingValue.text);
                },
                displayStringForOption: (option) => option['name'] ?? '',
                onSelected: (Map<String, dynamic> selection) {
                  setState(() {
                    _nameController.text = selection['name'] ?? '';
                    _icoController.text = selection['ico'] ?? selection['cin'] ?? '';
                    _addressController.text = selection['formatted_address'] ?? selection['address'] ?? '';
                    _dicController.text = selection['dic'] ?? selection['tin'] ?? '';
                    _icDphController.text = selection['v_tin'] ?? selection['ic_dph'] ?? '';
                  });
                },
                fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                  if (controller.text != _nameController.text && _nameController.text.isNotEmpty && controller.text.isEmpty) {
                    controller.text = _nameController.text;
                  }
                  controller.addListener(() {
                    _nameController.text = controller.text;
                  });

                  return _buildTextField(
                    context,
                    controller: controller,
                    focusNode: focusNode,
                    label: 'Obchodné meno',
                    icon: Icons.business,
                    validator: (v) => v!.isEmpty ? 'Zadajte obchodné meno' : null,
                  );
                },
              ),
              const SizedBox(height: BizTheme.spacingMd),
              _buildTextField(
                context,
                controller: _addressController,
                label: 'Sídlo / Adresa',
                icon: Icons.location_on_outlined,
                maxLines: 2,
                validator: (v) => v!.isEmpty ? 'Zadajte adresu' : null,
              ),
              const SizedBox(height: BizTheme.spacingMd),
               _buildTextField(
                context,
                controller: _registerInfoController,
                label: 'Registrácia (OR SR / ŽR SR)',
                icon: Icons.info_outline,
                placeholder: 'Zapísaná v OR OS Bratislava I...',
              ),
              const SizedBox(height: BizTheme.spacingLg),
              
              _buildHeader(context, 'Identifikačné údaje'),
              const SizedBox(height: BizTheme.spacingMd),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildTextField(
                      context,
                      controller: _icoController,
                      label: 'IČO',
                      icon: Icons.numbers,
                      suffix: _isLookingUp
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : IconButton(
                              icon: const Icon(Icons.search, size: 20),
                              onPressed: _lookupCompany,
                            ),
                      validator: (v) => v!.isEmpty ? 'Povinné' : null,
                    ),
                  ),
                  const SizedBox(width: BizTheme.spacingMd),
                  Expanded(
                    child: _buildTextField(
                      context,
                      controller: _dicController,
                      label: 'DIČ',
                      icon: Icons.tag,
                      validator: (v) => v!.isEmpty ? 'Povinné' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: BizTheme.spacingMd),
              _buildTextField(
                context,
                controller: _icDphController,
                label: 'IČ DPH',
                icon: Icons.receipt_long,
                placeholder: 'SK1020304050',
              ),
              const SizedBox(height: BizTheme.spacingSm),
              SwitchListTile(
                 title: Text('Platca DPH', style: theme.textTheme.bodyMedium),
                 value: settings.isVatPayer,
                 contentPadding: EdgeInsets.zero,
                 onChanged: (val) {
                   ref.read(settingsControllerProvider.notifier).updateVatPayer(val);
                 },
              ),
              const SizedBox(height: BizTheme.spacingLg),

              _buildHeader(context, 'Bankové spojenie'),
              const SizedBox(height: BizTheme.spacingMd),
              _buildTextField(
                context,
                controller: _ibanController,
                label: 'IBAN',
                icon: Icons.account_balance,
                validator: (v) => v!.isEmpty ? 'Zadajte IBAN' : null,
              ),
              const SizedBox(height: BizTheme.spacingMd),
              _buildTextField(
                context,
                controller: _swiftController,
                label: 'SWIFT / BIC',
                icon: Icons.language,
              ),
              
              const SizedBox(height: BizTheme.spacing3xl),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _save,
                  child: const Text('ULOŽIŤ PROFIL'),
                ),
              ),
              const SizedBox(height: BizTheme.spacingXl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String title) {
    return Text(
      title.toUpperCase(),
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.primary,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildTextField(
    BuildContext context, {
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? placeholder,
    int maxLines = 1,
    Widget? suffix,
    FocusNode? focusNode,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: placeholder,
        prefixIcon: Icon(icon),
        suffixIcon: suffix,
      ),
    );
  }
}
