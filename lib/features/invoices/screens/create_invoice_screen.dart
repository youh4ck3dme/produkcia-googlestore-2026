import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/invoice_model.dart';
import '../../../core/ui/biz_theme.dart';
import '../../settings/providers/settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../shared/utils/biz_snackbar.dart';
import '../../../core/services/analytics_service.dart';
import '../providers/invoices_provider.dart';
import '../../auth/providers/auth_repository.dart';
import '../../../core/services/icoatlas_service.dart';
import '../../../core/models/ico_lookup_result.dart';
import '../../limits/usage_limiter.dart';
import '../../billing/billing_service.dart';

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

  @override
  void initState() {
    super.initState();
    _loadNextNumber();
    
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
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastNumber = prefs.getInt('invoice_next_number') ?? 1;
      _numberController.text = 'FA-$lastNumber';
    } catch (e) {
      _numberController.text = 'FA-1';
    }
  }

  void _onIcoChanged() {
    final ico = _clientIcoController.text.trim();
    if (ico.length == 8 && (_lookupResult == null || _lookupResult!.name.isEmpty)) {
      _triggerLookup(ico);
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
      BizSnackbar.showError(context, 'Vyplňte popis a cenu');
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
      _itemVatRate = isVatPayer ? 0.20 : 0.0;
    });

    BizSnackbar.showInfo(context, 'Položka pridaná: $itemDesc');
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
    if (!_formKey.currentState!.validate()) return;
    if (_items.isEmpty) {
      BizSnackbar.showError(context, 'Pridajte aspoň jednu položku');
      return;
    }

    final number = _numberController.text.isEmpty
        ? 'FA-${const Uuid().v4().substring(0, 8)}'
        : _numberController.text;
    // Simple VS generation: remove non-digits from number. If empty, use random.
    final vs = number.replaceAll(RegExp(r'[^0-9]'), '');

    final invoice = InvoiceModel(
      id: '',
      userId: '',
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
        BizSnackbar.showSuccess(context, 'Faktúra $number úspešne vytvorená!');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        BizSnackbar.showError(context, 'Chyba pri ukladaní: $e');
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
          vatRate: 0.20,
        ));
      }
      
      _isAiOptimized = true;
      _isDetailsExpanded = false;
    });
    
    BizSnackbar.showSuccess(
      context, 
      'AI: Formulár predvyplnený',
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
    
    BizSnackbar.showInfo(context, 'AI zmeny vrátené späť');
  }

  InputDecoration _aiInputDecoration(String label, String fieldKey) {
    final isAiFilled = _aiPopulatedFields.contains(fieldKey);
    return InputDecoration(
      labelText: label,
      filled: isAiFilled,
      fillColor: isAiFilled ? BizTheme.slovakBlue.withValues(alpha: 0.05) : null,
      suffixIcon: isAiFilled 
        ? const Icon(Icons.auto_awesome, size: 16, color: BizTheme.slovakBlue) 
        : null,
      helperText: isAiFilled ? 'Navrhnuté AI' : null,
      helperStyle: const TextStyle(color: BizTheme.slovakBlue, fontSize: 10),
    );
  }

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
    final settings = settingsAsync.valueOrNull;
    final isVatPayer = settings?.isVatPayer ?? false;

    // Initialize VAT rate once settings are loaded
    if (!_vatRateInitialized && settings != null) {
      _itemVatRate = isVatPayer ? 0.20 : 0.0;
      _vatRateInitialized = true;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nová faktúra'),
        actions: [
          if (_previousStates != null)
            IconButton(
              onPressed: _undoMagicFill,
              icon: const Icon(Icons.undo),
              tooltip: 'Vrátiť AI zmeny',
            ),
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: TextButton.icon(
              onPressed: _applyMagicFill,
              icon: const Icon(Icons.auto_awesome, size: 18),
              label: const Text('AI Vyplniť'),
              style: TextButton.styleFrom(
                backgroundColor: BizTheme.slovakBlue.withValues(alpha: 0.1),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(BizTheme.spacingMd),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(top: BorderSide(color: theme.dividerTheme.color ?? BizTheme.gray100)),
        ),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Spolu: ${NumberFormat.currency(symbol: '€').format(_grandTotal)}',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  if (isVatPayer)
                    Text(
                      'DPH: ${NumberFormat.currency(symbol: '€').format(_totalVat)}',
                      style: theme.textTheme.bodySmall,
                    ),
                ],
              ),
              FilledButton(
                onPressed: _saveInvoice,
                child: const Text('Uložiť'),
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
            Card(
              child: Padding(
                padding: const EdgeInsets.all(BizTheme.spacingMd),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader(context, 'Odberateľ'),
                    const SizedBox(height: BizTheme.spacingMd),
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
                          decoration: _aiInputDecoration('Názov firmy / Meno', 'name'),
                          validator: (v) => v!.isEmpty ? 'Povinné pole' : null,
                        );
                      },
                    ),
                    if (!_isAiOptimized || _isDetailsExpanded) ...[
                      const SizedBox(height: BizTheme.spacingMd),
                      TextFormField(
                        controller: _clientAddressController,
                        decoration: _aiInputDecoration('Sídlo / Adresa', 'address'),
                        maxLines: 2,
                      ),
                      const SizedBox(height: BizTheme.spacingMd),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _clientIcoController,
                              decoration: _aiInputDecoration('IČO', 'ico'),
                            ),
                          ),
                          const SizedBox(width: BizTheme.spacingMd),
                          Expanded(
                            child: TextFormField(
                              controller: _clientDicController,
                              decoration: _aiInputDecoration('DIČ', 'dic'),
                            ),
                          ),
                        ],
                      ),
                      if (_lookupResult != null || _isLookingUp) ...[
                        const SizedBox(height: BizTheme.spacingSm),
                        _buildRiskBadge(),
                      ],
                      const SizedBox(height: BizTheme.spacingMd),
                      TextFormField(
                        controller: _clientIcDphController,
                        decoration: const InputDecoration(labelText: 'IČ DPH (nepovinné)'),
                      ),
                    ] else
                      Padding(
                        padding: const EdgeInsets.only(top: 12.0),
                        child: InkWell(
                          onTap: () => setState(() => _isDetailsExpanded = true),
                          child: Row(
                            children: [
                              Text('Zobraziť fakturačné detaily', 
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
            ),
            const SizedBox(height: BizTheme.spacingMd),

            // Dates & Number
            Card(
              child: Padding(
                padding: const EdgeInsets.all(BizTheme.spacingMd),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _numberController,
                      decoration: const InputDecoration(
                        labelText: 'Číslo faktúry',
                        helperText: 'Generuje sa automaticky (napr. 2026/001)',
                      ),
                    ),
                    const SizedBox(height: BizTheme.spacingMd),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => _pickDate(context, true),
                            child: InputDecorator(
                              decoration: const InputDecoration(labelText: 'Dátum vystavenia'),
                              child: Text(DateFormat('dd.MM.yyyy').format(_dateIssued), style: theme.textTheme.bodyMedium),
                            ),
                          ),
                        ),
                        const SizedBox(width: BizTheme.spacingMd),
                        Expanded(
                          child: InkWell(
                            onTap: () => _pickDate(context, false),
                            child: InputDecorator(
                              decoration: const InputDecoration(labelText: 'Dátum splatnosti'),
                              child: Text(DateFormat('dd.MM.yyyy').format(_dateDue), style: theme.textTheme.bodyMedium),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: BizTheme.spacingMd),

            // Status Selector
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: BizTheme.spacingMd, vertical: BizTheme.spacingSm),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Stav faktúry', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                    DropdownButton<InvoiceStatus>(
                      value: _selectedStatus,
                      underline: const SizedBox(),
                      items: [
                        const DropdownMenuItem(value: InvoiceStatus.draft, child: Text('Návrh')),
                        const DropdownMenuItem(value: InvoiceStatus.sent, child: Text('Odoslaná')),
                      ],
                      onChanged: (val) => setState(() => _selectedStatus = val!),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: BizTheme.spacingMd),

            // Items
            Card(
              child: Padding(
                padding: const EdgeInsets.all(BizTheme.spacingMd),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader(context, 'Položky'),
                    const SizedBox(height: BizTheme.spacingMd),
                    ..._items.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final item = entry.value;
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(item.description, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          '${item.quantity} x ${item.unitPrice} €  (DPH ${(item.vatRate * 100).toInt()}%)',
                          style: theme.textTheme.bodySmall,
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('${item.totalWithVat.toStringAsFixed(2)} €', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                                Text('bez DPH: ${item.subtotal.toStringAsFixed(2)} €', style: theme.textTheme.labelSmall),
                              ],
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: BizTheme.nationalRed),
                              onPressed: () => _removeItem(idx),
                            ),
                          ],
                        ),
                      );
                    }),
                    const Divider(height: 32),
                    // Add Item Row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: TextFormField(controller: _itemDescController, decoration: const InputDecoration(labelText: 'Popis'))),
                        const SizedBox(width: 8),
                        SizedBox(width: 50, child: TextFormField(controller: _itemQtyController, decoration: const InputDecoration(labelText: 'Ks'), keyboardType: TextInputType.number)),
                        const SizedBox(width: 8),
                        SizedBox(width: 80, child: TextFormField(controller: _itemPriceController, decoration: const InputDecoration(labelText: 'Cena/ks'), keyboardType: TextInputType.number)),
                        const SizedBox(width: 8),
                        if (isVatPayer)
                          DropdownButton<double>(
                            value: _itemVatRate,
                            underline: const SizedBox(),
                            items: const [
                              DropdownMenuItem(value: 0.0, child: Text('0%')),
                              DropdownMenuItem(value: 0.1, child: Text('10%')),
                              DropdownMenuItem(value: 0.2, child: Text('20%')),
                            ],
                            onChanged: (val) => setState(() => _itemVatRate = val!),
                          ),
                        IconButton(
                            onPressed: () => _addItem(isVatPayer),
                            icon: const Icon(Icons.add_circle, color: BizTheme.slovakBlue, size: 32)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRiskBadge() {
    if (_isLookingUp) {
      return const Padding(
        padding: EdgeInsets.only(top: 8.0),
        child: Row(
          children: [
            SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2)),
            SizedBox(width: 8),
            Text('Overujem firmu...', style: TextStyle(fontSize: 9.6, color: Colors.grey)), // Reduced by 20% (12 * 0.8)
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
        // AI Verdict Section (High value)
        if (_lookupResult!.headline != null) ...[
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
                      'AI VERDIKT',
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
                'RIZIKO: $risk',
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
    return Text(
      title.toUpperCase(),
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.primary,
        letterSpacing: 1.5,
      ),
    );
  }
}
