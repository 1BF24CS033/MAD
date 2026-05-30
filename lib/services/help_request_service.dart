import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/help_request.dart';
import 'supabase_service.dart';

class HelpRequestService {
  static SupabaseClient get _db => SupabaseService.client;

  static const _select = '''
    *,
    learner:profiles!help_requests_learner_id_fkey(name, semester, email),
    mentor:profiles!help_requests_mentor_id_fkey(name, email)
  ''';

  /// All open help requests (for mentors to browse).
  static Future<List<HelpRequest>> fetchOpenRequests(
      {String? topic}) async {
    final currentUserId = SupabaseService.currentUserId ?? '';
    var query = _db
        .from('help_requests')
        .select(_select)
        .eq('status', 'open')
        .eq('type', 'help')
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

  /// Requests accepted by the current mentor (active sessions).
  static Future<List<HelpRequest>> fetchMyAcceptedRequests(
      String mentorId) async {
    final rows = await _db
        .from('help_requests')
        .select(_select)
        .eq('mentor_id', mentorId)
        .inFilter('status', ['accepted', 'pending_review'])
        .order('created_at', ascending: false);

    return rows
        .cast<Map<String, dynamic>>()
        .map((r) => HelpRequest.fromJson(r, currentUserId: mentorId))
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
    bool wantsMeet = false,
  }) async {
    final row = await _db
        .from('help_requests')
        .insert({
          'learner_id': learnerId,
          'topic': topic,
          'description': description,
          'duration_minutes': durationMinutes,
          'status': 'open',
          'type': 'help',
          'wants_meet': wantsMeet,
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

  /// Mentor marks the request as pending learner review.
  static Future<void> markPendingReview(String requestId) async {
    await _db
        .from('help_requests')
        .update({'status': 'pending_review'})
        .eq('id', requestId);
  }

  /// Learner confirms completion.
  static Future<void> completeRequest(String requestId) async {
    await _db
        .from('help_requests')
        .update({'status': 'completed'})
        .eq('id', requestId);
  }

  /// Learner opts in to share their email.
  static Future<void> shareEmail(String requestId) async {
    await _db
        .from('help_requests')
        .update({'email_shared': true})
        .eq('id', requestId);
  }

  /// Save a Meet link for a request.
  static Future<void> saveMeetLink(
      String requestId, String meetLink) async {
    await _db
        .from('help_requests')
        .update({'meet_link': meetLink})
        .eq('id', requestId);
  }

  /// Learner cancels their own request.
  static Future<void> cancelRequest(String requestId) async {
    await _db
        .from('help_requests')
        .update({'status': 'cancelled'})
        .eq('id', requestId);
  }

  // ── Group Study ──────────────────────────────────────────────────────────

  /// All open group studies.
  static Future<List<HelpRequest>> fetchOpenGroupStudies(
      {String? topic}) async {
    final currentUserId = SupabaseService.currentUserId ?? '';
    var query = _db
        .from('help_requests')
        .select(_select)
        .eq('status', 'open')
        .eq('type', 'group_study')
        .order('created_at', ascending: false);

    final rows = await query;
    // Fetch member counts
    final List<HelpRequest> results = [];
    for (final r in rows.cast<Map<String, dynamic>>()) {
      if (topic != null && topic.isNotEmpty) {
        final t = (r['topic'] as String).toLowerCase();
        if (!t.contains(topic.toLowerCase())) continue;
      }
      // Get current member count
      final membersResp = await _db
          .from('group_study_members')
          .select('user_id')
          .eq('request_id', r['id'] as String);
      r['member_count'] = (membersResp as List).length;
      results.add(HelpRequest.fromJson(r, currentUserId: currentUserId));
    }
    return results;
  }

  /// Post a new group study.
  static Future<HelpRequest> postGroupStudy({
    required String learnerId,
    required String topic,
    required String description,
    required int maxParticipants,
  }) async {
    final row = await _db
        .from('help_requests')
        .insert({
          'learner_id': learnerId,
          'topic': topic,
          'description': description,
          'duration_minutes': 60,
          'status': 'open',
          'type': 'group_study',
          'max_participants': maxParticipants,
        })
        .select(_select)
        .single();

    // Creator auto-joins
    await _db.from('group_study_members').insert({
      'request_id': row['id'] as String,
      'user_id': learnerId,
    });

    row['member_count'] = 1;
    return HelpRequest.fromJson(row, currentUserId: learnerId);
  }

  /// Join a group study.
  static Future<void> joinGroupStudy(
      String requestId, String userId) async {
    await _db.rpc('join_group_study',
        params: {'p_request_id': requestId, 'p_user_id': userId});
  }

  /// Leave a group study.
  static Future<void> leaveGroupStudy(
      String requestId, String userId) async {
    await _db
        .from('group_study_members')
        .delete()
        .eq('request_id', requestId)
        .eq('user_id', userId);
  }

  /// Fetch members of a group study (with profile info).
  static Future<List<Map<String, dynamic>>> fetchGroupMembers(
      String requestId) async {
    final rows = await _db
        .from('group_study_members')
        .select('user_id, joined_at, profile:profiles!group_study_members_user_id_fkey(name, email, semester)')
        .eq('request_id', requestId)
        .order('joined_at');

    return rows.cast<Map<String, dynamic>>();
  }

  /// Check if the current user has joined a group study.
  static Future<bool> hasJoinedGroupStudy(
      String requestId, String userId) async {
    final rows = await _db
        .from('group_study_members')
        .select('user_id')
        .eq('request_id', requestId)
        .eq('user_id', userId);
    return (rows as List).isNotEmpty;
  }
}
