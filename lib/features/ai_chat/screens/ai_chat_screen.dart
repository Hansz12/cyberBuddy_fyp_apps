import 'package:flutter/material.dart';

import '../../../data/services/connectivity_service.dart';
import '../services/gemini_service.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GeminiService _geminiService = GeminiService();
  final List<_ChatMessage> _messages = [
    _ChatMessage.ai(
      'Hi! I am CyberBuddy AI Coach.\n\nAsk me about cybersecurity, scam checking, programming, Flutter errors, assignments, or study guidance.',
    ),
  ];

  Future<void> _messageQueue = Future.value();
  int _conversationVersion = 0;
  int _nextMessageId = 0;
  bool _hasText = false;

  bool get _hasPendingReplies =>
      _messages.any((message) => message.isAwaitingReply);

  void _useSuggestedPrompt(String text) {
    _controller
      ..text = text
      ..selection = TextSelection.fromPosition(TextPosition(offset: text.length));
    setState(() => _hasText = true);
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final replyId = _nextMessageId++;
    final version = _conversationVersion;
    setState(() {
      _messages
        ..add(_ChatMessage.user(text))
        ..add(_ChatMessage.waiting(replyId));
      _hasText = false;
    });
    _controller.clear();
    _scrollToBottom();

    // Requests are queued in the order the user writes them. Unlike the old
    // screen, typing and sending remain available while a reply is generated.
    _messageQueue = _messageQueue.then(
      (_) => _requestReply(text, replyId, version),
      // A failed request must not block every message sent after it.
      onError: (_) => _requestReply(text, replyId, version),
    );
  }

  Future<void> _requestReply(String text, int replyId, int version) async {
    if (version != _conversationVersion) return;

    String reply;
    try {
      final online = await ConnectivityService.hasInternetConnection();
      if (version != _conversationVersion || !mounted) return;

      reply = online
          ? await _geminiService.sendMessage(text)
          : 'CyberBuddy AI needs an internet connection. Reconnect and send your message again.';
    } catch (_) {
      reply = 'CyberBuddy AI could not process this message. Please try again.';
    }

    if (version != _conversationVersion || !mounted) return;

    final messageIndex = _messages.indexWhere((message) => message.id == replyId);
    if (messageIndex == -1) return;

    setState(() {
      _messages[messageIndex] = _ChatMessage.ai(reply, id: replyId);
    });
    _scrollToBottom();
  }

  void _clearChat() {
    _conversationVersion++;
    _messageQueue = Future.value();
    _geminiService.startNewConversation();
    setState(() {
      _messages
        ..clear()
        ..add(_ChatMessage.ai('New chat started. How can I help you today?'));
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    });
  }

  Widget _buildMessageBubble(_ChatMessage message) {
    final isUser = message.role == _MessageRole.user;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Align(
          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: constraints.maxWidth * 0.84),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isUser ? const Color(0xFF2563EB) : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isUser ? 18 : 5),
                  bottomRight: Radius.circular(isUser ? 5 : 18),
                ),
                border: Border.all(
                  color: isUser ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: message.isAwaitingReply
                  ? _buildTypingContent()
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!isUser)
                          const Padding(
                            padding: EdgeInsets.only(bottom: 8),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.smart_toy_outlined,
                                    color: Color(0xFF2563EB), size: 16),
                                SizedBox(width: 6),
                                Text(
                                  'CyberBuddy AI',
                                  style: TextStyle(
                                    color: Color(0xFF2563EB),
                                    fontWeight: FontWeight.w900,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        SelectableText(
                          message.text,
                          style: TextStyle(
                            color: isUser ? Colors.white : const Color(0xFF0F172A),
                            fontSize: 14.5,
                            height: 1.4,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTypingContent() {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
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
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E40AF)],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 32),
              const SizedBox(width: 10),
              Expanded(
                child: const Text(
                  'CyberBuddy AI',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _StatusPill(configured: _geminiService.isConfigured),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Continue asking follow-up questions, send several messages, and press and hold a response to copy it.',
            style: TextStyle(color: Colors.white70, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildPromptChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: [
          _PromptChip(
            icon: Icons.gpp_good_outlined,
            text: 'Check Scam',
            onTap: () => _useSuggestedPrompt('Check whether this message is a scam:\n\n'),
          ),
          _PromptChip(
            icon: Icons.mark_email_read_outlined,
            text: 'Check Email',
            onTap: () => _useSuggestedPrompt('Analyse this email for phishing risks:\n\n'),
          ),
          _PromptChip(
            icon: Icons.code_rounded,
            text: 'Programming',
            onTap: () => _useSuggestedPrompt('Help me solve this programming problem:\n\n'),
          ),
          _PromptChip(
            icon: Icons.phone_android_rounded,
            text: 'Flutter',
            onTap: () => _useSuggestedPrompt('Help me with Flutter development:\n\n'),
          ),
          _PromptChip(
            icon: Icons.school_outlined,
            text: 'Study Coach',
            onTap: () => _useSuggestedPrompt(
              'Act as my study coach. Suggest what I should revise today based on cybersecurity learning.',
            ),
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
        actions: [
          IconButton(
            tooltip: 'New chat',
            icon: const Icon(Icons.add_comment_outlined),
            onPressed: _clearChat,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildHeaderCard(),
          _buildPromptChips(),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.only(bottom: 14),
              itemCount: _messages.length,
              itemBuilder: (context, index) => _buildMessageBubble(_messages[index]),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 5,
                      textCapitalization: TextCapitalization.sentences,
                      textInputAction: TextInputAction.send,
                      onChanged: (value) {
                        final hasText = value.trim().isNotEmpty;
                        if (hasText != _hasText) setState(() => _hasText = hasText);
                      },
                      onSubmitted: (_) => _sendMessage(),
                      decoration: InputDecoration(
                        hintText: _hasPendingReplies
                            ? 'Send another message...'
                            : 'Ask CyberBuddy AI...',
                        filled: true,
                        fillColor: const Color(0xFFF1F5F9),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Semantics(
                    label: 'Send message',
                    button: true,
                    child: CircleAvatar(
                      backgroundColor: _hasText
                          ? const Color(0xFF2563EB)
                          : const Color(0xFFCBD5E1),
                      child: IconButton(
                        onPressed: _hasText ? _sendMessage : null,
                        icon: const Icon(Icons.send_rounded, color: Colors.white),
                      ),
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

class _StatusPill extends StatelessWidget {
  final bool configured;

  const _StatusPill({required this.configured});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: (configured ? const Color(0xFF22C55E) : const Color(0xFFF59E0B))
            .withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.circle,
            color: configured ? const Color(0xFF4ADE80) : const Color(0xFFFBBF24),
            size: 8,
          ),
          const SizedBox(width: 5),
          Text(
            configured ? 'Configured' : 'Setup needed',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _PromptChip extends StatelessWidget {
  final IconData icon;
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
        avatar: Icon(icon, size: 18, color: const Color(0xFF2563EB)),
        label: Text(text),
        onPressed: onTap,
        backgroundColor: Colors.white,
        side: const BorderSide(color: Color(0xFFE2E8F0)),
        labelStyle: const TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.w800),
      ),
    );
  }
}

enum _MessageRole { user, ai }

class _ChatMessage {
  final int? id;
  final _MessageRole role;
  final String text;
  final bool isAwaitingReply;

  const _ChatMessage._({
    this.id,
    required this.role,
    required this.text,
    this.isAwaitingReply = false,
  });

  factory _ChatMessage.user(String text) =>
      _ChatMessage._(role: _MessageRole.user, text: text);

  factory _ChatMessage.ai(String text, {int? id}) =>
      _ChatMessage._(id: id, role: _MessageRole.ai, text: text);

  factory _ChatMessage.waiting(int id) => _ChatMessage._(
        id: id,
        role: _MessageRole.ai,
        text: '',
        isAwaitingReply: true,
      );
}
