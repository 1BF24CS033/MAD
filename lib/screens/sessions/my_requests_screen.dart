import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../providers/help_request_provider.dart';
import '../../providers/reminder_provider.dart';
import '../../models/help_request.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_card.dart';
import 'post_help_request_screen.dart';
import 'review_screen.dart';
import '../reminders/reminders_screen.dart';
import 'chat_screen.dart';

class MyRequestsScreen extends StatefulWidget {
  const MyRequestsScreen({super.key});

  @override
  State<MyRequestsScreen> createState() => _MyRequestsScreenState();
}

class _MyRequestsScreenState extends State<MyRequestsScreen> {
  @override
  void initState() {
    super.initState();
    // Always fetch fresh data so status changes (e.g. mentor accepted) are visible
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HelpRequestProvider>().loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HelpRequestProvider>();
    final requests = provider.myRequests.where((r) => r.isHelp).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Help Requests'),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        actions: [
          IconButton(
            onPressed: () => provider.loadData(),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const PostHelpRequestScreen()),
          );
        },
        backgroundColor: AppColors.primaryGreen,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Request'),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.sage.withValues(alpha: 0.05),
              AppColors.scaffoldBg,
            ],
          ),
        ),
        child: SafeArea(
          child: provider.loading
              ? const Center(child: CircularProgressIndicator())
              : requests.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.help_outline_rounded,
                              size: 56, color: AppColors.subtleText),
                          const SizedBox(height: 12),
                          const Text(
                            'No help requests yet',
                            style:
                                TextStyle(color: AppColors.subtleText),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      const PostHelpRequestScreen()),
                            ),
                            icon: const Icon(Icons.add_rounded, size: 16),
                            label: const Text('Post a Request'),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryGreen),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: requests.length,
                      itemBuilder: (context, index) {
                        final req = requests[index];
                        return _MyRequestCard(
                          request: req,
                          onCancel: req.isOpen
                              ? () async {
                                  await provider.cancelRequest(req.id);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(
                                      const SnackBar(
                                          content:
                                              Text('Request cancelled')),
                                    );
                                  }
                                }
                              : null,
                          onShareEmail: req.isAccepted && !req.emailShared
                              ? () async {
                                  await provider.shareEmail(req.id);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            'Email shared with your mentor'),
                                        backgroundColor:
                                            AppColors.primaryGreen,
                                      ),
                                    );
                                  }
                                }
                              : null,
                          onSetReminder: (req.isAccepted || req.isOpen)
                              ? () {
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: AppColors.cardBg,
                                    shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.vertical(
                                          top: Radius.circular(24)),
                                    ),
                                    builder: (_) => ChangeNotifierProvider.value(
                                      value: context.read<ReminderProvider>(),
                                      child: _AddReminderSheet(
                                        requestId: req.id,
                                        prefillTitle:
                                            'Session: ${req.topic}',
                                      ),
                                    ),
                                  );
                                }
                              : null,
                          onChat: (req.isAccepted ||
                                  req.isPendingReview ||
                                  req.isCompleted)
                              ? () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ChatScreen(
                                        requestId: req.id,
                                        otherPersonName:
                                            req.mentorName ?? 'Mentor',
                                        topic: req.topic,
                                      ),
                                    ),
                                  )
                              : null,
                          onConfirmComplete: req.isPendingReview
                              ? () async {
                                  await provider.confirmComplete(req.id);
                                  if (context.mounted) {
                                    // Navigate to review screen
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ReviewScreen(
                                          requestId: req.id,
                                          mentorId: req.mentorId!,
                                          mentorName:
                                              req.mentorName ?? 'Mentor',
                                          topic: req.topic,
                                        ),
                                      ),
                                    );
                                  }
                                }
                              : null,
                        )
                            .animate()
                            .fadeIn(delay: (index * 80).ms)
                            .slideY(begin: 0.05);
                      },
                    ),
        ),
      ),
    );
  }
}

class _MyRequestCard extends StatelessWidget {
  final HelpRequest request;
  final VoidCallback? onCancel;
  final VoidCallback? onShareEmail;
  final VoidCallback? onSetReminder;
  final VoidCallback? onChat;
  final VoidCallback? onConfirmComplete;

