import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/ai_tax_assistant_service.dart';
import '../../../shared/widgets/biz_card.dart';
import '../../../shared/widgets/biz_buttons.dart';
import '../../../core/ui/biz_theme.dart';

class AiExpenseAnalysisScreen extends ConsumerStatefulWidget {
  const AiExpenseAnalysisScreen({super.key});

  @override
  ConsumerState<AiExpenseAnalysisScreen> createState() => _AiExpenseAnalysisScreenState();
}

class _AiExpenseAnalysisScreenState extends ConsumerState<AiExpenseAnalysisScreen> {
  final _expenseNameController = TextEditingController();
  VatAnalysisResult? _result;
  bool _isLoading = false;

  Future<void> _analyze() async {
    final name = _expenseNameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final service = ref.read(aiTaxAssistantServiceProvider);
      final result = await service.analyzeExpenseItem(name, 100.0); 
      setState(() => _result = result);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('DPH Asistent')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            BizCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Rýchla analýza daňovej uznateľnosti', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _expenseNameController,
                    decoration: const InputDecoration(
                      labelText: 'Názov položky (napr. Obed s klientom)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  BizPrimaryButton(
                    onPressed: _analyze,
                    label: _isLoading ? 'Analyzujem...' : 'Skontrolovať',
                    isLoading: _isLoading,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            if (_result != null)
              _buildResultCard(context, _result!),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(BuildContext context, VatAnalysisResult result) {
    return BizCard(
      child: Column(
        children: [
          Icon(
            result.isTaxDeductible ? Icons.check_circle : Icons.warning_amber_rounded,
            size: 64,
            color: result.isTaxDeductible ? BizTheme.successGreen : BizTheme.warningAmber,
          ),
          const SizedBox(height: 16),
          Text(
            result.isTaxDeductible ? 'Pravdepodobne daňovo uznateľné' : 'Rizikový výdavok',
            style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(result.itemCategory, style: const TextStyle(fontWeight: FontWeight.bold)),
          if (result.warningMessage != null) ...[
             const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: BizTheme.warningAmber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: BizTheme.warningAmber.withValues(alpha: 0.3)),
                ),
               child: Row(
                 children: [
                   const Icon(Icons.info_outline, color: BizTheme.warningAmber),
                   const SizedBox(width: 12),
                   Expanded(child: Text(result.warningMessage!)),
                 ],
               ),
             )
          ]
        ],
      ),
    );
  }
}
