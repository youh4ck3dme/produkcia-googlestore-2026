import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/services/ocr_service.dart';
import '../../../core/ui/biz_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AiToolsScreen extends ConsumerStatefulWidget {
  const AiToolsScreen({super.key});

  @override
  ConsumerState<AiToolsScreen> createState() => _AiToolsScreenState();
}

class _AiToolsScreenState extends ConsumerState<AiToolsScreen> {
  ParsedReceipt? _receipt;
  bool _isScanning = false;

  final _amountController = TextEditingController();
  final _dateController = TextEditingController();
  final _vendorController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    _dateController.dispose();
    _vendorController.dispose();
    super.dispose();
  }

  Future<void> _scan(ImageSource source) async {
    setState(() {
      _isScanning = true;
      _receipt = null;
      _amountController.clear();
      _dateController.clear();
      _vendorController.clear();
    });

    final ocrService = ref.read(ocrServiceProvider);
    final receipt = await ocrService.scanReceipt(source);

    if (mounted) {
      setState(() {
        _isScanning = false;
        _receipt = receipt;
        if (receipt != null) {
          _amountController.text = receipt.totalAmount ?? '';
          _dateController.text = receipt.date ?? '';
          _vendorController.text = receipt.vendorId ?? '';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            _buildToolHeader(context),
            const SizedBox(height: BizTheme.spacingMd),
            // AI Tools Feature Illustration Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.purple.withValues(alpha: 0.1),
                    Colors.purple.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(BizTheme.radiusLg),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'AI Nástroje',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Využite silu AI pre vaše podnikanie',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 100, maxWidth: 120),
                    child: Image.asset(
                      'assets/images/ai_tools_feature.png',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn().slideX(begin: -0.05),
            const SizedBox(height: BizTheme.spacingMd),

            _buildToolCard(
              context,
              title: 'BizBot AI Asistent',
              subtitle: 'Váš inteligentný parťák pre biznis, dane a poradenstvo.',
              icon: Icons.smart_toy,
              color: BizTheme.slovakBlue,
              onTap: () => context.go('/ai-tools/biz-bot'),
              isProminent: true,
              delay: 100.ms,
            ),

            const SizedBox(height: 24),
            if (kIsWeb)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.amber),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'OCR skenovanie je dostupné v Android aplikácii.',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed:
                          _isScanning ? null : () => _scan(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Kamera'),
                      style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.all(16)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed:
                          _isScanning ? null : () => _scan(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Galéria'),
                      style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.all(16)),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 24),
            if (_isScanning)
              const Center(child: Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: CircularProgressIndicator(),
              ))
            else if (_receipt != null)
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(BizTheme.spacingMd),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Rozpoznané údaje:',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                      const Divider(height: 24),
                      TextFormField(
                        controller: _amountController,
                        decoration: const InputDecoration(
                          labelText: 'Suma',
                          suffixText: 'EUR',
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _dateController,
                        decoration: const InputDecoration(
                          labelText: 'Dátum',
                          hintText: 'DD.MM.YYYY',
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _vendorController,
                        decoration: const InputDecoration(
                          labelText: 'IČO / ID',
                        ),
                      ),
                      const SizedBox(height: 16),
                      ExpansionTile(
                        title: const Text('Zobraziť celý text'),
                        tilePadding: EdgeInsets.zero,
                        children: [SelectableText(_receipt!.originalText)],
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            context.push('/create-expense',
                                extra: _receipt!.originalText);
                          },
                          child: const Text('Vytvoriť výdavok'),
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn().scale(begin: const Offset(0.9, 0.9)),
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildToolHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            BizTheme.slovakBlue.withValues(alpha: 0.1),
            BizTheme.slovakBlue.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(BizTheme.radiusLg),
      ),
      child: Column(
        children: [
          // Modern illustration
          Container(
            constraints: const BoxConstraints(maxHeight: 150, maxWidth: 250),
            child: Image.asset(
              'assets/images/ocr_scanning_feature.png',
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.document_scanner, size: 64, color: BizTheme.slovakBlue);
              },
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Skener Bločkov',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Odfote bloček a AI automaticky vyčíta údaje.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.1);
  }

  Widget _buildToolCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    IconData? icon,
    Widget? leading,
    required Color color,
    required VoidCallback onTap,
    bool isProminent = false,
    Duration delay = Duration.zero,
  }) {
    assert(icon != null || leading != null, 'Provide either icon or leading');
    final theme = Theme.of(context);
    // final isDark = theme.brightness == Brightness.dark;

    return Card(
      elevation: isProminent ? 4 : 0,
      shadowColor: isProminent ? color.withValues(alpha: 0.2) : null,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(BizTheme.spacingMd),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(BizTheme.radiusMd),
                ),
                child: IconTheme(
                  data: IconThemeData(size: 32, color: color),
                  child: leading ?? Icon(icon),
                ),
              ),
              const SizedBox(width: BizTheme.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: BizTheme.gray300),
            ],
          ),
        ),
      ),
    ).animate(delay: delay).fadeIn().slideX(begin: 0.05);
  }
}
