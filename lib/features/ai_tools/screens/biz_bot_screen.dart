import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/biz_bot_service.dart';
import '../../../core/ui/biz_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../auth/providers/auth_repository.dart';
import '../models/bizbot_message.dart';
import '../providers/bizbot_history_provider.dart';

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
      final msgs = next.valueOrNull;
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

    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Na chat je potrebné byť prihlásený.')),
      );
      return;
    }

    setState(() {
      _controller.clear();
      _isLoading = true;
    });

    final repo = ref.read(bizBotHistoryRepositoryProvider);
    try {
      await repo.addMessage(uid: user.id, text: text, isUser: true);

      final response = await ref.read(bizBotServiceProvider).ask(text);
      await repo.addMessage(uid: user.id, text: response, isUser: false);
    } catch (e) {
      String errorMessage = 'Prepáč, vyskytla sa chyba pri spájaní s AI.';
      
      if (e.toString().contains('API kľúč')) {
        errorMessage = 'Chyba API kľúča (403/Invalid). Kontaktujte podporu.';
      } else if (e.toString().contains('quota')) {
        errorMessage = 'Dosiahli ste denný limit bezplatných dopytov (429).';
      } else if (e.toString().toLowerCase().contains('network') || e.toString().contains('ClientException')) {
        errorMessage = 'Sieťová chyba. Skontrolujte pripojenie na internet.';
      } else {
        errorMessage = 'Chyba: $e';
      }
      
      // Store the error as an assistant message so the user sees it in history.
      await repo.addMessage(uid: user.id, text: errorMessage, isUser: false);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
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
                Text('BizBot', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
                const Text('AI Asistent', style: TextStyle(fontSize: 12, color: Colors.green)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            onPressed: () async {
              final user = ref.read(authStateProvider).valueOrNull;
              if (user == null) return;
              await ref.read(bizBotHistoryRepositoryProvider).clearThread(user.id);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              data: (messages) => _buildMessagesList(messages),
              loading: () => _buildMessagesList(const <BizBotMessage>[]),
              error: (e, _) => _buildMessagesList(
                const <BizBotMessage>[],
                errorText: 'Nepodarilo sa načítať históriu chatu.',
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
              text: 'Ahoj! Som tvoj BizAgent asistent. Ako ti môžem dnes pomôcť s tvojím podnikaním?',
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
    return Align(
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
          ),
        ),
      ).animate().fade().slideY(begin: 0.1, duration: 300.ms, curve: Curves.easeOut),
    );
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
                    hintText: 'Opýtaj sa na účtovníctvo...',
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
