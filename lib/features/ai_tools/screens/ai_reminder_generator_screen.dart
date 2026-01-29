import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/ai_reminder_service.dart';
import '../../../shared/widgets/biz_card.dart';
import '../../../shared/widgets/biz_buttons.dart';
import '../../../core/ui/biz_theme.dart';

class AiReminderGeneratorScreen extends ConsumerStatefulWidget {
  const AiReminderGeneratorScreen({super.key});

  @override
  ConsumerState<AiReminderGeneratorScreen> createState() => _AiReminderGeneratorScreenState();
}

class _AiReminderGeneratorScreenState extends ConsumerState<AiReminderGeneratorScreen> {
  // Inputs
  final _clientNameController = TextEditingController(text: 'Firma s.r.o.');
  final _daysOverdueController = TextEditingController(text: '7');
  
  double _toneValue = 1.0; // 0=Polite, 1=Professional, 2=Strict
  String? _generatedText;
  bool _isGenerating = false;

  Future<void> _generate() async {
    setState(() => _isGenerating = true);
    
    // Convert slider value to enum
    ReminderTone tone;
    if (_toneValue < 0.5) {
      tone = ReminderTone.polite;
    } else if (_toneValue > 1.5) {
      tone = ReminderTone.strict;
    } else {
      tone = ReminderTone.professional;
    }

    final service = ref.read(aiReminderServiceProvider);
    final text = await service.generateReminderText(
      clientName: _clientNameController.text,
      invoiceNumber: '2026/042',
      amount: 1250.00,
      daysOverdue: int.tryParse(_daysOverdueController.text) ?? 0,
      tone: tone,
    );

    setState(() {
      _generatedText = text;
      _isGenerating = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI Generátor Upomienok')),
      body: SingleChildScrollView(
         padding: const EdgeInsets.all(16),
         child: Column(
           crossAxisAlignment: CrossAxisAlignment.stretch,
           children: [
             BizCard(
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   const Text('Parametre upomienky', style: TextStyle(fontWeight: FontWeight.bold)),
                   const SizedBox(height: 16),
                   TextField(controller: _clientNameController, decoration: const InputDecoration(labelText: 'Klient')),
                   const SizedBox(height: 12),
                   TextField(controller: _daysOverdueController, decoration: const InputDecoration(labelText: 'Dni po splatnosti'), keyboardType: TextInputType.number),
                   
                   const SizedBox(height: 24),
                   const Text('Tón komunikácie (Tone of Voice)', style: TextStyle(fontWeight: FontWeight.bold)),
                   Slider(
                     value: _toneValue,
                     min: 0,
                     max: 2,
                     divisions: 2,
                     activeColor: BizTheme.slovakBlue,
                     inactiveColor: BizTheme.gray200,
                     label: _getToneLabel(_toneValue),
                     onChanged: (val) => setState(() => _toneValue = val),
                   ),
                   Center(child: Text(_getToneLabel(_toneValue), style: const TextStyle(color: BizTheme.slovakBlue, fontWeight: FontWeight.bold))),
                   
                   const SizedBox(height: 24),
                   BizPrimaryButton(
                     onPressed: _generate,
                     label: _isGenerating ? 'Generujem...' : 'Vytvoriť návrh',
                     isLoading: _isGenerating,
                   ),
                 ],
               ),
             ),
             
             if (_generatedText != null) ...[
               const SizedBox(height: 24),
               BizCard(
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     Row(
                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
                       children: [
                         const Text('Návrh textu (E-mail / SMS)', style: TextStyle(fontWeight: FontWeight.bold)),
                         IconButton(
                           icon: const Icon(Icons.copy),
                           onPressed: () {
                             Clipboard.setData(ClipboardData(text: _generatedText!));
                             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Skopírované!')));
                           },
                         )
                       ],
                     ),
                     const Divider(),
                     const SizedBox(height: 8),
                     Text(_generatedText!, style: const TextStyle(height: 1.5)),
                   ],
                 ),
               ),
             ]
           ],
         ),
      ),
    );
  }

  String _getToneLabel(double value) {
    if (value < 0.5) return "Mäkký (Kamarátsky)";
    if (value > 1.5) return "Prísny (Predžalobný)";
    return "Profesionálny (Štandard)";
  }
}