  const _MyRequestCard({
    required this.request,
    this.onCancel,
    this.onShareEmail,
    this.onSetReminder,
    this.onChat,
    this.onConfirmComplete,
  });

  Color get _statusColor {
    switch (request.status) {
      case 'open':
        return AppColors.tealAccent;
      case 'accepted':
        return AppColors.primaryGreen;
      case 'pending_review':
        return AppColors.peach;
      case 'completed':
        return AppColors.sage;
      default:
        return AppColors.subtleText;
    }
  }

  String get _statusText {
    switch (request.status) {
      case 'pending_review':
        return 'AWAITING YOUR REVIEW';
      default:
        return request.status.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderColor: _statusColor.withValues(alpha: 0.25),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _statusText,
                  style: TextStyle(
                    color: _statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                request.topic,
                style: const TextStyle(
                    color: AppColors.subtleText, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            request.description,
            style: const TextStyle(
                color: AppColors.white, fontSize: 14, height: 1.4),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          if (request.mentorName != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.psychology_rounded,
                    size: 14, color: AppColors.primaryGreen),
                const SizedBox(width: 4),
                Text(
                  'Accepted by ${request.mentorName}',
                  style: const TextStyle(
                      color: AppColors.primaryGreen, fontSize: 12),
                ),
              ],
            ),
          ],
          // Email shared / Meet link section
          if (request.isAccepted || request.isPendingReview || request.isCompleted) ...[
            const SizedBox(height: 8),
            if (request.emailShared && request.mentorEmail != null)
              _ContactRow(
                icon: Icons.email_outlined,
                label: 'Mentor: ${request.mentorEmail}',
                email: request.mentorEmail!,
              ),
            if (request.meetLink != null)
              _ContactRow(
                icon: Icons.videocam_rounded,
                label: 'Google Meet link',
                email: request.meetLink!,
                isMeetLink: true,
              ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '${request.durationMinutes} min',
                style: const TextStyle(
                    color: AppColors.subtleText, fontSize: 12),
              ),
              if (request.wantsMeet) ...[
                const SizedBox(width: 8),
                const Icon(Icons.videocam_rounded,
                    size: 14, color: AppColors.sage),
              ],
              const Spacer(),
              if (onCancel != null)
                TextButton(
                  onPressed: onCancel,
                  style: TextButton.styleFrom(
                      foregroundColor: Colors.red.shade300),
                  child: const Text('Cancel', style: TextStyle(fontSize: 12)),
                ),
            ],
          ),
          // Action buttons
          if (onChat != null) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 42,
              child: ElevatedButton.icon(
                onPressed: onChat,
                icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                label: const Text('Open Chat'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.tealAccent,
                ),
              ),
            ),
          ],
          if (onShareEmail != null) ...[
            const Divider(color: AppColors.glassBorder, height: 20),
            SizedBox(
              width: double.infinity,
              height: 40,
              child: OutlinedButton.icon(
                onPressed: onShareEmail,
                icon: const Icon(Icons.mail_outline_rounded, size: 16),
                label: const Text('Share My Email with Mentor'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.tealAccent,
                  side: BorderSide(
                      color: AppColors.tealAccent.withValues(alpha: 0.4)),
                ),
              ),
            ),
          ],
          if (onSetReminder != null) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 40,
              child: OutlinedButton.icon(
                onPressed: onSetReminder,
                icon: const Icon(Icons.alarm_add_rounded, size: 16),
                label: const Text('Set a Reminder'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.peach,
                  side: BorderSide(
                      color: AppColors.peach.withValues(alpha: 0.4)),
                ),
              ),
            ),
          ],
          if (onConfirmComplete != null) ...[
            const Divider(color: AppColors.glassBorder, height: 20),
            const Text(
              'Your mentor marked this as done. Please confirm:',
              style: TextStyle(color: AppColors.subtleText, fontSize: 12),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                onPressed: onConfirmComplete,
                icon: const Icon(Icons.check_circle_outline, size: 18),
                label: const Text('Confirm & Leave Review'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String email;
  final bool isMeetLink;

  const _ContactRow({
    required this.icon,
    required this.label,
    required this.email,
    this.isMeetLink = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        if (isMeetLink) {
          // Open Meet link in browser
          final uri = Uri.tryParse(email);
          if (uri != null && await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          } else {
            // Fallback: copy to clipboard
            Clipboard.setData(ClipboardData(text: email));
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Meet link copied!'),
                  behavior: SnackBarBehavior.floating,
                  duration: Duration(seconds: 1),
                ),
              );
            }
          }
        } else {
          Clipboard.setData(ClipboardData(text: email));
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Email copied!'),
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 1),
              ),
            );
          }
        }
      },
      onLongPress: () {
        Clipboard.setData(ClipboardData(text: email));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isMeetLink ? 'Meet link copied!' : 'Email copied!'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 1),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isMeetLink
              ? AppColors.sage.withValues(alpha: 0.1)
              : AppColors.tealAccent.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 14,
                color:
                    isMeetLink ? AppColors.sage : AppColors.tealAccent),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                    color: isMeetLink
                        ? AppColors.sage
                        : AppColors.tealAccent,
                    fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
                isMeetLink
                    ? Icons.open_in_new_rounded
                    : Icons.copy_rounded,
                size: 14,
                color: AppColors.subtleText),
          ],
        ),
      ),
    );
  }
}

