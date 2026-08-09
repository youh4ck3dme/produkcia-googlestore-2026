import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/i18n/app_strings.dart';
import '../../../core/i18n/l10n.dart';
import '../../../core/services/ai_consent_service.dart';
import '../../../core/supabase/supabase_config.dart';
import '../../legal/widgets/ai_consent_dialog.dart';
import '../services/biz_bot_service.dart';
import '../../../core/ui/biz_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../auth/providers/auth_repository.dart';
import '../models/bizbot_message.dart';
import '../providers/bizbot_history_provider.dart';
import '../../billing/billing_service.dart';
import '../../billing/subscription_guard.dart';
import '../../billing/paywall_flow.dart';
import '../../../shared/widgets/ai_generated_label.dart';

class BizBotScreen extends ConsumerStatefulWidget {
  const BizBotScreen({super.key});

  @override
  ConsumerState<BizBotScreen> createState() => _BizBotScreenState();
}

class _BizBotScreenState extends ConsumerState<BizBotScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  int _lastMessageCount = 0;
  ProviderSubscription<AsyncValue<List<BizBotMessage>>>? _messagesSub;

  @override
  void initState() {
    super.initState();

    // Scroll to bottom when Firestore stream updates.
    _messagesSub = ref.listenManual<AsyncValue<List<BizBotMessage>>>(bizBotMessagesProvider, (_, next) {
      final msgs = next.value;
      if (msgs == null) return;
      if (msgs.length == _lastMessageCount) return;
      _lastMessageCount = msgs.length;
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    _messagesSub?.close();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isLoading) return;

    final user = ref.read(authStateProvider).value;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.t(AppStr.bizBotAuthRequired))),
      );
      return;
    }

    if (!await PaywallFlow.ensureAccess(context, ref, BizFeature.aiAnalysis)) {
      return;
    }

    if (!mounted) return;
    final consent = ref.read(aiConsentServiceProvider);
    if (!await showAiConsentDialog(context, consent)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.t(AppStr.gdprAiConsentRequired))),
        );
      }
      return;
    }

    setState(() {
      _controller.clear();
      _isLoading = true;
    });

    final repo = ref.read(bizBotHistoryRepositoryProvider);
    await repo.addMessage(uid: user.id, text: text, isUser: true);
    await _askAndStore(user.id, text);
  }

  /// Zavolá AI a uloží odpoveď. Pri chybe ponúkne „Skúsiť znova" bez duplikovania otázky.
  Future<void> _askAndStore(String uid, String question) async {
    final repo = ref.read(bizBotHistoryRepositoryProvider);
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final response = await ref.read(bizBotServiceProvider).ask(question);
      await repo.addMessage(uid: uid, text: response, isUser: false);
      await ref.read(billingProvider.notifier).recordAiRequest();
    } catch (e) {
      if (!mounted) return;
      final lower = e.toString().toLowerCase();
      String errorMessage = context.t(AppStr.bizBotErrorGeneric);
      if (e.toString().contains('API kľúč') || lower.contains('permission')) {
        errorMessage = context.t(AppStr.bizBotErrorApiKey);
      } else if (lower.contains('quota') || lower.contains('resource-exhausted')) {
        errorMessage = context.t(AppStr.bizBotErrorQuota);
      } else if (lower.contains('network') || lower.contains('clientexception') || lower.contains('unavailable')) {
        errorMessage = context.t(AppStr.bizBotErrorNetwork);
      }

      await repo.addMessage(uid: uid, text: errorMessage, isUser: false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.t(AppStr.bizBotUnavailable)),
            action: SnackBarAction(
              label: context.t(AppStr.retry),
              onPressed: () => _askAndStore(uid, question),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(bizBotMessagesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const CircleAvatar(
              backgroundColor: BizTheme.slovakBlue,
              radius: 16,
              child: Icon(Icons.verified_user, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.t(AppStr.bizBotTitle), style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
                Text(context.t(AppStr.bizBotSubtitle), style: const TextStyle(fontSize: 12, color: Colors.green)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            onPressed: () async {
              final user = ref.read(authStateProvider).value;
              if (user == null) return;
              await ref.read(bizBotHistoryRepositoryProvider).clearThread(user.id);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // AI Disclaimer banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: Colors.amber.withValues(alpha: 0.1),
            child: Text(
              context.t(AppStr.bizBotDisclaimer),
              style: const TextStyle(fontSize: 11, color: Colors.black54),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: messagesAsync.when(
              data: (messages) => _buildMessagesList(messages),
              loading: () => _buildMessagesList(const <BizBotMessage>[]),
              error: (e, _) => _buildMessagesList(
                const <BizBotMessage>[],
                errorText: context.t(AppStr.bizBotHistoryError),
              ),
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: LinearProgressIndicator(backgroundColor: Colors.transparent),
            ),
          _buildInput(),
        ],
      ),
    );
  }

  Widget _buildMessagesList(List<BizBotMessage> messages, {String? errorText}) {
    final displayMessages = messages.isEmpty
        ? <BizBotMessage>[
            BizBotMessage(
              id: 'welcome',
              text: context.t(AppStr.bizBotWelcome),
              isUser: false,
              createdAt: DateTime.fromMillisecondsSinceEpoch(0),
            ),
          ]
        : messages;

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: displayMessages.length + (errorText == null ? 0 : 1),
      itemBuilder: (context, index) {
        if (errorText != null && index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              errorText,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.redAccent),
            ),
          );
        }
        final msg = displayMessages[errorText == null ? index : index - 1];
        return _buildMessageBubble(msg);
      },
    );
  }

  Widget _buildMessageBubble(BizBotMessage msg) {
    final bubble = Align(
      alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
        decoration: BoxDecoration(
          gradient: msg.isUser
              ? LinearGradient(
                  colors: [BizTheme.slovakBlue, BizTheme.slovakBlue.withValues(alpha: 0.9)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : const LinearGradient(
                  colors: [Colors.white, Color(0xFFF9FAFB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          color: msg.isUser ? null : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(msg.isUser ? 20 : 4),
            bottomRight: Radius.circular(msg.isUser ? 4 : 20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          border: msg.isUser ? null : Border.all(color: Colors.grey.withValues(alpha: 0.1)),
        ),
        child: SelectableText( // Allow copying text
          msg.text,
          style: TextStyle(
            color: msg.isUser ? Colors.white : Colors.black87,
            height: 1.5,
            fontSize: 15,
            fontFamilyFallback: BizTheme.fontFallbacks,
          ),
        ),
      ).animate().fade().slideY(begin: 0.1, duration: 300.ms, curve: Curves.easeOut),
    );

    if (!msg.isUser && msg.id != 'welcome') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 4),
            child: const AiGeneratedLabel(),
          ),
          bubble,
          Padding(
            padding: const EdgeInsets.only(left: 4, top: 2),
            child: GestureDetector(
              onTap: () => _reportMessage(msg),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.flag_outlined, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(context.t(AppStr.bizBotReport),
                      style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return bubble;
  }

  Future<void> _reportMessage(BizBotMessage msg) async {
    final user = ref.read(authStateProvider).value;
    if (user == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(dialogContext.t(AppStr.bizBotReportTitle)),
        content: Text(dialogContext.t(AppStr.bizBotReportBody)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(dialogContext.t(AppStr.cancel)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(dialogContext.t(AppStr.bizBotReport)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      if (SupabaseConfig.isReady) {
        await SupabaseConfig.client.from('ai_reports').insert({
          'user_id': user.id,
          'message_id': msg.id,
          'excerpt': msg.text.length > 100 ? msg.text.substring(0, 100) : msg.text,
        });
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.t(AppStr.bizBotReportThanks))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.t(AppStr.bizBotReportFailed))),
        );
      }
    }
  }

  Widget _buildInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          )
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.transparent),
                ),
                child: TextField(
                  key: const Key('bizbot_input'),
                  controller: _controller,
                  onSubmitted: (_) => _sendMessage(),
                  style: const TextStyle(fontSize: 15),
                  decoration: InputDecoration(
                    hintText: context.t(AppStr.bizBotInputHint),
                    hintStyle: TextStyle(color: Colors.grey[500]),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    isDense: true,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            FloatingActionButton.small(
              key: const Key('bizbot_send_btn'),
              onPressed: _sendMessage,
              backgroundColor: BizTheme.slovakBlue,
              elevation: 2,
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ).animate(target: _isLoading ? 0 : 1).scale(),
          ],
        ),
      ),
    );
  }
}
