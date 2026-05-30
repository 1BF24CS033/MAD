import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/reminder_model.dart';
import 'supabase_service.dart';

class ReminderService {
  static SupabaseClient get _db => SupabaseService.client;

  /// Fetch all reminders for the current user, ordered by remind_at.
  static Future<List<ReminderModel>> fetchReminders(String userId) async {
    final rows = await _db
        .from('reminders')
        .select()
        .eq('user_id', userId)
        .order('remind_at');

    return rows
        .cast<Map<String, dynamic>>()
        .map(ReminderModel.fromJson)
        .toList();
  }

  /// Fetch reminders that are due now and not yet sent.
  static Future<List<ReminderModel>> fetchDueReminders(
      String userId) async {
    final now = DateTime.now().toUtc().toIso8601String();
    final rows = await _db
        .from('reminders')
        .select()
        .eq('user_id', userId)
        .eq('is_sent', false)
        .lte('remind_at', now)
        .order('remind_at');

    return rows
        .cast<Map<String, dynamic>>()
        .map(ReminderModel.fromJson)
        .toList();
  }

  /// Create a new reminder.
  static Future<ReminderModel> createReminder({
    required String userId,
    String? requestId,
    required String title,
    required String body,
    required DateTime remindAt,
  }) async {
    final row = await _db
        .from('reminders')
        .insert({
          'user_id': userId,
          if (requestId != null) 'request_id': requestId,
          'title': title,
          'body': body,
          'remind_at': remindAt.toUtc().toIso8601String(),
          'is_sent': false,
        })
        .select()
        .single();

    return ReminderModel.fromJson(row);
  }

  /// Mark a reminder as sent so it doesn't fire again.
  static Future<void> markSent(String reminderId) async {
    await _db
        .from('reminders')
        .update({'is_sent': true})
        .eq('id', reminderId);
  }

  /// Delete a reminder.
  static Future<void> deleteReminder(String reminderId) async {
    await _db.from('reminders').delete().eq('id', reminderId);
  }
}
