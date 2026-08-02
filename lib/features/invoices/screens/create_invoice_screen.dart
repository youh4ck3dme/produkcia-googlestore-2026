import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/invoice_model.dart';
import '../../../core/config/play_release_scope.dart';
import '../../../core/i18n/app_strings.dart';
import '../../../core/i18n/l10n.dart';
import '../../../core/ui/biz_theme.dart';
import '../../settings/providers/settings_provider.dart';
import '../../../shared/utils/biz_snackbar.dart';
import '../../../core/services/analytics_service.dart';
import '../providers/invoices_provider.dart';
import '../providers/invoice_numbering_provider.dart';
import '../../auth/providers/auth_repository.dart';
import '../../../core/services/icoatlas_service.dart';
import '../../../core/services/tax_calculation_service.dart';
import '../../../core/models/ico_lookup_result.dart';
import '../../limits/usage_limiter.dart';
import '../../billing/billing_service.dart';
import '../../billing/paywall_flow.dart';
import '../../billing/subscription_guard.dart';

class CreateInvoiceScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? initialData;
  const CreateInvoiceScreen({super.key, this.initialData});

  @override
  ConsumerState<CreateInvoiceScreen> createState() =>
      _CreateInvoiceScreenState();
}

class _CreateInvoiceScreenState extends ConsumerState<CreateInvoiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _clientNameController = TextEditingController();
  TextEditingController? _clientNameAutocompleteController;
  final _clientAddressController = TextEditingController();
  final _clientIcoController = TextEditingController();
  final _clientDicController = TextEditingController();
  final _clientIcDphController = TextEditingController();
  final _numberController = TextEditingController();
  DateTime _dateIssued = DateTime.now();
  DateTime _dateDue = DateTime.now().add(const Duration(days: 14));

  // Items state
  final List<InvoiceItemModel> _items = [];
  InvoiceStatus _selectedStatus = InvoiceStatus.draft;
  final _itemDescController = TextEditingController();
  final _itemQtyController = TextEditingController();
  final _itemPriceController = TextEditingController();
  double _itemVatRate = 0.0; // Default 0%
  bool _vatRateInitialized = false;
  
  // AI UX State
  bool _isAiOptimized = false;
  bool _isDetailsExpanded = false;
  final Set<String> _aiPopulatedFields = {};
  Map<String, String>? _previousStates;
  List<InvoiceItemModel>? _previousItems;

  // ICO Lookup State
  IcoLookupResult? _lookupResult;
  bool _isLookingUp = false;
  bool _autoInvoiceNumber = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadNextNumber());

    _clientIcoController.addListener(_onIcoChanged);

    // Pre-fill if initial data provided (Funnel from IČO Lookup)
    if (widget.initialData != null) {
      _clientNameController.text = widget.initialData!['clientName'] ?? '';
      _clientIcoController.text = widget.initialData!['clientIco'] ?? '';
      _clientAddressController.text = widget.initialData!['clientAddress'] ?? '';
      _clientDicController.text = widget.initialData!['clientDic'] ?? '';
      _clientIcDphController.text = widget.initialData!['clientIcDph'] ?? '';
      
      if (_clientNameController.text.isNotEmpty) {
        _aiPopulatedFields.addAll(['name', 'ico', 'address', 'dic', 'icDph']);
        _isAiOptimized = true;
      }
    }
  }

  Future<void> _loadNextNumber() async {
    final user = ref.read(authStateProvider).value;
    if (user == null) {
      _numberController.text = '2026/001';
      return;
    }
    try {
      final preview = await ref
          .read(invoiceNumberingServiceProvider)
          .previewNumber(uid: user.id);
      if (mounted) {
        _numberController.text = preview;
      }
    } catch (_) {
      if (mounted) {
        _numberController.text = '2026/001';
      }
    }
  }

  void _onIcoChanged() {
    final normalized = IcoAtlasService.normalizeIco(_clientIcoController.text);
    if (normalized != null &&
        (_lookupResult == null || _lookupResult!.name.isEmpty)) {
      _triggerLookup(normalized);
    }
  }

  Future<void> _triggerLookup(String ico) async {
    if (_isLookingUp) return;

    setState(() {
      _isLookingUp = true;
    });

    try {
      final authUser = ref.read(authStateProvider).value;
      IcoLookupResult? result;
      final service = ref.read(icoAtlasServiceProvider);

      if (authUser != null && !authUser.isAnonymous) {
        final token = await ref.read(authRepositoryProvider).currentUserToken;
        if (token != null) {
          result = await service.secureLookup(ico, token);
        }
      }
      
      // Fallback or public lookup if not secure
      result ??= await service.publicLookup(ico);

      if (result != null && result.name.isNotEmpty) {
        setState(() {
          _lookupResult = result;
          _clientNameController.text = result?.name ?? "";
          _clientNameAutocompleteController?.text = result?.name ?? "";
          _clientAddressController.text = result?.fullAddress ?? "";
          _clientDicController.text = result?.dic ?? '';
          _clientIcDphController.text = result?.icDph ?? '';
          _isAiOptimized = true;
          _aiPopulatedFields.addAll(['name', 'address', 'dic', 'icDph']);
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLookingUp = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _clientIcoController.removeListener(_onIcoChanged);
    _clientNameController.dispose();
    _clientAddressController.dispose();
    _clientIcoController.dispose();
    _clientDicController.dispose();
    _clientIcDphController.dispose();
    _numberController.dispose();
    _itemDescController.dispose();
    _itemQtyController.dispose();
    _itemPriceController.dispose();
    super.dispose();
  }

  void _addItem(bool isVatPayer) {
    if (_itemDescController.text.isEmpty || _itemPriceController.text.isEmpty) {
      BizSnackbar.showError(context, context.t(AppStr.createInvoiceAddItemError));
      return;
    }

    final qty = double.tryParse(_itemQtyController.text) ?? 1.0;
    final price = double.tryParse(_itemPriceController.text) ?? 0.0;
    final amount = qty * price; // NET amount
    final itemDesc = _itemDescController.text;

    setState(() {
      _items.add(InvoiceItemModel(
        title: itemDesc,
        amount: amount,
        vatRate: _itemVatRate,
      ));
      _itemDescController.clear();
      _itemQtyController.clear();
      _itemPriceController.clear();
      // Reset to default
      _itemVatRate = TaxCalculationService.defaultVatRateForPayer(isVatPayer);
    });

    BizSnackbar.showInfo(context, context.t(AppStr.createInvoiceItemAdded,
        params: {'item': itemDesc}));
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  double get _totalBeforeVat =>
      _items.fold(0, (total, item) => total + item.subtotal);
  double get _totalVat =>
      _items.fold(0, (total, item) => total + item.vatAmount);
  double get _grandTotal => _totalBeforeVat + _totalVat;

  Future<void> _saveInvoice() async {
    if (!await PaywallFlow.ensureAccess(context, ref, BizFeature.createInvoice)) return;
    if (!_formKey.currentState!.validate()) return;
    if (_items.isEmpty) {
      BizSnackbar.showError(context, context.t(AppStr.createInvoiceMinOneItem));
      return;
    }

    final user = ref.read(authStateProvider).value ??
        ref.read(authRepositoryProvider).currentUser;
    if (user == null) {
      BizSnackbar.showError(context, context.t(AppStr.bizBotAuthRequired));
      return;
    }

    String number = _numberController.text.trim();
    if (_autoInvoiceNumber && user != null) {
      final result = await ref
          .read(invoiceNumberingServiceProvider)
          .nextNumber(uid: user.id, now: _dateIssued);
      number = result.number;
    } else if (number.isEmpty) {
      number = 'FA-${const Uuid().v4().substring(0, 8)}';
    }
    // Simple VS generation: remove non-digits from number. If empty, use random.
    final vs = number.replaceAll(RegExp(r'[^0-9]'), '');

    final invoice = InvoiceModel(
      id: '',
      userId: user.id,
      createdAt: DateTime.now(),
      number: number,
      clientName: _clientNameController.text,
      clientAddress: _clientAddressController.text,
      clientIco: _clientIcoController.text,
      clientDic: _clientDicController.text,
      clientIcDph: _clientIcDphController.text,
      dateIssued: _dateIssued,
      dateDue: _dateDue,
      items: _items,
      totalAmount: _grandTotal,
      status: _selectedStatus,
      variableSymbol: vs.isEmpty ? '0000' : vs,
      constantSymbol: '0308',
    );

    try {
      await ref.read(invoicesControllerProvider.notifier).addInvoice(invoice);

      // Helper: Track usage
      await ref.read(usageLimiterProvider).incrementInvoice();
      ref.read(billingProvider.notifier).refreshUsage();

      // Track created
      ref.read(analyticsServiceProvider).logInvoiceCreated(invoice.totalAmount);

      if (mounted) {
        BizSnackbar.showSuccess(context, context.t(AppStr.createInvoiceCreatedToast,
            params: {'number': number}));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        BizSnackbar.showError(context, context.t(AppStr.createInvoiceSaveError,
            params: {'error': '$e'}));
      }
    }
  }

  void _applyMagicFill() {
    // Uložiť predchádzajúci stav pre Undo
    _previousStates = {
      'name': _clientNameController.text,
      'address': _clientAddressController.text,
      'ico': _clientIcoController.text,
      'dic': _clientDicController.text,
    };
    _previousItems = List.from(_items);

    setState(() {
      _clientNameController.text = 'Oatmeal Digital s.r.o.';
      _clientNameAutocompleteController?.text = _clientNameController.text;
      _clientIcoController.text = '53123456';
      _clientDicController.text = '2121234567';
      _clientAddressController.text = 'Mýtna 1, 811 07 Bratislava';
      
      _aiPopulatedFields.addAll(['name', 'ico', 'dic', 'address']);
      
      if (_items.isEmpty) {
        _items.add(InvoiceItemModel(
          title: 'Mesačný paušál - správa kampaní',
          amount: 450.0,
          vatRate: TaxCalculationService.vatStandardRate,
        ));
      }
      
      _isAiOptimized = true;
      _isDetailsExpanded = false;
    });
    
      BizSnackbar.showSuccess(
      context,
      context.t(AppStr.createInvoiceFormPrefilled),
    );
    
    // Tu by sa dal pridať ScaffoldMessenger pre Undo akciu, 
    // ale BizSnackbar momentálne nepodporuje actions. 
    // Použijeme aspoň internú logiku.
  }

  void _undoMagicFill() {
    if (_previousStates == null) return;
    
    setState(() {
      _clientNameController.text = _previousStates!['name'] ?? '';
      _clientNameAutocompleteController?.text = _clientNameController.text;
      _clientAddressController.text = _previousStates!['address'] ?? '';
      _clientIcoController.text = _previousStates!['ico'] ?? '';
      _clientDicController.text = _previousStates!['dic'] ?? '';
      
      if (_previousItems != null) {
        _items.clear();
        _items.addAll(_previousItems!);
      }
      
      _aiPopulatedFields.clear();
      _isAiOptimized = false;
      _previousStates = null;
    });
    
    BizSnackbar.showInfo(context, context.t(AppStr.createInvoiceUndoDone));
  }

  InputDecoration _fieldDecoration(
    String label, {
    String? fieldKey,
    String? helperText,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isAiFilled = fieldKey != null &&
        PlayReleaseScope.showInvoiceAiFeatures &&
        _aiPopulatedFields.contains(fieldKey);
    final aiBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(BizTheme.inputRadius),
      borderSide: BorderSide(
        color: BizTheme.slovakBlue.withValues(alpha: 0.4),
        width: 1,
      ),
    );
    final aiFocusedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(BizTheme.inputRadius),
      borderSide: const BorderSide(color: BizTheme.slovakBlue, width: 2),
    );

    return InputDecoration(
      labelText: label,
      helperText:
          isAiFilled ? context.t(AppStr.createInvoiceAiPrefilled) : helperText,
      helperStyle: isAiFilled
          ? const TextStyle(color: BizTheme.slovakBlue, fontSize: 10)
          : null,
      filled: true,
      fillColor: isAiFilled
          ? BizTheme.slovakBlue.withValues(alpha: 0.04)
          : (isDark ? BizTheme.darkSurfaceVariant : BizTheme.tatraWhite),
      suffixIcon: isAiFilled
          ? const Icon(Icons.check_circle_outline,
              size: 16, color: BizTheme.slovakBlue)
          : null,
      enabledBorder: isAiFilled ? aiBorder : null,
      focusedBorder: isAiFilled ? aiFocusedBorder : null,
    );
  }

  Widget _buildFormSection({required Widget child}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BizTheme.formSectionDecoration(isDark: isDark),
      padding: const EdgeInsets.all(BizTheme.spacingMd),
      child: child,
    );
  }

  static const _fieldGap = 12.0;
  static const _sectionGap = 20.0;

  Future<void> _pickDate(BuildContext context, bool isIssued) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isIssued ? _dateIssued : _dateDue,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isIssued) {
          _dateIssued = picked;
        } else {
          _dateDue = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // final isDark = theme.brightness == Brightness.dark;
    final settingsAsync = ref.watch(settingsProvider);
    final settings = settingsAsync.value;
    final isVatPayer = settings?.isVatPayer ?? false;

    // Initialize VAT rate once settings are loaded
    if (!_vatRateInitialized && settings != null) {
      _itemVatRate = TaxCalculationService.defaultVatRateForPayer(isVatPayer);
      _vatRateInitialized = true;
    }

    return Scaffold(
      backgroundColor: theme.brightness == Brightness.dark
          ? BizTheme.darkSurface
          : BizTheme.gray50,
      appBar: AppBar(
        title: Text(context.t(AppStr.createInvoiceTitle)),
        actions: [
          if (PlayReleaseScope.showInvoiceAiFeatures) ...[
            if (_previousStates != null)
              IconButton(
                onPressed: _undoMagicFill,
                icon: const Icon(Icons.undo),
                tooltip: context.t(AppStr.createInvoiceUndo),
              ),
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: IconButton(
                onPressed: _applyMagicFill,
                icon: const Icon(Icons.auto_awesome, size: 20),
                tooltip: context.t(AppStr.createInvoiceAiFill),
                style: IconButton.styleFrom(
                  backgroundColor: BizTheme.slovakBlue.withValues(alpha: 0.1),
                ),
              ),
            ),
          ],
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(BizTheme.spacingMd),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: const Border(top: BorderSide(color: BizTheme.gray200)),
          boxShadow: [
            BoxShadow(
              color: BizTheme.slovakBlue.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.t(AppStr.summaryTotal),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: BizTheme.gray500,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      NumberFormat.currency(symbol: '€').format(_grandTotal),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: BizTheme.slovakBlue,
                      ),
                    ),
                    if (isVatPayer)
                      Text(
                        context.t(AppStr.createInvoiceVatSummary, params: {
                          'amount':
                              NumberFormat.currency(symbol: '€').format(_totalVat),
                        }),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: BizTheme.gray500,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              FilledButton(
                onPressed: _saveInvoice,
                child: Text(context.t(AppStr.save)),
              ),
            ],
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(BizTheme.spacingMd),
          children: [
            // Client Info
            _buildFormSection(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(
                      context, context.t(AppStr.createInvoiceClientSection)),
                  const SizedBox(height: _fieldGap),
                    Autocomplete<Map<String, dynamic>>(
                      optionsBuilder: (TextEditingValue textEditingValue) async {
                        if (textEditingValue.text.length < 2) return [];
                        return await ref.read(icoAtlasServiceProvider).autocomplete(textEditingValue.text);
                      },
                      displayStringForOption: (option) => option['name'] ?? '',
                      onSelected: (Map<String, dynamic> selection) {
                        setState(() {
                          _clientNameController.text = selection['name'] ?? '';
                          _clientNameAutocompleteController?.text = _clientNameController.text;
                          _clientIcoController.text = selection['ico'] ?? selection['cin'] ?? '';
                          _clientDicController.text = selection['dic'] ?? selection['tin'] ?? '';
                          _clientAddressController.text = selection['formatted_address'] ?? selection['address'] ?? '';
                          _clientIcDphController.text = selection['v_tin'] ?? selection['ic_dph'] ?? '';
                          _isDetailsExpanded = true; 
                        });
                      },
                      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                        _clientNameAutocompleteController ??= controller;

                        // Keep the Autocomplete's internal controller in sync with our source-of-truth
                        // controller, but do it post-frame to avoid triggering Form rebuilds during build.
                        if (controller.text != _clientNameController.text) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (!mounted) return;
                            final c = _clientNameAutocompleteController;
                            if (c == null) return;
                            if (c.text == _clientNameController.text) return;
                            final text = _clientNameController.text;
                            c.value = c.value.copyWith(
                              text: text,
                              selection: TextSelection.collapsed(offset: text.length),
                              composing: TextRange.empty,
                            );
                          });
                        }
                        return TextFormField(
                          controller: controller,
                          focusNode: focusNode,
                          onChanged: (value) {
                            _clientNameController.text = value;
                          },
                          decoration: _fieldDecoration(
                              context.t(AppStr.createInvoiceClientName),
                              fieldKey: 'name'),
                          validator: (v) => v!.isEmpty
                              ? context.t(AppStr.createInvoiceRequiredField)
                              : null,
                        );
                      },
                    ),
                    if (!_isAiOptimized || _isDetailsExpanded) ...[
                      const SizedBox(height: _fieldGap),
                      TextFormField(
                        controller: _clientAddressController,
                        decoration: _fieldDecoration(
                            context.t(AppStr.createInvoiceClientAddress),
                            fieldKey: 'address'),
                        maxLines: 2,
                      ),
                      const SizedBox(height: _fieldGap),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _clientIcoController,
                              decoration: _fieldDecoration(
                                  context.t(AppStr.icoLabel), fieldKey: 'ico'),
                            ),
                          ),
                          const SizedBox(width: _fieldGap),
                          Expanded(
                            child: TextFormField(
                              controller: _clientDicController,
                              decoration: _fieldDecoration(
                                  context.t(AppStr.dicLabel), fieldKey: 'dic'),
                            ),
                          ),
                        ],
                      ),
                      if (_lookupResult != null || _isLookingUp) ...[
                        const SizedBox(height: BizTheme.spacingSm),
                        _buildRiskBadge(),
                      ],
                      const SizedBox(height: _fieldGap),
                      TextFormField(
                        controller: _clientIcDphController,
                        decoration: _fieldDecoration(
                            context.t(AppStr.createInvoiceIcDphOptional),
                            fieldKey: 'icDph'),
                      ),
                    ] else
                      Padding(
                        padding: const EdgeInsets.only(top: 12.0),
                        child: InkWell(
                          onTap: () => setState(() => _isDetailsExpanded = true),
                          child: Row(
                            children: [
                              Text(context.t(AppStr.createInvoiceShowDetails), 
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: BizTheme.slovakBlue,
                                  fontWeight: FontWeight.bold,
                                )),
                              const Icon(Icons.keyboard_arrow_down, color: BizTheme.slovakBlue, size: 20),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            const SizedBox(height: _sectionGap),

            // Dates & Number
            _buildFormSection(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(
                      context, context.t(AppStr.createInvoiceDetailsSection)),
                  const SizedBox(height: _fieldGap),
                    TextFormField(
                      controller: _numberController,
                      onChanged: (_) => _autoInvoiceNumber = false,
                      decoration: _fieldDecoration(
                        context.t(AppStr.invoiceNumber),
                        helperText: context.t(AppStr.invoiceNumberHelper),
                      ),
                    ),
                    const SizedBox(height: _fieldGap),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => _pickDate(context, true),
                            borderRadius: BorderRadius.circular(BizTheme.inputRadius),
                            child: InputDecorator(
                              decoration: _fieldDecoration(
                                  context.t(AppStr.createInvoiceIssueDate)),
                              child: Text(DateFormat('dd.MM.yyyy').format(_dateIssued), style: theme.textTheme.bodyMedium),
                            ),
                          ),
                        ),
                        const SizedBox(width: _fieldGap),
                        Expanded(
                          child: InkWell(
                            onTap: () => _pickDate(context, false),
                            borderRadius: BorderRadius.circular(BizTheme.inputRadius),
                            child: InputDecorator(
                              decoration: _fieldDecoration(
                                  context.t(AppStr.createInvoiceDueDate)),
                              child: Text(DateFormat('dd.MM.yyyy').format(_dateDue), style: theme.textTheme.bodyMedium),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            const SizedBox(height: _sectionGap),

            // Status Selector
            _buildFormSection(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSectionHeader(
                      context, context.t(AppStr.createInvoiceStatusSection)),
                  DropdownButton<InvoiceStatus>(
                    value: _selectedStatus,
                    underline: const SizedBox(),
                    borderRadius: BorderRadius.circular(BizTheme.radiusMd),
                    items: [
                      DropdownMenuItem(
                        value: InvoiceStatus.draft,
                        child: Text(
                            InvoiceStatus.draft.label(context)),
                      ),
                      DropdownMenuItem(
                        value: InvoiceStatus.sent,
                        child: Text(InvoiceStatus.sent.label(context)),
                      ),
                    ],
                    onChanged: (val) => setState(() => _selectedStatus = val!),
                  ),
                ],
              ),
            ),
            const SizedBox(height: _sectionGap),

            // Items
            _buildFormSection(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(context, context.t(AppStr.invoiceItems)),
                  const SizedBox(height: _fieldGap),
                    ..._items.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final item = entry.value;
                      return Container(
                        margin: const EdgeInsets.only(bottom: _fieldGap),
                        padding: const EdgeInsets.symmetric(
                          horizontal: BizTheme.spacingSm,
                          vertical: BizTheme.spacingSm,
                        ),
                        decoration: BoxDecoration(
                          color: BizTheme.gray50,
                          borderRadius: BorderRadius.circular(BizTheme.radiusMd),
                          border: Border.all(color: BizTheme.gray200),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.description,
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${item.quantity} x ${item.unitPrice} €  (DPH ${(item.vatRate * 100).toInt()}%)',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: BizTheme.gray500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${item.totalWithVat.toStringAsFixed(2)} €',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: BizTheme.slovakBlue,
                                  ),
                                ),
                                Text(
                                  context.t(AppStr.createInvoiceExclVat, params: {
                                    'amount': item.subtotal.toStringAsFixed(2),
                                  }),
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: BizTheme.gray500,
                                  ),
                                ),
                              ],
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  color: BizTheme.nationalRed, size: 20),
                              onPressed: () => _removeItem(idx),
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                        ),
                      );
                    }),
                    if (_items.isNotEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: _fieldGap),
                        child: Divider(color: BizTheme.gray200, height: 1),
                      ),
                    // Add Item Row
                    Container(
                      padding: const EdgeInsets.all(BizTheme.spacingSm),
                      decoration: BoxDecoration(
                        color: BizTheme.gray50,
                        borderRadius: BorderRadius.circular(BizTheme.radiusMd),
                        border: Border.all(color: BizTheme.gray200),
                      ),
                      child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: TextFormField(controller: _itemDescController, decoration: _fieldDecoration(context.t(AppStr.createInvoiceItemDesc)))),
                        const SizedBox(width: 8),
                        SizedBox(width: 56, child: TextFormField(controller: _itemQtyController, decoration: _fieldDecoration(context.t(AppStr.createInvoiceItemQty)), keyboardType: TextInputType.number)),
                        const SizedBox(width: 8),
                        SizedBox(width: 88, child: TextFormField(controller: _itemPriceController, decoration: _fieldDecoration(context.t(AppStr.createInvoiceItemPrice)), keyboardType: TextInputType.number)),
                        const SizedBox(width: 8),
                        if (isVatPayer)
                          DropdownButton<double>(
                            value: _itemVatRate,
                            underline: const SizedBox(),
                            borderRadius: BorderRadius.circular(BizTheme.radiusMd),
                            items: TaxCalculationService.vatRates
                                .map(
                                  (rate) => DropdownMenuItem(
                                    value: rate,
                                    child: Text(
                                      TaxCalculationService.vatRateLabel(rate),
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) => setState(() => _itemVatRate = val!),
                          ),
                        OutlinedButton(
                          onPressed: () => _addItem(isVatPayer),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(44, 44),
                            padding: EdgeInsets.zero,
                            shape: const CircleBorder(),
                            side: const BorderSide(color: BizTheme.slovakBlue, width: 1.5),
                          ),
                          child: const Icon(Icons.add, color: BizTheme.slovakBlue, size: 22),
                        ),
                      ],
                    ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRiskBadge() {
    if (_isLookingUp) {
      return Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: Row(
          children: [
            const SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(strokeWidth: 2)),
            const SizedBox(width: 8),
            Text(context.t(AppStr.createInvoiceLookingUp),
                style: const TextStyle(fontSize: 9.6, color: Colors.grey)),
          ],
        ),
      );
    }

    if (_lookupResult == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final risk = _lookupResult!.riskLevel?.toUpperCase() ?? 'LOW';
    final color = switch (risk) {
      'HIGH' => BizTheme.nationalRed,
      'MEDIUM' => Colors.orange,
      'LOW' => Colors.green,
      _ => Colors.blue,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        // Risk / IČO lookup (Play MVP: bez AI verdict copy)
        if (PlayReleaseScope.showIcoRiskVerdict &&
            _lookupResult!.headline != null) ...[
          Container(
            padding: const EdgeInsets.all(BizTheme.spacingMd),
            decoration: BoxDecoration(
              color: BizTheme.slovakBlue.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(BizTheme.radiusMd),
              border: Border.all(color: BizTheme.slovakBlue.withValues(alpha: 0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.auto_awesome, color: BizTheme.slovakBlue, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      context.t(AppStr.createInvoiceAiVerdict),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: BizTheme.slovakBlue,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _lookupResult!.headline!,
                  style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                if (_lookupResult!.explanation != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2.0),
                    child: Text(
                      _lookupResult!.explanation!,
                      style: theme.textTheme.bodySmall?.copyWith(fontSize: 11, height: 1.3),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
        // Risk Status Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                risk == 'HIGH' ? Icons.warning_amber_rounded : (risk == 'MEDIUM' ? Icons.info_outline : Icons.check_circle_outline),
                size: 12,
                color: color,
              ),
              const SizedBox(width: 4),
              Text(
                context.t(AppStr.createInvoiceRiskLabel, params: {'risk': risk}),
                style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
              ),
              if (_lookupResult!.confidence != null) ...[
                const SizedBox(width: 4),
                Text(
                  '(${( _lookupResult!.confidence! * 100).toInt()}%)',
                  style: TextStyle(color: color.withValues(alpha: 0.7), fontSize: 9),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: BizTheme.slovakBlue,
            letterSpacing: 0.08 * 16,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 2,
          width: 28,
          decoration: BoxDecoration(
            color: BizTheme.slovakBlue.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(1),
          ),
        ),
      ],
    );
  }
}
