import 'dart:async';
import 'package:flutter/material.dart';
import '../models/reminder_model.dart';
import '../services/reminder_service.dart';
import '../services/supabase_service.dart';
import '../services/web_notification_service.dart';

class ReminderProvider extends ChangeNotifier {
  List<ReminderModel> _reminders = [];
  bool _loading = false;
  Timer? _pollTimer;

  List<ReminderModel> get reminders => _reminders;
  List<ReminderModel> get upcoming =>
      _reminders.where((r) => r.isUpcoming).toList();
  List<ReminderModel> get past =>
      _reminders.where((r) => r.isSent || r.isDue).toList();
  bool get loading => _loading;

  // ── Init ────────────────────────────────────────────────────────────────────

  /// Call once after login. Loads reminders and starts the polling timer.
  Future<void> init() async {
    await WebNotificationService.requestPermission();
    await loadReminders();
    _startPolling();
  }

  /// Poll every 60 seconds for due reminders.
  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      _checkDueReminders();
    });
    // Also check immediately on init
    _checkDueReminders();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  // ── Load ────────────────────────────────────────────────────────────────────

  Future<void> loadReminders() async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) return;

    _loading = true;
    notifyListeners();

    try {
      _reminders = await ReminderService.fetchReminders(userId);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // ── Check & fire due reminders ───────────────────────────────────────────

  Future<void> _checkDueReminders() async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) return;

    final due = await ReminderService.fetchDueReminders(userId);
    for (final reminder in due) {
      // Fire browser notification
      WebNotificationService.show(
        title: reminder.title,
        body: reminder.body,
      );

      // Mark as sent in DB
      await ReminderService.markSent(reminder.id);

      // Update local state
      final index = _reminders.indexWhere((r) => r.id == reminder.id);
      if (index != -1) {
        _reminders[index] = ReminderModel(
          id: reminder.id,
          userId: reminder.userId,
          requestId: reminder.requestId,
          title: reminder.title,
          body: reminder.body,
          remindAt: reminder.remindAt,
          isSent: true,
          createdAt: reminder.createdAt,
        );
      }
    }

    if (due.isNotEmpty) notifyListeners();
  }

  // ── CRUD ─────────────────────────────────────────────────────────────────

  Future<void> createReminder({
    String? requestId,
    required String title,
    required String body,
    required DateTime remindAt,
  }) async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) return;

    final reminder = await ReminderService.createReminder(
      userId: userId,
      requestId: requestId,
      title: title,
      body: body,
      remindAt: remindAt,
    );

    _reminders.add(reminder);
    _reminders.sort((a, b) => a.remindAt.compareTo(b.remindAt));
    notifyListeners();
  }

  Future<void> deleteReminder(String reminderId) async {
    await ReminderService.deleteReminder(reminderId);
    _reminders.removeWhere((r) => r.id == reminderId);
    notifyListeners();
  }
}
