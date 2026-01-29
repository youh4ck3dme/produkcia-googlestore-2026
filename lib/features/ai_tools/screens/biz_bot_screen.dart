import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/biz_bot_service.dart';
import '../../../core/ui/biz_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';

class BizBotMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  BizBotMessage({required this.text, required this.isUser, required this.timestamp});
}

class BizBotScreen extends ConsumerStatefulWidget {
  const BizBotScreen({super.key});

  @override
  ConsumerState<BizBotScreen> createState() => _BizBotScreenState();
}

class _BizBotScreenState extends ConsumerState<BizBotScreen> {
  final List<BizBotMessage> _messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Welcome message
    _messages.add(BizBotMessage(
      text: 'Ahoj! Som tvoj BizAgent asistent. Ako ti môžem dnes pomôcť s tvojím podnikaním?',
      isUser: false,
      timestamp: DateTime.now(),
    ));
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

    setState(() {
      _messages.add(BizBotMessage(text: text, isUser: true, timestamp: DateTime.now()));
      _controller.clear();
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      final response = await ref.read(bizBotServiceProvider).ask(text);
      if (mounted) {
        setState(() {
          _messages.add(BizBotMessage(text: response, isUser: false, timestamp: DateTime.now()));
          _isLoading = false;
        });
        _scrollToBottom();
      }
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
      
      if (mounted) {
        setState(() {
          _messages.add(BizBotMessage(
            text: errorMessage,
            isUser: false,
            timestamp: DateTime.now(),
          ));
          _isLoading = false;
        });
        _scrollToBottom();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
            onPressed: () => setState(() => _messages.clear()),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return _buildMessageBubble(msg);
              },
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
