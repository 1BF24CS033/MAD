import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/supabase_service.dart';
import '../../theme/app_theme.dart';

class GroupChatScreen extends StatefulWidget {
  final String roomId;
  final String roomType; // 'project' or 'group_study'
  final String title;
  final String subtitle;

  const GroupChatScreen({
    super.key,
    required this.roomId,
    required this.roomType,
    required this.title,
    required this.subtitle,
  });

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<_Msg> _messages = [];
  bool _loading = true;
  bool _sending = false;
  RealtimeChannel? _channel;

  SupabaseClient get _db => SupabaseService.client;
  String get _userId => SupabaseService.currentUserId ?? '';

  static const _select =
      '*, sender:profiles!group_messages_sender_id_fkey(name)';

  @override
  void initState() {
    super.initState();
    _load();
    _subscribe();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _channel?.unsubscribe();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final rows = await _db
          .from('group_messages')
          .select(_select)
          .eq('room_id', widget.roomId)
          .eq('room_type', widget.roomType)
          .order('created_at', ascending: true);

      if (!mounted) return;
      setState(() {
        _messages.clear();
        _messages.addAll(rows.cast<Map<String, dynamic>>().map(_parse));
        _loading = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        WidgetsBinding.instance
            .addPostFrameCallback((_) => _jump());
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _subscribe() {
    _channel = _db
        .channel('grp_${widget.roomId}')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'group_messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'room_id',
            value: widget.roomId,
          ),
          callback: (payload) async {
            final id = payload.newRecord['id'] as String?;
            if (id == null || _messages.any((m) => m.id == id)) return;
            try {
              final row = await _db
                  .from('group_messages')
                  .select(_select)
                  .eq('id', id)
                  .single();
              if (mounted) {
                setState(() => _messages.add(_parse(row)));
                _scrollToBottom();
              }
            } catch (_) {}
          },
        )
        .subscribe();
  }

  _Msg _parse(Map<String, dynamic> r) {
    final sender = r['sender'] as Map<String, dynamic>?;
    return _Msg(
      id: r['id'] as String,
      senderId: r['sender_id'] as String,
      senderName: r['sender_id'] == _userId
          ? 'You'
          : (sender?['name'] as String? ?? 'Unknown'),
      content: r['content'] as String,
      createdAt: DateTime.parse(r['created_at'] as String).toLocal(),
    );
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    _controller.clear();
    setState(() => _sending = true);
    try {
      final row = await _db
          .from('group_messages')
          .insert({
            'room_id': widget.roomId,
            'room_type': widget.roomType,
            'sender_id': _userId,
            'content': text,
          })
          .select(_select)
          .single();
      if (mounted) {
        setState(() => _messages.add(_parse(row)));
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        _controller.text = text;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed: $e'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _jump() {
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(
          _scrollController.position.maxScrollExtent);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceDark,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  AppColors.sage,
                  AppColors.primaryGreen,
                ]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.groups_rounded,
                  color: AppColors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.title,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis),
                  Text(widget.subtitle,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.subtleText)),
                ],
              ),
            ),
          ],
        ),
        actions: [
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
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.chat_bubble_outline_rounded,
                                size: 48, color: AppColors.subtleText),
                            SizedBox(height: 12),
                            Text('No messages yet',
                                style: TextStyle(
                                    color: AppColors.subtleText,
                                    fontSize: 15)),
                            SizedBox(height: 4),
                            Text('Start the conversation! 👋',
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
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final msg = _messages[index];
                          final isMe = msg.senderId == _userId;
                          final showName = !isMe &&
                              (index == 0 ||
                                  _messages[index - 1].senderId !=
                                      msg.senderId);

                          return _Bubble(
                              msg: msg,
                              isMe: isMe,
                              showName: showName);
                        },
                      ),
          ),
          // Input
          Container(
            padding: EdgeInsets.fromLTRB(
                12,
                8,
                12,
                8 + MediaQuery.of(context).viewInsets.bottom),
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
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: const TextStyle(
                        color: AppColors.white, fontSize: 15),
                    maxLines: null,
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
                const SizedBox(width: 8),
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
                        : Icon(Icons.send_rounded,
                            color: _controller.text.trim().isNotEmpty
                                ? AppColors.white
                                : AppColors.subtleText,
                            size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Msg {
  final String id, senderId, senderName, content;
  final DateTime createdAt;
  _Msg(
      {required this.id,
      required this.senderId,
      required this.senderName,
      required this.content,
      required this.createdAt});
}

class _Bubble extends StatelessWidget {
  final _Msg msg;
  final bool isMe;
  final bool showName;
  const _Bubble(
      {required this.msg, required this.isMe, required this.showName});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          top: showName ? 10 : 2,
          bottom: 2,
          left: isMe ? 48 : 0,
          right: isMe ? 0 : 48),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe)
            SizedBox(
              width: 32,
              child: showName
                  ? Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [
                          AppColors.sage,
                          AppColors.primaryGreen
                        ]),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          msg.senderName.isNotEmpty
                              ? msg.senderName[0].toUpperCase()
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
          GestureDetector(
            onLongPress: () {
              Clipboard.setData(ClipboardData(text: msg.content));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Copied'),
                    duration: Duration(seconds: 1),
                    behavior: SnackBarBehavior.floating),
              );
            },
            child: Container(
              constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.68),
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: isMe ? AppColors.primaryGreen : AppColors.cardBg,
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
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isMe && showName)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Text(msg.senderName,
                          style: const TextStyle(
                              color: AppColors.sage,
                              fontSize: 11,
                              fontWeight: FontWeight.w600)),
                    ),
                  Text(msg.content,
                      style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 14,
                          height: 1.4)),
                  const SizedBox(height: 3),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Text(
                      _fmt(msg.createdAt),
                      style: TextStyle(
                          color: isMe
                              ? AppColors.white.withValues(alpha: 0.55)
                              : AppColors.subtleText,
                          fontSize: 10),
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

  String _fmt(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
