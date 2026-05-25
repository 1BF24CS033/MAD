import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/help_request.dart';
import 'supabase_service.dart';

class HelpRequestService {
  static SupabaseClient get _db => SupabaseService.client;

  static const _select = '''
    *,
    learner:profiles!help_requests_learner_id_fkey(name),
    mentor:profiles!help_requests_mentor_id_fkey(name)
  ''';

  /// All open requests (for mentors to browse).
  static Future<List<HelpRequest>> fetchOpenRequests(
      {String? topic}) async {
    final currentUserId = SupabaseService.currentUserId ?? '';
    var query = _db
        .from('help_requests')
        .select(_select)
        .eq('status', 'open')
        // Don't show the current user's own requests in the mentor browse view
        .neq('learner_id', currentUserId)
        .order('created_at', ascending: false);

    final rows = await query;
    return rows
        .cast<Map<String, dynamic>>()
        .where((r) {
          if (topic == null || topic.isEmpty) return true;
          return (r['topic'] as String)
              .toLowerCase()
              .contains(topic.toLowerCase());
        })
        .map((r) => HelpRequest.fromJson(r, currentUserId: currentUserId))
        .toList();
  }

  /// Requests posted by the current learner.
  static Future<List<HelpRequest>> fetchMyRequests(
      String userId) async {
    final rows = await _db
        .from('help_requests')
        .select(_select)
        .eq('learner_id', userId)
        .order('created_at', ascending: false);

    return rows
        .cast<Map<String, dynamic>>()
        .map((r) => HelpRequest.fromJson(r, currentUserId: userId))
        .toList();
  }

  /// Post a new help request.
  static Future<HelpRequest> postRequest({
    required String learnerId,
    required String topic,
    required String description,
    required int durationMinutes,
  }) async {
    final row = await _db
        .from('help_requests')
        .insert({
          'learner_id': learnerId,
          'topic': topic,
          'description': description,
          'duration_minutes': durationMinutes,
          'status': 'open',
        })
        .select(_select)
        .single();

    return HelpRequest.fromJson(row, currentUserId: learnerId);
  }

  /// Mentor accepts a request.
  static Future<void> acceptRequest(
      String requestId, String mentorId) async {
    await _db.from('help_requests').update({
      'status': 'accepted',
      'mentor_id': mentorId,
    }).eq('id', requestId);
  }

  /// Mark a request as completed.
  static Future<void> completeRequest(String requestId) async {
    await _db
        .from('help_requests')
        .update({'status': 'completed'})
        .eq('id', requestId);
  }

  /// Learner cancels their own request.
  static Future<void> cancelRequest(String requestId) async {
    await _db
        .from('help_requests')
        .update({'status': 'cancelled'})
        .eq('id', requestId);
  }
}
