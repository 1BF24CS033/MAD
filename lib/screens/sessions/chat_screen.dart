import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/message_model.dart';
import '../../services/supabase_service.dart';
import '../../theme/app_theme.dart';

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

  SupabaseClient get _db => SupabaseService.client;
  String get _userId => SupabaseService.currentUserId ?? '';

  // Select with sender name join
  static const _select =
      '*, sender:profiles!messages_sender_id_fkey(name)';

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

  // ── Load all history ────────────────────────────────────────────────────

  Future<void> _loadMessages() async {
    try {
      final rows = await _db
          .from('messages')
          .select(_select)
          .eq('request_id', widget.requestId)
          .order('created_at');

      if (!mounted) return;
      setState(() {
        _messages.clear();
        _messages.addAll(rows
            .cast<Map<String, dynamic>>()
            .map((r) => MessageModel.fromJson(r, currentUserId: _userId)));
        _loading = false;
      });
      // Double frame callback ensures list is fully laid out before scrolling
      WidgetsBinding.instance.addPostFrameCallback((_) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom(animate: false);
        });
      });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Realtime — listen for new messages from the other person ────────────

  void _subscribeRealtime() {
    _channel = _db
        .channel('chat_${widget.requestId}')
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
            final newId = payload.newRecord['id'] as String?;
            if (newId == null) return;

            // Skip if we already have this message (own sends added optimistically)
            if (_messages.any((m) => m.id == newId)) return;

            // Fetch full row with sender name
            try {
              final row = await _db
                  .from('messages')
                  .select(_select)
                  .eq('id', newId)
                  .single();

              final msg =
                  MessageModel.fromJson(row, currentUserId: _userId);
              if (mounted) {
                setState(() => _messages.add(msg));
                _scrollToBottom();
              }
            } catch (_) {}
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
        // Restore text
        _controller.text = text;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _scrollToBottom({bool animate = true}) {
    // With reverse:true ListView, scrolling to 0 shows the latest message
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      if (animate) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      } else {
        _scrollController.jumpTo(0);
      }
    });
  }

  // ── UI ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceDark,
        elevation: 1,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Row(
          children: [
            // Avatar
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                    colors: [AppColors.tealAccent, AppColors.primaryGreen]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  widget.otherPersonName.isNotEmpty
                      ? widget.otherPersonName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                      color: AppColors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.otherPersonName,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600)),
                  Text(widget.topic,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.subtleText)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Live indicator
          Container(
            margin: const EdgeInsets.only(right: 14),
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.circle,
                    color: AppColors.primaryGreen, size: 7),
                SizedBox(width: 4),
                Text('Live',
                    style: TextStyle(
                        color: AppColors.primaryGreen, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Messages ──────────────────────────────────────────────────
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.chat_bubble_outline_rounded,
                                size: 52, color: AppColors.subtleText),
                            const SizedBox(height: 12),
                            const Text('No messages yet',
                                style: TextStyle(
                                    color: AppColors.subtleText,
                                    fontSize: 15)),
                            const SizedBox(height: 4),
                            const Text('Say hello! 👋',
                                style: TextStyle(
                                    color: AppColors.subtleText,
                                    fontSize: 13)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding:
                            const EdgeInsets.fromLTRB(12, 16, 12, 8),
                        reverse: true,
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          // Reverse index so newest is at bottom
                          final actualIndex = _messages.length - 1 - index;
                          final msg = _messages[actualIndex];
                          final isMe = msg.senderId == _userId;

                          final showDate = actualIndex == 0 ||
                              !_sameDay(
                                  _messages[actualIndex - 1].createdAt,
                                  msg.createdAt);

                          final showAvatar = !isMe &&
                              (actualIndex == _messages.length - 1 ||
                                  _messages[actualIndex + 1].senderId !=
                                      msg.senderId);

                          return Column(
                            children: [
                              if (showDate)
                                _DateSeparator(msg.createdAt),
                              _MessageBubble(
                                message: msg,
                                isMe: isMe,
                                showAvatar: showAvatar,
                              ),
                            ],
                          );
                        },
                      ),
          ),

          // ── Input bar ─────────────────────────────────────────────────
          Container(
            padding: EdgeInsets.fromLTRB(
                12, 8, 12, 8 + MediaQuery.of(context).viewInsets.bottom),
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              border: Border(
                top: BorderSide(
                    color: AppColors.glassBorder.withValues(alpha: 0.4)),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Text field
                Expanded(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 120),
                    child: TextField(
                      controller: _controller,
                      style: const TextStyle(
                          color: AppColors.white, fontSize: 15),
                      maxLines: null,
                      textInputAction: TextInputAction.newline,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Message...',
                        hintStyle: const TextStyle(
                            color: AppColors.subtleText, fontSize: 14),
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
                              color: AppColors.primaryGreen, width: 1.5),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Send button
                GestureDetector(
                  onTap: _controller.text.trim().isNotEmpty ? _send : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _controller.text.trim().isNotEmpty
                          ? AppColors.primaryGreen
                          : AppColors.cardBg,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: _sending
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.white),
                          )
                        : Icon(
                            Icons.send_rounded,
                            color: _controller.text.trim().isNotEmpty
                                ? AppColors.white
                                : AppColors.subtleText,
                            size: 20,
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

// ── Date separator ─────────────────────────────────────────────────────────

class _DateSeparator extends StatelessWidget {
  final DateTime date;
  const _DateSeparator(this.date);

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    String label;
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      label = 'Today';
    } else if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day - 1) {
      label = 'Yesterday';
    } else {
      label = '${date.day}/${date.month}/${date.year}';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
              child: Divider(
                  color: AppColors.glassBorder.withValues(alpha: 0.4))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(label,
                style: const TextStyle(
                    color: AppColors.subtleText, fontSize: 11)),
          ),
          Expanded(
              child: Divider(
                  color: AppColors.glassBorder.withValues(alpha: 0.4))),
        ],
      ),
    );
  }
}

// ── Message bubble ─────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  final bool showAvatar;

  const _MessageBubble({
    required this.message,
    required this.isMe,
    required this.showAvatar,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: 2,
        bottom: 2,
        left: isMe ? 48 : 0,
        right: isMe ? 0 : 48,
      ),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Other person avatar (only on last message in group)
          if (!isMe)
            SizedBox(
              width: 32,
              child: showAvatar
                  ? Container(
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
                    )
                  : null,
            ),

          // Bubble
          GestureDetector(
            onLongPress: () {
              Clipboard.setData(ClipboardData(text: message.content));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Copied'),
                  duration: Duration(seconds: 1),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.68,
              ),
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: isMe
                    ? AppColors.primaryGreen
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
                        color: AppColors.glassBorder
                            .withValues(alpha: 0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Sender name for group chats (non-me only)
                  if (!isMe)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Text(
                        message.senderName,
                        style: const TextStyle(
                            color: AppColors.tealAccent,
                            fontSize: 11,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  Text(
                    message.content,
                    style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 14,
                        height: 1.4),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _formatTime(message.createdAt),
                    style: TextStyle(
                      color: isMe
                          ? AppColors.white.withValues(alpha: 0.55)
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
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
