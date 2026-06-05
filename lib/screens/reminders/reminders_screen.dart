import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../models/reminder_model.dart';
import '../../providers/reminder_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_card.dart';

class RemindersScreen extends StatelessWidget {
  const RemindersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReminderProvider>();
    final upcoming = provider.upcoming;
    final past = provider.past;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reminders'),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        actions: [
          IconButton(
            onPressed: () => provider.loadReminders(),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddReminderSheet(context),
        backgroundColor: AppColors.primaryGreen,
        icon: const Icon(Icons.add_alarm_rounded),
        label: const Text('Add Reminder'),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.peach.withValues(alpha: 0.05),
              AppColors.scaffoldBg,
            ],
          ),
        ),
        child: SafeArea(
          child: provider.loading
              ? const Center(child: CircularProgressIndicator())
              : (upcoming.isEmpty && past.isEmpty)
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.alarm_rounded,
                              size: 56, color: AppColors.subtleText),
                          const SizedBox(height: 12),
                          const Text('No reminders yet',
                              style:
                                  TextStyle(color: AppColors.subtleText)),
                          const SizedBox(height: 6),
                          const Text(
                            'Tap + Add Reminder to set one',
                            style: TextStyle(
                                color: AppColors.subtleText, fontSize: 12),
                          ),
                        ],
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                      children: [
                        if (upcoming.isNotEmpty) ...[
                          _SectionHeader(
                              'Upcoming (${upcoming.length})'),
                          const SizedBox(height: 10),
                          ...upcoming.asMap().entries.map((e) =>
                              _ReminderCard(
                                reminder: e.value,
                                onDelete: () => provider
                                    .deleteReminder(e.value.id),
                              )
                                  .animate()
                                  .fadeIn(delay: (e.key * 60).ms)
                                  .slideX(begin: 0.05)),
                          const SizedBox(height: 24),
                        ],
                        if (past.isNotEmpty) ...[
                          _SectionHeader('Past (${past.length})'),
                          const SizedBox(height: 10),
                          ...past.asMap().entries.map((e) =>
                              _ReminderCard(
                                reminder: e.value,
                                onDelete: () => provider
                                    .deleteReminder(e.value.id),
                                dimmed: true,
                              )
                                  .animate()
                                  .fadeIn(delay: (e.key * 60).ms)),
                        ],
                      ],
                    ),
        ),
      ),
    );
  }

  void _showAddReminderSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _AddReminderSheet(),
    );
  }
}

// Section header

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text, style: Theme.of(context).textTheme.titleMedium);
  }
}

// Reminder card

class _ReminderCard extends StatelessWidget {
  final ReminderModel reminder;
  final VoidCallback onDelete;
  final bool dimmed;

  const _ReminderCard({
    required this.reminder,
    required this.onDelete,
    this.dimmed = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = dimmed ? AppColors.subtleText : AppColors.peach;
    final timeStr = _formatDateTime(reminder.remindAt);

    return GlassCard(
      borderColor: color.withValues(alpha: dimmed ? 0.1 : 0.3),
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              reminder.isSent
                  ? Icons.check_circle_outline_rounded
                  : Icons.alarm_rounded,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reminder.title,
                  style: TextStyle(
                    color: dimmed ? AppColors.subtleText : AppColors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                if (reminder.body.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    reminder.body,
                    style: const TextStyle(
                        color: AppColors.subtleText, fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.schedule_rounded,
                        size: 12, color: color),
                    const SizedBox(width: 4),
                    Text(
                      timeStr,
                      style: TextStyle(color: color, fontSize: 11),
                    ),
                    if (reminder.isSent) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.sage.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('Sent',
                            style: TextStyle(
                                color: AppColors.sage, fontSize: 10)),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline_rounded,
                size: 18, color: AppColors.subtleText),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    final now = DateTime.now();
    final diff = dt.difference(now);

    String datePart;
    if (dt.year == now.year &&
        dt.month == now.month &&
        dt.day == now.day) {
      datePart = 'Today';
    } else if (diff.inDays == 1) {
      datePart = 'Tomorrow';
    } else if (diff.inDays < 0) {
      datePart = '${(-diff.inDays)}d ago';
    } else {
      datePart =
          '${dt.day}/${dt.month}/${dt.year}';
    }

    final hour = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$datePart at $hour:$min';
  }
}

// Add Reminder bottom sheet

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
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed: $e'),
              backgroundColor: Colors.red),
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
          // Handle
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
          Text('New Reminder',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 20),

          // Title
          TextField(
            controller: _titleController,
            style: const TextStyle(color: AppColors.white),
            decoration: InputDecoration(
              labelText: 'Title',
              labelStyle:
                  const TextStyle(color: AppColors.subtleText),
              prefixIcon: const Icon(Icons.title_rounded,
                  color: AppColors.primaryGreen),
              filled: true,
              fillColor: AppColors.glassBg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.glassBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.glassBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: AppColors.primaryGreen),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Note (optional)
          TextField(
            controller: _bodyController,
            style: const TextStyle(color: AppColors.white),
            maxLines: 2,
            decoration: InputDecoration(
              labelText: 'Note (optional)',
              labelStyle:
                  const TextStyle(color: AppColors.subtleText),
              prefixIcon: const Icon(Icons.notes_rounded,
                  color: AppColors.primaryGreen),
              filled: true,
              fillColor: AppColors.glassBg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.glassBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.glassBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: AppColors.primaryGreen),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Date/time picker
          GestureDetector(
            onTap: _pickDateTime,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.glassBg,
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
                      _formatSelected(_selectedDate),
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

          // Save button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _titleController.text.trim().isNotEmpty &&
                      !_loading
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
                backgroundColor: AppColors.primaryGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatSelected(DateTime dt) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final day = days[dt.weekday - 1];
    final month = months[dt.month - 1];
    final hour = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$day, ${dt.day} $month ${dt.year}  ·  $hour:$min';
  }
}
