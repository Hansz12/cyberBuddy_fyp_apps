import 'package:flutter/material.dart';

import '../services/gemini_service.dart';
import '../../../data/services/connectivity_service.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GeminiService _geminiService = GeminiService();

  bool _isLoading = false;

  final List<Map<String, String>> _messages = [
    {
      'role': 'ai',
      'text':
          'Hi 👋 I am CyberBuddy AI Coach. I can help as a cybersecurity tutor, scam checker, phishing checker, and study coach.',
    },
  ];

  void _useSuggestedPrompt(String text) {
    _controller.text = text;
    _controller.selection = TextSelection.fromPosition(
      TextPosition(offset: _controller.text.length),
    );
  }

  Future _sendMessage() async {
    final text = _controller.text.trim();

    if (text.isEmpty || _isLoading) return;

    final online = await ConnectivityService.hasInternetConnection();

    if (!online) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'CyberBuddy AI needs internet connection. Please try again when online.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _messages.add({'role': 'user', 'text': text});
      _isLoading = true;
    });

    _controller.clear();
    _scrollToBottom();

    final reply = await _geminiService.sendMessage(text);

    if (!mounted) return;

    setState(() {
      _messages.add({'role': 'ai', 'text': reply});
      _isLoading = false;
    });

    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 250), () {
      if (!_scrollController.hasClients) return;

      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  Widget _buildMessageBubble(Map<String, String> message) {
    final isUser = message['role'] == 'user';

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        padding: const EdgeInsets.all(14),
        constraints: const BoxConstraints(maxWidth: 310),
        decoration: BoxDecoration(
          color: isUser ? const Color(0xFF2563EB) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isUser ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isUser)
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text(
                  '🤖 CyberBuddy AI',
                  style: TextStyle(
                    color: Color(0xFF2563EB),
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              ),

            Text(
              message['text'] ?? '',
              style: TextStyle(
                color: isUser ? Colors.white : const Color(0xFF0F172A),
                fontSize: 14.5,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 10,
              backgroundColor: Color(0xFF2563EB),
              child: Text('🤖', style: TextStyle(fontSize: 10)),
            ),
            SizedBox(width: 10),

            Text(
              'CyberBuddy is thinking...',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E40AF)],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('🤖', style: TextStyle(fontSize: 34)),
              SizedBox(width: 10),

              Expanded(
                child: Text(
                  'CyberBuddy AI',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),

              Row(
                children: [
                  Icon(Icons.circle, color: Colors.green, size: 10),
                  SizedBox(width: 5),
                  Text(
                    'Online',
                    style: TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),

          SizedBox(height: 12),

          Text(
            'Ask anything about cybersecurity, programming, mobile app development, assignments, or study guidance.',
            style: TextStyle(color: Colors.white70, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildPromptChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
      child: Row(
        children: [
          _PromptChip(
            icon: '🛡️',
            text: 'Check Scam',
            onTap: () => _useSuggestedPrompt(
              'Check whether this message is a scam:\n\n',
            ),
          ),

          _PromptChip(
            icon: '📧',
            text: 'Check Email',
            onTap: () => _useSuggestedPrompt(
              'Analyse this email for phishing risks:\n\n',
            ),
          ),

          _PromptChip(
            icon: '💻',
            text: 'Programming',
            onTap: () => _useSuggestedPrompt(
              'Help me solve this programming problem:\n\n',
            ),
          ),

          _PromptChip(
            icon: '📱',
            text: 'Flutter',
            onTap: () =>
                _useSuggestedPrompt('Help me with Flutter development:\n\n'),
          ),

          _PromptChip(
            icon: '🎓',
            text: 'Study Coach',
            onTap: () =>
                _useSuggestedPrompt('Act as my study coach and guide me.'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text('CyberBuddy AI'),
        centerTitle: true,
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          _buildHeaderCard(),
          _buildPromptChips(),

          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.only(bottom: 14),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (_isLoading && index == _messages.length) {
                  return _buildTypingIndicator();
                }

                return _buildMessageBubble(_messages[index]);
              },
            ),
          ),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                      decoration: InputDecoration(
                        hintText: 'Ask CyberBuddy AI...',
                        filled: true,
                        fillColor: const Color(0xFFF1F5F9),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: const Color(0xFF2563EB),
                    child: IconButton(
                      onPressed: _isLoading ? null : _sendMessage,
                      icon: const Icon(Icons.send, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PromptChip extends StatelessWidget {
  final String icon;
  final String text;
  final VoidCallback onTap;

  const _PromptChip({
    required this.icon,
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        avatar: Text(icon),
        label: Text(text),
        onPressed: onTap,
        backgroundColor: Colors.white,
        side: const BorderSide(color: Color(0xFFE2E8F0)),
        labelStyle: const TextStyle(
          color: Color(0xFF2563EB),
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
