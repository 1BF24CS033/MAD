import 'package:flutter/material.dart';
import '../models/help_request.dart';
import '../services/google_meet_service.dart';
import '../services/help_request_service.dart';
import '../services/supabase_service.dart';

class HelpRequestProvider extends ChangeNotifier {
  // Open help requests visible to mentors
  List<HelpRequest> _openRequests = [];
  // Requests posted by the current learner
  List<HelpRequest> _myRequests = [];
  // Open group studies
  List<HelpRequest> _openGroupStudies = [];
  bool _loading = false;
  String _topicFilter = '';

  List<HelpRequest> get openRequests => _openRequests;
  List<HelpRequest> get myRequests => _myRequests;
  List<HelpRequest> get openGroupStudies => _openGroupStudies;
  bool get loading => _loading;
  String get topicFilter => _topicFilter;

  // Convenience getters
  List<HelpRequest> get myHelpRequests =>
      _myRequests.where((r) => r.isHelp).toList();
  List<HelpRequest> get myGroupStudies =>
      _myRequests.where((r) => r.isGroupStudy).toList();

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
        HelpRequestService.fetchOpenGroupStudies(topic: _topicFilter.isEmpty ? null : _topicFilter),
      ]);
      _openRequests = results[0];
      _myRequests = results[1];
      _openGroupStudies = results[2];
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
    bool wantsMeet = false,
  }) async {
    final userId = SupabaseService.currentUserId!;
    final req = await HelpRequestService.postRequest(
      learnerId: userId,
      topic: topic,
      description: description,
      durationMinutes: durationMinutes,
      wantsMeet: wantsMeet,
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

  /// Learner shares their email with the mentor.
  Future<void> shareEmail(String requestId) async {
    await HelpRequestService.shareEmail(requestId);
    final index = _myRequests.indexWhere((r) => r.id == requestId);
    if (index != -1) {
      final old = _myRequests[index];
      _myRequests[index] = HelpRequest(
        id: old.id,
        learnerId: old.learnerId,
        learnerName: old.learnerName,
        learnerSemester: old.learnerSemester,
        learnerEmail: old.learnerEmail,
        topic: old.topic,
        description: old.description,
        durationMinutes: old.durationMinutes,
        status: old.status,
        type: old.type,
        mentorId: old.mentorId,
        mentorName: old.mentorName,
        mentorEmail: old.mentorEmail,
        emailShared: true,
        wantsMeet: old.wantsMeet,
        meetLink: old.meetLink,
        maxParticipants: old.maxParticipants,
        currentParticipants: old.currentParticipants,
        createdAt: old.createdAt,
      );
      notifyListeners();
    }
  }

  /// Learner confirms completion (after mentor marks pending_review).
  Future<void> confirmComplete(String requestId) async {
    await HelpRequestService.completeRequest(requestId);
    _updateStatus(requestId, 'completed', inMyRequests: true);
    notifyListeners();
  }

  // ── Mentor actions ──────────────────────────────────────────────────────────

  /// Accepts a help request. If the learner opted for Google Meet,
  /// a Meet link is auto-generated and saved to the database.
  ///
  /// Returns the generated Meet link, or null.
  Future<String?> acceptRequest(String requestId) async {
    final mentorId = SupabaseService.currentUserId!;

    // Find the request before removing it so we can check wantsMeet
    final request = _openRequests.firstWhere(
      (r) => r.id == requestId,
      orElse: () => HelpRequest(
        id: requestId,
        learnerId: '',
        learnerName: '',
        topic: '',
        description: '',
        createdAt: DateTime.now(),
      ),
    );

    await HelpRequestService.acceptRequest(requestId, mentorId);

    // Auto-generate Meet link if the learner requested it
    String? meetLink;
    if (request.wantsMeet) {
      try {
        final attendees = <String>[];
        if (request.learnerEmail != null) {
          attendees.add(request.learnerEmail!);
        }
        meetLink = await GoogleMeetService.createMeetLink(
          topic: request.topic,
          durationMinutes: request.durationMinutes,
          attendeeEmails: attendees,
        );
        if (meetLink != null) {
          await HelpRequestService.saveMeetLink(requestId, meetLink);
        }
      } catch (_) {
        // Meet creation failed — request is still accepted.
        // The mentor can manually share a link later.
      }
    }

    // Remove from open list (it's no longer open)
    _openRequests.removeWhere((r) => r.id == requestId);
    notifyListeners();
    return meetLink;
  }

  /// Mentor marks the request as done → goes to pending_review.
  Future<void> markPendingReview(String requestId) async {
    await HelpRequestService.markPendingReview(requestId);
    _updateStatus(requestId, 'pending_review', inMyRequests: false);
    notifyListeners();
  }

  Future<void> completeRequest(String requestId) async {
    await HelpRequestService.completeRequest(requestId);
    _updateStatus(requestId, 'completed', inMyRequests: true);
    notifyListeners();
  }

  // ── Group Study actions ─────────────────────────────────────────────────────

  Future<HelpRequest> postGroupStudy({
    required String topic,
    required String description,
    required int maxParticipants,
  }) async {
    final userId = SupabaseService.currentUserId!;
    final req = await HelpRequestService.postGroupStudy(
      learnerId: userId,
      topic: topic,
      description: description,
      maxParticipants: maxParticipants,
    );
    _myRequests.insert(0, req);
    notifyListeners();
    return req;
  }

  Future<void> joinGroupStudy(String requestId) async {
    final userId = SupabaseService.currentUserId!;
    await HelpRequestService.joinGroupStudy(requestId, userId);
    // Update local count
    final index = _openGroupStudies.indexWhere((r) => r.id == requestId);
    if (index != -1) {
      final old = _openGroupStudies[index];
      _openGroupStudies[index] = HelpRequest(
        id: old.id,
        learnerId: old.learnerId,
        learnerName: old.learnerName,
        learnerSemester: old.learnerSemester,
        topic: old.topic,
        description: old.description,
        durationMinutes: old.durationMinutes,
        status: old.status,
        type: old.type,
        maxParticipants: old.maxParticipants,
        currentParticipants: old.currentParticipants + 1,
        createdAt: old.createdAt,
      );
    }
    notifyListeners();
  }

  Future<void> leaveGroupStudy(String requestId) async {
    final userId = SupabaseService.currentUserId!;
    await HelpRequestService.leaveGroupStudy(requestId, userId);
    await loadData(); // Reload to get fresh counts
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
        learnerSemester: old.learnerSemester,
        learnerEmail: old.learnerEmail,
        topic: old.topic,
        description: old.description,
        durationMinutes: old.durationMinutes,
        status: status,
        type: old.type,
        mentorId: old.mentorId,
        mentorName: old.mentorName,
        mentorEmail: old.mentorEmail,
        emailShared: old.emailShared,
        wantsMeet: old.wantsMeet,
        meetLink: old.meetLink,
        maxParticipants: old.maxParticipants,
        currentParticipants: old.currentParticipants,
        createdAt: old.createdAt,
      );
    }
  }
}
