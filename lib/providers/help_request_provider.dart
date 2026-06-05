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
  // Requests accepted by the current mentor
  List<HelpRequest> _myAcceptedRequests = [];
  // Open group studies
  List<HelpRequest> _openGroupStudies = [];
  bool _loading = false;
  String _topicFilter = '';

  List<HelpRequest> get openRequests => _openRequests;
  List<HelpRequest> get myRequests => _myRequests;
  List<HelpRequest> get myAcceptedRequests => _myAcceptedRequests;
  List<HelpRequest> get openGroupStudies => _openGroupStudies;
  bool get loading => _loading;
  String get topicFilter => _topicFilter;

  // Convenience getters
  List<HelpRequest> get myHelpRequests =>
      _myRequests.where((r) => r.isHelp).toList();
  List<HelpRequest> get myGroupStudies =>
      _myRequests.where((r) => r.isGroupStudy).toList();

  // Load 

  Future<void> loadData() async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) return;

    _loading = true;
    notifyListeners();

    try {
      final results = await Future.wait([
        HelpRequestService.fetchOpenRequests(topic: _topicFilter.isEmpty ? null : _topicFilter),
        HelpRequestService.fetchMyRequests(userId),
        HelpRequestService.fetchMyAcceptedRequests(userId),
        HelpRequestService.fetchOpenGroupStudies(topic: _topicFilter.isEmpty ? null : _topicFilter),
      ]);
      _openRequests = results[0];
      _myRequests = results[1];
      _myAcceptedRequests = results[2];
      _openGroupStudies = results[3];
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

  // Learner actions 

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

  // Mentor actions 

  Future<void> acceptRequest(String requestId) async {
    final mentorId = SupabaseService.currentUserId!;

    // Find the request before removing it
    final req = _openRequests.firstWhere(
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

    // Write to DB first — if this fails, throw so UI can show error
    await HelpRequestService.acceptRequest(requestId, mentorId);

    // Update local state only after successful DB write
    _openRequests.removeWhere((r) => r.id == requestId);
    if (req.learnerId.isNotEmpty) {
      final accepted = _copyWith(req, 'accepted');
      _myAcceptedRequests.insert(0, accepted);
    }
    notifyListeners();
  }

  /// Separately schedule a Google Meet for an already-accepted request.
  Future<String?> scheduleMeet(String requestId) async {
    final req = _myAcceptedRequests.firstWhere(
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
    try {
      final attendees = <String>[];
      if (req.learnerEmail != null) attendees.add(req.learnerEmail!);
      final meetLink = await GoogleMeetService.createMeetLink(
        topic: req.topic,
        durationMinutes: req.durationMinutes,
        attendeeEmails: attendees,
      );
      if (meetLink != null) {
        await HelpRequestService.saveMeetLink(requestId, meetLink);
        // Update local state with the meet link
        final i = _myAcceptedRequests.indexWhere((r) => r.id == requestId);
        if (i != -1) {
          final old = _myAcceptedRequests[i];
          _myAcceptedRequests[i] = HelpRequest(
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
            emailShared: old.emailShared,
            wantsMeet: old.wantsMeet,
            meetLink: meetLink,
            maxParticipants: old.maxParticipants,
            currentParticipants: old.currentParticipants,
            createdAt: old.createdAt,
          );
          notifyListeners();
        }
      }
      return meetLink;
    } catch (e) {
      rethrow;
    }
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

  // Group Study actions 

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

  // Helpers 

  void _updateStatus(String id, String status,
      {bool inMyRequests = false}) {
    final list = inMyRequests ? _myRequests : _openRequests;
    final index = list.indexWhere((r) => r.id == id);
    if (index != -1) {
      final old = list[index];
      list[index] = _copyWith(old, status);
    }
    // Also update myAcceptedRequests if present there
    final ai = _myAcceptedRequests.indexWhere((r) => r.id == id);
    if (ai != -1) {
      _myAcceptedRequests[ai] = _copyWith(_myAcceptedRequests[ai], status);
    }
  }

  HelpRequest _copyWith(HelpRequest old, String status) {
    return HelpRequest(
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
