import 'package:flutter/material.dart';
import '../models/help_request.dart';
import '../services/help_request_service.dart';
import '../services/supabase_service.dart';

class HelpRequestProvider extends ChangeNotifier {
  // Open requests visible to mentors
  List<HelpRequest> _openRequests = [];
  // Requests posted by the current learner
  List<HelpRequest> _myRequests = [];
  bool _loading = false;
  String _topicFilter = '';

  List<HelpRequest> get openRequests => _openRequests;
  List<HelpRequest> get myRequests => _myRequests;
  bool get loading => _loading;
  String get topicFilter => _topicFilter;

  // ── Load ────────────────────────────────────────────────────────────────────

  Future<void> loadData() async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) return;

    _loading = true;
    notifyListeners();

    try {
      final results = await Future.wait([
        HelpRequestService.fetchOpenRequests(topic: _topicFilter.isEmpty ? null : _topicFilter),
        HelpRequestService.fetchMyRequests(userId),
      ]);
      _openRequests = results[0] as List<HelpRequest>;
      _myRequests = results[1] as List<HelpRequest>;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void setFilter(String topic) {
    _topicFilter = topic;
    loadData();
  }

  void clearFilter() {
    _topicFilter = '';
    loadData();
  }

  // ── Learner actions ─────────────────────────────────────────────────────────

  Future<HelpRequest> postRequest({
    required String topic,
    required String description,
    required int durationMinutes,
  }) async {
    final userId = SupabaseService.currentUserId!;
    final req = await HelpRequestService.postRequest(
      learnerId: userId,
      topic: topic,
      description: description,
      durationMinutes: durationMinutes,
    );
    _myRequests.insert(0, req);
    notifyListeners();
    return req;
  }

  Future<void> cancelRequest(String requestId) async {
    await HelpRequestService.cancelRequest(requestId);
    _updateStatus(requestId, 'cancelled', inMyRequests: true);
    _openRequests.removeWhere((r) => r.id == requestId);
    notifyListeners();
  }

  // ── Mentor actions ──────────────────────────────────────────────────────────

  Future<void> acceptRequest(String requestId) async {
    final mentorId = SupabaseService.currentUserId!;
    await HelpRequestService.acceptRequest(requestId, mentorId);
    // Remove from open list (it's no longer open)
    _openRequests.removeWhere((r) => r.id == requestId);
    notifyListeners();
  }

  Future<void> completeRequest(String requestId) async {
    await HelpRequestService.completeRequest(requestId);
    _updateStatus(requestId, 'completed', inMyRequests: true);
    notifyListeners();
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  void _updateStatus(String id, String status,
      {bool inMyRequests = false}) {
    final list = inMyRequests ? _myRequests : _openRequests;
    final index = list.indexWhere((r) => r.id == id);
    if (index != -1) {
      final old = list[index];
      list[index] = HelpRequest(
        id: old.id,
        learnerId: old.learnerId,
        learnerName: old.learnerName,
        topic: old.topic,
        description: old.description,
        durationMinutes: old.durationMinutes,
        status: status,
        mentorId: old.mentorId,
        mentorName: old.mentorName,
        createdAt: old.createdAt,
      );
    }
  }
}
