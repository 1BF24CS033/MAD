import 'package:flutter/material.dart';
import '../models/peer_work_session.dart';
import '../services/session_service.dart';
import '../services/supabase_service.dart';

class SessionProvider extends ChangeNotifier {
  List<PeerWorkSession> _sessions = [];
  List<String> _studyHistory = [];
  bool _loading = false;

  List<PeerWorkSession> get sessions => _sessions;
  List<String> get studyHistory => _studyHistory;
  bool get loading => _loading;

  /// Sessions where the current user is the mentor and status is pending.
  List<PeerWorkSession> get pendingRequests => _sessions
      .where((s) => s.mentorName == 'You' && s.isPending)
      .toList();

  /// Sessions where the current user is the mentor and status is accepted.
  List<PeerWorkSession> get acceptedMentorSessions => _sessions
      .where((s) => s.mentorName == 'You' && s.isAccepted)
      .toList();

  /// Sessions where the current user is the learner.
  List<PeerWorkSession> get learnerSessions =>
      _sessions.where((s) => s.learnerName == 'You').toList();

  /// All non-declined sessions for display.
  List<PeerWorkSession> get activeSessions =>
      _sessions.where((s) => s.status != 'declined').toList();

  // Load 

  Future<void> loadData() async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) return;

    _loading = true;
    notifyListeners();

    try {
      final results = await Future.wait([
        SessionService.fetchSessions(userId),
        SessionService.fetchStudyHistory(userId),
      ]);
      _sessions = results[0] as List<PeerWorkSession>;
      _studyHistory = results[1] as List<String>;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // Request 

  /// Learner sends a session request to a mentor.
  Future<void> requestSession({
    required String mentorId,
    required String topic,
    required int durationMinutes,
  }) async {
    final learnerId = SupabaseService.currentUserId;
    if (learnerId == null) return;

    final session = await SessionService.requestSession(
      mentorId: mentorId,
      learnerId: learnerId,
      topic: topic,
      durationMinutes: durationMinutes,
    );
    _sessions.insert(0, session);
    notifyListeners();
  }

  // Accept / Decline 

  Future<void> acceptSession(String sessionId) async {
    await SessionService.acceptSession(sessionId);
    _updateStatus(sessionId, 'accepted');
  }

  Future<void> declineSession(String sessionId) async {
    await SessionService.declineSession(sessionId);
    _updateStatus(sessionId, 'declined');
  }

  // Complete 

  Future<void> completeSession(String sessionId, int pointsAwarded) async {
    await SessionService.completeSession(sessionId, pointsAwarded);

    final index = _sessions.indexWhere((s) => s.id == sessionId);
    if (index != -1) {
      final old = _sessions[index];
      _sessions[index] = PeerWorkSession(
        id: old.id,
        topic: old.topic,
        mentorName: old.mentorName,
        learnerName: old.learnerName,
        mentorId: old.mentorId,
        learnerId: old.learnerId,
        date: old.date,
        durationMinutes: old.durationMinutes,
        pointsAwarded: pointsAwarded,
        completed: true,
        status: 'completed',
      );
      notifyListeners();
    }
  }

  // Study History 

  Future<void> addStudyTopic(String topic) async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) return;
    _studyHistory.insert(0, topic);
    notifyListeners();
    await SessionService.addStudyTopic(userId, topic);
  }

  // Helpers 

  void _updateStatus(String sessionId, String newStatus) {
    final index = _sessions.indexWhere((s) => s.id == sessionId);
    if (index != -1) {
      final old = _sessions[index];
      _sessions[index] = PeerWorkSession(
        id: old.id,
        topic: old.topic,
        mentorName: old.mentorName,
        learnerName: old.learnerName,
        mentorId: old.mentorId,
        learnerId: old.learnerId,
        date: old.date,
        durationMinutes: old.durationMinutes,
        pointsAwarded: old.pointsAwarded,
        completed: old.completed,
        status: newStatus,
      );
      notifyListeners();
    }
  }
}
