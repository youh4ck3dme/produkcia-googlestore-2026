import 'package:flutter/material.dart';
import '../../../../core/utils/platform_image_provider.dart';
import '../../../../shared/utils/biz_snackbar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../core/services/ocr_service.dart';
import '../../../core/services/ai_ocr_service.dart';

import '../models/expense_model.dart';
import '../models/expense_category.dart';
import '../providers/expenses_provider.dart';
import '../services/categorization_service.dart';
import '../services/receipt_storage_service.dart';
import '../widgets/category_selector.dart';
import '../../../core/services/analytics_service.dart';
import '../../auth/providers/auth_repository.dart';

class CreateExpenseScreen extends ConsumerStatefulWidget {
  final String? initialText;

  const CreateExpenseScreen({super.key, this.initialText});

  @override
  ConsumerState<CreateExpenseScreen> createState() =>
      _CreateExpenseScreenState();
}

class _CreateExpenseScreenState extends ConsumerState<CreateExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _vendorController;
  late TextEditingController _descController;
  late TextEditingController _amountController;
  DateTime _date = DateTime.now();

  // Kategorizácia
  ExpenseCategory? _selectedCategory;
  ExpenseCategory? _suggestedCategory;
  int? _suggestionConfidence;
  String? _scannedReceiptPath;

  @override
  void initState() {
    super.initState();
    _vendorController = TextEditingController();
    _descController = TextEditingController(text: widget.initialText);
    _amountController = TextEditingController();

    // Try to extract amount from initial text if present
    if (widget.initialText != null) {
      _tryExtractAmount(widget.initialText!);
    }

    // Listen to vendor changes for auto-categorization
    _vendorController.addListener(_onVendorChanged);
  }

  void _onVendorChanged() async {
    if (_vendorController.text.length >= 3) {
      final user = ref.read(authStateProvider).value;
      if (user == null) return;

      final (category, confidence) = await ref
          .read(categorizationServiceProvider)
          .suggestCategoryWithHistory(_vendorController.text, userId: user.id);

      if (mounted) {
        setState(() {
          _suggestedCategory = category;
          _suggestionConfidence = confidence;

          // Auto-select if confidence is high and no category selected yet
          if (confidence >= 85 && _selectedCategory == null) {
            _selectedCategory = category;
          }
        });
      }
    }
  }

  void _tryExtractAmount(String text) {
    // Simple regex for currency like "12.50" or "12,50"
    final regex = RegExp(r'(\d+[.,]\d{2})');
    final match = regex.firstMatch(text);
    if (match != null) {
      final String amountStr = match.group(0)!.replaceAll(',', '.');
      _amountController.text = amountStr;
    }
  }

  @override
  void dispose() {
    _vendorController.dispose();
    _descController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _scanReceipt() async {
    final ocrService = ref.read(ocrServiceProvider);
    final aiOcrService = ref.read(aiOcrServiceProvider);
    final analytics = ref.read(analyticsServiceProvider);

    // Track start
    analytics.logScanStarted();

    final result = await ocrService.scanReceipt(ImageSource.camera);

    if (result != null && mounted) {
      analytics.logScanSuccess(result.vendorId ?? 'unknown');

      setState(() {
        _scannedReceiptPath = result.imagePath; // Save image path
        _descController.text = result.originalText;

        // Initial quick regex parse
        if (result.totalAmount != null) {
          _amountController.text = result.totalAmount!;
        }
        if (result.vendorId != null) _vendorController.text = result.vendorId!;
        if (result.date != null) _tryParseDate(result.date!);
      });

      // Show "Refining with AI" feedback
      // Show "Refining with AI" feedback
      BizSnackbar.showInfo(context, 'Upravujeme údaje pomocou AI...');

      // AI Refinement
      final refined = await aiOcrService.refineWithAi(result.originalText,
          imagePath: result.imagePath);

      if (refined != null && mounted) {
        setState(() {
          if (refined.totalAmount != null) {
            _amountController.text = refined.totalAmount!;
          }
          if (refined.vendorId != null) {
            _vendorController.text = refined.vendorId!;
          }
          if (refined.date != null) _tryParseDate(refined.date!);
          _onVendorChanged();
        });

        BizSnackbar.showSuccess(
            context, 'Údaje úspešne spracované cez Gemini AI');
      }
    }
  }

  void _tryParseDate(String dateStr) {
    try {
      if (dateStr.contains('.')) {
        final parts = dateStr.split('.');
        if (parts.length == 3) {
          _date = DateTime(
              int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
        }
      } else if (dateStr.contains('-')) {
        _date = DateTime.parse(dateStr);
      }
    } catch (e) {
      debugPrint('Failed to parse date: $dateStr');
    }
  }

  void _showCategorySelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: CategorySelector(
            selectedCategory: _selectedCategory,
            suggestedCategory: _suggestedCategory,
            suggestionConfidence: _suggestionConfidence,
            onCategorySelected: (category) {
              setState(() {
                _selectedCategory = category;
              });
              Navigator.pop(context);
            },
          ),
        ),
      ),
    );
  }

  bool _isSaving = false;

  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final List<String> receiptUrls = [];

      // Upload receipt if exists
      if (_scannedReceiptPath != null) {
        final storageService = ref.read(receiptStorageServiceProvider);

        // Check if it's already a remote URL (unlikely here but good practice)
        if (_scannedReceiptPath!.startsWith('http')) {
          receiptUrls.add(_scannedReceiptPath!);
        } else {
          final url = await storageService.uploadReceipt(_scannedReceiptPath!);
          if (url != null) {
            receiptUrls.add(url);
          }
        }
      }

      final expense = ExpenseModel(
        id: '',
        userId: '',
        vendorName: _vendorController.text,
        description: _descController.text,
        amount:
            double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0.0,
        date: _date,
        category: _selectedCategory,
        categorizationConfidence: _selectedCategory == _suggestedCategory
            ? _suggestionConfidence
            : null,
        isOcrVerified:
            widget.initialText != null || _scannedReceiptPath != null,
        receiptUrls: receiptUrls,
        receiptScannedAt: _scannedReceiptPath != null ? DateTime.now() : null,
      );

      await ref.read(expensesControllerProvider.notifier).addExpense(expense);

      // Track created
      ref.read(analyticsServiceProvider).logExpenseCreated(
            expense.amount,
            expense.category?.name ?? 'other',
          );

      if (mounted) {
        // Show success snackbar instead of dialog for better flow
        BizSnackbar.showSuccess(context, 'Výdavok úspešne pridaný!');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        BizSnackbar.showError(context, 'Chyba: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nový výdavok'),
        actions: [
          IconButton(
            onPressed: _isSaving ? null : _saveExpense,
            icon: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 1. Receipt Preview & Scan Button Area
            if (_scannedReceiptPath != null) ...[
              Container(
                height: 200,
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.grey.shade100,
                  border: Border.all(color: Colors.grey.shade300),
                  image: DecorationImage(
                    image: getPlatformImage(_scannedReceiptPath!),
                    fit: BoxFit.contain,
                  ),
                ),
                child: Stack(
                  children: [
                    // Gradient overlay for text legibility
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 60,
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.vertical(
                              bottom: Radius.circular(16)),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.7)
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Retake button
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: TextButton.icon(
                        onPressed: _scanReceipt,
                        icon: const Icon(Icons.refresh,
                            color: Colors.white, size: 16),
                        label: const Text('Preskenovať',
                            style: TextStyle(color: Colors.white)),
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                    ),
                    // AI Trust Badge
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF7C3AED), // Royal Purple
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF7C3AED)
                                  .withValues(alpha: 0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.auto_awesome,
                                color: Colors.amber, size: 14),
                            SizedBox(width: 6),
                            Text(
                              'Gemini AI',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else
              // Scan Button (Default State)
              Container(
                margin: const EdgeInsets.only(bottom: 24),
                child: ElevatedButton.icon(
                  onPressed: _scanReceipt,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Skenovať bloček (AI)'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    backgroundColor: const Color(0xFFEFF6FF), // Light Blue
                    foregroundColor: const Color(0xFF2563EB), // Primary Blue
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: Color(0xFFBFDBFE)),
                    ),
                  ),
                ),
              ),

            // 2. Form Fields with "Verified" visuals

            TextFormField(
              controller: _vendorController,
              decoration: InputDecoration(
                labelText: 'Obchod / Dodávateľ',
                prefixIcon: const Icon(Icons.store_outlined),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: _vendorController.text.isNotEmpty &&
                        _scannedReceiptPath != null
                    ? const Color(0xFFF0FDF4) // Green tint if populated
                    : Colors.white,
              ),
              validator: (v) => v!.isEmpty ? 'Povinné pole' : null,
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _amountController,
                    decoration: InputDecoration(
                      labelText: 'Suma (€)',
                      prefixIcon: const Icon(Icons.euro),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: _amountController.text.isNotEmpty &&
                              _scannedReceiptPath != null
                          ? const Color(0xFFF0FDF4)
                          : Colors.white,
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Povinné pole';
                      if (double.tryParse(v.replaceAll(',', '.')) == null) {
                        return 'Neplatná suma';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Dátum',
                      prefixIcon: const Icon(Icons.calendar_today_outlined),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _date,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: ColorScheme.light(
                                  primary: Theme.of(context).primaryColor,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null) {
                          setState(() => _date = picked);
                        }
                      },
                      child: Text(
                        DateFormat('dd.MM.yyyy').format(_date),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Category Selector
            InkWell(
              onTap: _showCategorySelector,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.category_outlined, color: Colors.grey),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _selectedCategory != null
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Kategória',
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.grey)),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      _selectedCategory!.icon,
                                      color: _selectedCategory!.color,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _selectedCategory!.displayName,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16),
                                    ),
                                    if (_selectedCategory ==
                                            _suggestedCategory &&
                                        _suggestionConfidence != null)
                                      Padding(
                                        padding: const EdgeInsets.only(left: 8),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.amber
                                                .withValues(alpha: 0.2),
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(Icons.auto_awesome,
                                                  size: 12,
                                                  color: Colors.amber),
                                              const SizedBox(width: 4),
                                              Text(
                                                '$_suggestionConfidence%',
                                                style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    color:
                                                        Colors.amber.shade800),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            )
                          : const Text('Vybrať kategóriu',
                              style: TextStyle(
                                  fontSize: 16, color: Colors.black54)),
                    ),
                    const Icon(Icons.arrow_forward_ios,
                        size: 16, color: Colors.grey),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _descController,
              decoration: InputDecoration(
                labelText: 'Popis / Text bločku',
                alignLabelWithHint: true,
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.description_outlined),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }
}
