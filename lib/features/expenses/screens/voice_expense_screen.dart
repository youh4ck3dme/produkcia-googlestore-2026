import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/ui/biz_theme.dart';
import '../../../core/services/voice_capture_service.dart';
import '../../../core/services/expense_parser_service.dart';
import '../../../shared/utils/biz_snackbar.dart';
import '../../../core/services/analytics_service.dart';
import '../models/expense_model.dart';
import '../models/expense_category.dart';
import '../providers/expenses_provider.dart';
import '../../../features/auth/providers/auth_repository.dart';

class VoiceExpenseScreen extends ConsumerStatefulWidget {
  const VoiceExpenseScreen({super.key});

  @override
  ConsumerState<VoiceExpenseScreen> createState() => _VoiceExpenseScreenState();
}

class _VoiceExpenseScreenState extends ConsumerState<VoiceExpenseScreen>
    with TickerProviderStateMixin {
  // State management
  VoiceState _voiceState = VoiceState.idle;
  String _transcription = '';
  ParsedExpense? _parsedExpense;

  // Animation controllers
  late AnimationController _micAnimationController;
  late Animation<double> _micScaleAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _micAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _micScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _micAnimationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _micAnimationController.dispose();
    super.dispose();
  }

  Future<void> _startVoiceInput() async {
    setState(() => _voiceState = VoiceState.listening);
    _micAnimationController.repeat(reverse: true);

    ref.read(analyticsServiceProvider).logVoiceExpenseStarted();

    try {
      final voiceService = ref.read(voiceCaptureServiceProvider);
      final transcription = await voiceService.listenForExpense(
        onPartialResult: (partial) {
          if (mounted) {
            setState(() => _transcription = partial);
          }
        },
      );

      if (transcription != null && transcription.isNotEmpty) {
        setState(() {
          _transcription = transcription;
          _voiceState = VoiceState.processing;
        });

        await _processTranscription(transcription);
      } else {
        if (!mounted) return;
        _resetToIdle();
        BizSnackbar.showInfo(context, 'Nezachytil som žiadny hlasový vstup');
      }
    } catch (e) {
      if (!mounted) return;
      _resetToIdle();
      BizSnackbar.showError(context, 'Chyba pri rozpoznávaní hlasu: $e');
    } finally {
      _micAnimationController.stop();
      _micAnimationController.reset();
    }
  }

  Future<void> _processTranscription(String transcription) async {
    try {
      final parserService = ref.read(expenseParserServiceProvider);
      final parsed = await parserService.parseExpenseText(transcription);

      if (!mounted) return;

      if (parsed != null && parserService.isValidExpense(parsed)) {
        setState(() {
          _parsedExpense = parsed;
          _voiceState = VoiceState.confirmation;
        });
      } else {
        setState(() => _voiceState = VoiceState.error);
        BizSnackbar.showInfo(context, 'Nepodarilo sa rozpoznať výdavok. Skúste to znova.');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _voiceState = VoiceState.error);
      BizSnackbar.showError(context, 'Chyba pri spracovaní: $e');
    }
  }

  Future<void> _saveExpense() async {
    if (_parsedExpense == null) return;

    final user = ref.read(authStateProvider).value;
    if (user == null) return;

    setState(() => _voiceState = VoiceState.saving);

    try {
      // Map parsed expense to ExpenseModel
      final expense = ExpenseModel(
        id: const Uuid().v4(),
        userId: user.id,
        vendorName: _parsedExpense!.merchant ?? 'Hlasový výdavok',
        description: _parsedExpense!.description,
        amount: _parsedExpense!.amount,
        date: _parsedExpense!.date,
        category: expenseCategoryFromString(_parsedExpense!.category.toLowerCase()),
        categorizationConfidence: (_parsedExpense!.confidence * 100).toInt(),
        receiptUrls: [],
        isOcrVerified: false,
      );

      await ref.read(expensesControllerProvider.notifier).addExpense(expense);

      ref.read(analyticsServiceProvider).logVoiceExpenseCompleted(success: true);

      if (!mounted) return;
      BizSnackbar.showSuccess(context, 'Výdavok uložený cez hlas! 🎉');

      // Reset state
      setState(() {
        _voiceState = VoiceState.idle;
        _transcription = '';
        _parsedExpense = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _voiceState = VoiceState.error);
      BizSnackbar.showError(context, 'Chyba pri ukladaní výdavku: $e');
    }
  }

  void _resetToIdle() {
    if (!mounted) return;
    setState(() {
      _voiceState = VoiceState.idle;
      _transcription = '';
      _parsedExpense = null;
    });
  }

  void _retry() {
    _resetToIdle();
    _startVoiceInput();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('🎙️ Hlasový výdavok'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        actions: [
          if (_voiceState != VoiceState.idle)
            TextButton(
              onPressed: _resetToIdle,
              child: Text(
                'Reset',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Expanded(
                child: _buildMainContent(),
              ),
              if (_voiceState == VoiceState.idle)
                _buildActionButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    switch (_voiceState) {
      case VoiceState.idle:
        return _buildIdleState();
      case VoiceState.listening:
        return _buildListeningState();
      case VoiceState.processing:
        return _buildProcessingState();
      case VoiceState.confirmation:
        return _buildConfirmationState();
      case VoiceState.saving:
        return _buildSavingState();
      case VoiceState.error:
        return _buildErrorState();
    }
  }

  Widget _buildIdleState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: BizTheme.slovakBlue.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.mic_none,
              size: 60,
              color: BizTheme.slovakBlue,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Pridajte výdavok hlasom',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Povedzte niečo ako:\n"Kúpil som kávu za 3,50€"',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.grey[600],
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildListeningState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _micScaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _micScaleAnimation.value,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.mic,
                    size: 60,
                    color: Colors.red,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 32),
          Text(
            'Počúvam...',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _transcription.isNotEmpty ? _transcription : 'Povedzte svoj výdavok...',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProcessingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(BizTheme.slovakBlue),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Spracovávam...',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _transcription,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmationState() {
    if (_parsedExpense == null) return const SizedBox();

    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle,
              size: 64,
              color: Colors.green,
            ),
            const SizedBox(height: 24),
            Text(
              'Rozpoznané údaje',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),
            _buildExpenseDetails(),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _retry,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: Colors.grey[300]!),
                    ),
                    child: const Text('Skúsiť znova'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saveExpense,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: BizTheme.slovakBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Uložiť'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpenseDetails() {
    final expense = _parsedExpense!;
    final category = expenseCategoryFromString(expense.category.toLowerCase());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDetailRow('Popis', expense.description),
        _buildDetailRow('Suma', '${expense.amount.toStringAsFixed(2)} €'),
        _buildDetailRow('Kategória', category?.displayName ?? expense.category),
        if (expense.merchant != null)
          _buildDetailRow('Obchodník', expense.merchant!),
        _buildDetailRow('Dátum', _formatDate(expense.date)),
        _buildDetailRow(
          'Dôvera',
          '${(expense.confidence * 100).toStringAsFixed(0)}%',
          color: expense.confidence > 0.8 ? Colors.green : Colors.orange,
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: color ?? Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSavingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(BizTheme.slovakBlue),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Ukladám výdavok...',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.orange,
          ),
          const SizedBox(height: 24),
          Text(
            'Nepodarilo sa rozpoznať',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Skúste to znova s jasnejším hlasom',
            style: TextStyle(
              color: Colors.grey[600],
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _retry,
            style: ElevatedButton.styleFrom(
              backgroundColor: BizTheme.slovakBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            child: const Text('Skúsiť znova'),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 24),
      child: ElevatedButton(
        onPressed: _startVoiceInput,
        style: ElevatedButton.styleFrom(
          backgroundColor: BizTheme.slovakBlue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.mic, size: 24),
            SizedBox(width: 12),
            Text(
              'Začať nahrávať',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }
}

enum VoiceState {
  idle,
  listening,
  processing,
  confirmation,
  saving,
  error,
}
