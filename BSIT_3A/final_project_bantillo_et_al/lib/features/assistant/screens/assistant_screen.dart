// AI style assistant chat (Gemini through the ai-assistant edge function).
// The banner at the top marks replies as AI-generated and always shows a
// "Contact the shop" button (UI audit #9).
//
// UI audit changes: brand colors (maroon / gold tint) instead of orange, so
// white text on the user's bubbles passes WCAG AA (#19), and every reply
// from the AI carries the shared "AI-generated" label (#20).
//
// OWNER: Member 1.

import 'package:flutter/material.dart';

import 'package:orange150_rental/core/theme/app_colors.dart';
import 'package:orange150_rental/core/widgets/ai_label.dart';
import 'package:orange150_rental/core/widgets/contact_shop.dart';
import 'package:orange150_rental/features/assistant/services/assistant_service.dart';

class AssistantScreen extends StatefulWidget {
  const AssistantScreen({super.key});

  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _ChatMessage {
  final String text;
  final bool isUser;
  final bool isError;

  /// True only for replies that came from the AI (not the fixed welcome
  /// text or error notices). These show the "AI-generated" label.
  final bool isAi;

  const _ChatMessage({
    required this.text,
    required this.isUser,
    this.isError = false,
    this.isAi = false,
  });
}

class _AssistantScreenState extends State<AssistantScreen> {
  final AssistantService _assistantService = AssistantService();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<_ChatMessage> _messages = [
    const _ChatMessage(
      text:
          "Hi! Welcome to Orange 150! 🍊 I'm your style assistant. "
          "I can help you find outfits, explore styles, and answer "
          "questions about renting. What are you dressing up for?",
      isUser: false,
    ),
  ];

  bool _isLoading = false;
  String? _failedMessage;

  final List<String> _suggestions = [
    'What should I wear to a debut?',
    'Help me find a gown',
    'What sizes are available?',
    'How does renting work?',
  ];

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage([String? suggestedMessage]) async {
    final message = (suggestedMessage ?? _controller.text).trim();

    if (message.isEmpty || _isLoading) return;

    setState(() {
      _messages.add(_ChatMessage(text: message, isUser: true));
      _controller.clear();
      _isLoading = true;
      _failedMessage = null;
    });

    _scrollToBottom();

    try {
      final reply = await _assistantService.sendMessage(message);

      if (!mounted) return;

      setState(() {
        _messages.add(_ChatMessage(text: reply, isUser: false, isAi: true));
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _failedMessage = message;
        _messages.add(
          const _ChatMessage(
            text:
                "I couldn't connect right now. Please try sending "
                "your message again.",
            isUser: false,
            isError: true,
          ),
        );
      });
    }

    _scrollToBottom();
  }

  void _retryMessage() {
    final message = _failedMessage;
    if (message == null || _isLoading) return;

    setState(() {
      _messages.removeWhere((m) => m.isError);
      _failedMessage = null;
    });

    _sendMessage(message);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.goldTint,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.auto_awesome, color: AppColors.maroon),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Assistant'), // matches the tab label (UI audit #38)
                Text(
                  'Orange 150',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: AppColors.goldTint,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 18, color: AppColors.maroon),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'AI-generated advice. Please verify rental details '
                    'with Orange 150.',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
                // UI audit #9: a human fallback, always visible at the top
                // of the chat (opens a dialog with Call and Copy).
                const ContactShopButton(),
              ],
            ),
          ),

          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (_isLoading && index == _messages.length) {
                  return _buildTypingIndicator();
                }

                final message = _messages[index];

                return _buildMessageBubble(message);
              },
            ),
          ),

          if (_failedMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: TextButton.icon(
                onPressed: _retryMessage,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ),

          if (_messages.length == 1 && !_isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _suggestions.map((suggestion) {
                  return ActionChip(
                    label: Text(suggestion),
                    backgroundColor: AppColors.goldTint,
                    onPressed: () => _sendMessage(suggestion),
                  );
                }).toList(),
              ),
            ),

          _buildInput(theme),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(_ChatMessage message) {
    final isUser = message.isUser;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 320),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isUser ? AppColors.maroon : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(18).copyWith(
            bottomRight: isUser ? const Radius.circular(4) : null,
            bottomLeft: !isUser ? const Radius.circular(4) : null,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // AI replies: the shared "AI-generated" badge (UI audit #20).
            if (message.isAi)
              const Padding(
                padding: EdgeInsets.only(bottom: 6),
                child: AiLabel(),
              )
            else if (!isUser)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome, size: 14, color: AppColors.maroon),
                    const SizedBox(width: 5),
                    Text(
                      message.isError ? 'Notice' : 'Orange 150',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.maroon,
                      ),
                    ),
                  ],
                ),
              ),
            Text(
              message.text,
              style: TextStyle(
                color: isUser ? Colors.white : Colors.black87,
                height: 1.4,
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
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome, size: 16, color: AppColors.maroon),
            const SizedBox(width: 8),
            const Text('Thinking...'),
          ],
        ),
      ),
    );
  }

  Widget _buildInput(ThemeData theme) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(top: BorderSide(color: Colors.grey.shade200)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                minLines: 1,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Ask about outfits or rentals...',
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _isLoading ? null : () => _sendMessage(),
              tooltip: 'Send message', // UI audit #39
              icon: const Icon(Icons.send_rounded),
              style: IconButton.styleFrom(
                backgroundColor: AppColors.maroon,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade300,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
