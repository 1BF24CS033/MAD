import 'package:flutter/material.dart';
import '../models/peer_work_session.dart';
import '../utils/dummy_data.dart';

class SessionProvider extends ChangeNotifier {
  List<PeerWorkSession> _sessions = [];
  List<String> _studyHistory = [];

  List<PeerWorkSession> get sessions => _sessions;
  List<PeerWorkSession> get mentorSessions =>
      _sessions.where((s) => s.mentorName == 'You').toList();
  List<PeerWorkSession> get learnerSessions =>
      _sessions.where((s) => s.learnerName == 'You').toList();
  List<String> get studyHistory => _studyHistory;

  void loadDummyData() {
    _sessions = List.from(DummyData.sampleSessions);
    _studyHistory = List.from(DummyData.studyHistory);
    notifyListeners();
  }

  void addSession(PeerWorkSession session) {
    _sessions.insert(0, session);
    notifyListeners();
  }

  void completeSession(String sessionId, int pointsAwarded) {
    final index = _sessions.indexWhere((s) => s.id == sessionId);
    if (index != -1) {
      final old = _sessions[index];
      _sessions[index] = PeerWorkSession(
        id: old.id,
        topic: old.topic,
        mentorName: old.mentorName,
        learnerName: old.learnerName,
        date: old.date,
        durationMinutes: old.durationMinutes,
        pointsAwarded: pointsAwarded,
        completed: true,
      );
      notifyListeners();
    }
  }

  void addStudyTopic(String topic) {
    _studyHistory.insert(0, topic);
    notifyListeners();
  }
}