// ── Add Reminder Sheet (inline copy for use from my_requests_screen) ─────────

class _AddReminderSheet extends StatefulWidget {
  final String? requestId;
  final String? prefillTitle;

  const _AddReminderSheet({this.requestId, this.prefillTitle});

  @override
  State<_AddReminderSheet> createState() => _AddReminderSheetState();
}

class _AddReminderSheetState extends State<_AddReminderSheet> {
  late final TextEditingController _titleController;
  final _bodyController = TextEditingController();
  DateTime _selectedDate = DateTime.now().add(const Duration(hours: 1));
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _titleController =
        TextEditingController(text: widget.prefillTitle ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.dark(
            primary: AppColors.primaryGreen,
            surface: AppColors.cardBg,
          ),
        ),
        child: child!,
      ),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDate),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.dark(
            primary: AppColors.primaryGreen,
            surface: AppColors.cardBg,
          ),
        ),
        child: child!,
      ),
    );
    if (time == null || !mounted) return;

    setState(() {
      _selectedDate = DateTime(
          date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _save() async {
    if (_titleController.text.trim().isEmpty) return;
    setState(() => _loading = true);
    try {
      await context.read<ReminderProvider>().createReminder(
            requestId: widget.requestId,
            title: _titleController.text.trim(),
            body: _bodyController.text.trim(),
            remindAt: _selectedDate,
          );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Reminder set! ⏰'),
            backgroundColor: AppColors.primaryGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.glassBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Set Reminder',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 20),
          TextField(
            controller: _titleController,
            style: const TextStyle(color: AppColors.white),
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Title',
              labelStyle: TextStyle(color: AppColors.subtleText),
              prefixIcon: Icon(Icons.title_rounded,
                  color: AppColors.primaryGreen),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _bodyController,
            style: const TextStyle(color: AppColors.white),
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Note (optional)',
              labelStyle: TextStyle(color: AppColors.subtleText),
              prefixIcon: Icon(Icons.notes_rounded,
                  color: AppColors.primaryGreen),
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _pickDateTime,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.glassBorder),
              ),
              child: Row(
                children: [
                  const Icon(Icons.schedule_rounded,
                      color: AppColors.primaryGreen, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _fmt(_selectedDate),
                      style: const TextStyle(
                          color: AppColors.white, fontSize: 14),
                    ),
                  ),
                  const Icon(Icons.edit_calendar_rounded,
                      color: AppColors.subtleText, size: 16),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed:
                  _titleController.text.trim().isNotEmpty && !_loading
                      ? _save
                      : null,
              icon: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.white))
                  : const Icon(Icons.alarm_add_rounded, size: 18),
              label: const Text('Set Reminder'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen),
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(DateTime dt) {
    final months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}  ·  $h:$m';
  }
}
