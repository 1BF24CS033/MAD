import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/peer_work_session.dart';
import 'supabase_service.dart';

class SessionService {
  static SupabaseClient get _db => SupabaseService.client;

  static const _sessionSelect = '''
    *,
    mentor:profiles!peer_work_sessions_mentor_id_fkey(name),
    learner:profiles!peer_work_sessions_learner_id_fkey(name)
  ''';

  // ── Fetch ───────────────────────────────────────────────────────────────────

  static Future<List<PeerWorkSession>> fetchSessions(
      String currentUserId) async {
    final rows = await _db
        .from('peer_work_sessions')
        .select(_sessionSelect)
        .or('mentor_id.eq.$currentUserId,learner_id.eq.$currentUserId')
        .order('date', ascending: false);

    return rows
        .cast<Map<String, dynamic>>()
        .map((r) => PeerWorkSession.fromJson(r, currentUserId: currentUserId))
        .toList();
  }

  // ── Create ──────────────────────────────────────────────────────────────────

  /// Learner requests a session with a mentor.
  static Future<PeerWorkSession> requestSession({
    required String mentorId,
    required String learnerId,
    required String topic,
    required int durationMinutes,
  }) async {
    final row = await _db
        .from('peer_work_sessions')
        .insert({
          'mentor_id': mentorId,
          'learner_id': learnerId,
          'topic': topic,
          'duration_minutes': durationMinutes,
          'status': 'pending',
          'date': DateTime.now().toIso8601String(),
        })
        .select(_sessionSelect)
        .single();

    return PeerWorkSession.fromJson(row, currentUserId: learnerId);
  }

  // ── Update status ───────────────────────────────────────────────────────────

  /// Mentor accepts a pending session request.
  static Future<void> acceptSession(String sessionId) async {
    await _db
        .from('peer_work_sessions')
        .update({'status': 'accepted'})
        .eq('id', sessionId);
  }

  /// Mentor declines a pending session request.
  static Future<void> declineSession(String sessionId) async {
    await _db
        .from('peer_work_sessions')
        .update({'status': 'declined'})
        .eq('id', sessionId);
  }

  /// Mark a session as completed and award points.
  static Future<void> completeSession(
      String sessionId, int pointsAwarded) async {
    await _db.from('peer_work_sessions').update({
      'completed': true,
      'status': 'completed',
      'points_awarded': pointsAwarded,
    }).eq('id', sessionId);
  }

  // Study History

  static Future<List<String>> fetchStudyHistory(String userId) async {
    final rows = await _db
        .from('study_history')
        .select('topic')
        .eq('user_id', userId)
        .order('studied_at', ascending: false)
        .limit(50);

    return rows
        .cast<Map<String, dynamic>>()
        .map((r) => r['topic'] as String)
        .toList();
  }

  static Future<void> addStudyTopic(String userId, String topic) async {
    await _db.from('study_history').insert({
      'user_id': userId,
      'topic': topic,
    });
  }
}
