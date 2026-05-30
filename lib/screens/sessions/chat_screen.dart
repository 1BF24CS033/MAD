import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/message_model.dart';
import '../../services/supabase_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_card.dart';

class ChatScreen extends StatefulWidget {
  final String requestId;
  final String otherPersonName;
  final String topic;

  const ChatScreen({
    super.key,
    required this.requestId,
    required this.otherPersonName,
    required this.topic,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<MessageModel> _messages = [];
  bool _loading = true;
  bool _sending = false;
  RealtimeChannel? _channel;

  static const _select =
      '*, sender:profiles!messages_sender_id_fkey(name)';

  SupabaseClient get _db => SupabaseService.client;
  String get _userId => SupabaseService.currentUserId ?? '';

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _subscribeRealtime();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _channel?.unsubscribe();
    super.dispose();
  }

  // ── Load history ────────────────────────────────────────────────────────

  Future<void> _loadMessages() async {
    final rows = await _db
        .from('messages')
        .select(_select)
        .eq('request_id', widget.requestId)
        .order('created_at');

    if (!mounted) return;
    setState(() {
      _messages.addAll(rows
          .cast<Map<String, dynamic>>()
          .map((r) => MessageModel.fromJson(r, currentUserId: _userId)));
      _loading = false;
    });
    _scrollToBottom();
  }

  // ── Realtime subscription ────────────────────────────────────────────────

  void _subscribeRealtime() {
    _channel = _db
        .channel('chat:${widget.requestId}')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'request_id',
            value: widget.requestId,
          ),
          callback: (payload) async {
            // Fetch the full row with sender name
            final row = await _db
                .from('messages')
                .select(_select)
                .eq('id', payload.newRecord['id'] as String)
                .single();

            final msg =
                MessageModel.fromJson(row, currentUserId: _userId);

            // Avoid duplicates (our own sends are already added optimistically)
            if (_messages.any((m) => m.id == msg.id)) return;

            if (mounted) {
              setState(() => _messages.add(msg));
              _scrollToBottom();
            }
          },
        )
        .subscribe();
  }

  // ── Send ─────────────────────────────────────────────────────────────────

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;

    _controller.clear();
    setState(() => _sending = true);

    try {
      final row = await _db
          .from('messages')
          .insert({
            'request_id': widget.requestId,
            'sender_id': _userId,
            'content': text,
          })
          .select(_select)
          .single();

      final msg = MessageModel.fromJson(row, currentUserId: _userId);
      if (mounted) {
        setState(() => _messages.add(msg));
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to send: $e'),
              backgroundColor: Colors.red),
        );
        // Restore text so user doesn't lose it
        _controller.text = text;
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
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

  // ── UI ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.otherPersonName,
                style: const TextStyle(fontSize: 16)),
            Text(widget.topic,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.subtleText)),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.tealAccent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.circle, color: AppColors.primaryGreen, size: 8),
                SizedBox(width: 4),
                Text('Live',
                    style: TextStyle(
                        color: AppColors.tealAccent, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.tealAccent.withValues(alpha: 0.03),
              AppColors.scaffoldBg,
            ],
          ),
        ),
        child: Column(
          children: [
            // Messages list
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _messages.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.chat_bubble_outline_rounded,
                                  size: 48, color: AppColors.subtleText),
                              const SizedBox(height: 12),
                              const Text('No messages yet',
                                  style: TextStyle(
                                      color: AppColors.subtleText)),
                              const SizedBox(height: 4),
                              const Text('Say hello! 👋',
                                  style: TextStyle(
                                      color: AppColors.subtleText,
                                      fontSize: 12)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            final msg = _messages[index];
                            final isMe = msg.senderId == _userId;
                            final showName = index == 0 ||
                                _messages[index - 1].senderId !=
                                    msg.senderId;

                            return _MessageBubble(
                              message: msg,
                              isMe: isMe,
                              showName: showName,
                            )
                                .animate()
                                .fadeIn(duration: 200.ms)
                                .slideY(begin: 0.1);
                          },
                        ),
            ),

            // Input bar
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              decoration: BoxDecoration(
                color: AppColors.surfaceDark,
                border: Border(
                  top: BorderSide(
                      color: AppColors.glassBorder.withValues(alpha: 0.4)),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      style: const TextStyle(
                          color: AppColors.white, fontSize: 14),
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: const TextStyle(
                            color: AppColors.subtleText, fontSize: 13),
                        filled: true,
                        fillColor: AppColors.cardBg,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(
                              color: AppColors.glassBorder
                                  .withValues(alpha: 0.4)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(
                              color: AppColors.primaryGreen),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _send,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: _sending
                            ? AppColors.primaryGreen.withValues(alpha: 0.4)
                            : AppColors.primaryGreen,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: _sending
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.white),
                            )
                          : const Icon(Icons.send_rounded,
                              color: AppColors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Message bubble ─────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  final bool showName;

  const _MessageBubble({
    required this.message,
    required this.isMe,
    required this.showName,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: showName ? 12 : 3,
        bottom: 2,
      ),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (showName && !isMe)
            Padding(
              padding: const EdgeInsets.only(left: 12, bottom: 4),
              child: Text(
                message.senderName,
                style: const TextStyle(
                    color: AppColors.subtleText,
                    fontSize: 11,
                    fontWeight: FontWeight.w500),
              ),
            ),
          Row(
            mainAxisAlignment:
                isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isMe) ...[
                // Avatar
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [
                      AppColors.tealAccent,
                      AppColors.primaryGreen
                    ]),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      message.senderName.isNotEmpty
                          ? message.senderName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              // Bubble
              Flexible(
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.72,
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isMe
                        ? AppColors.primaryGreen.withValues(alpha: 0.85)
                        : AppColors.cardBg,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isMe ? 18 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 18),
                    ),
                    border: isMe
                        ? null
                        : Border.all(
                            color:
                                AppColors.glassBorder.withValues(alpha: 0.5)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        message.content,
                        style: TextStyle(
                          color: isMe
                              ? AppColors.white
                              : AppColors.white,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _formatTime(message.createdAt),
                        style: TextStyle(
                          color: isMe
                              ? AppColors.white.withValues(alpha: 0.6)
                              : AppColors.subtleText,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
