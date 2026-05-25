import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../services/profile_service.dart';
import '../services/supabase_service.dart';

class UserProvider extends ChangeNotifier {
  UserModel _user = UserModel();
  bool _loading = false;
  bool _initializing = true; // true only during the startup auth check
  String? _error;

  UserModel get user => _user;
  bool get loading => _loading;
  bool get initializing => _initializing;
  String? get error => _error;
  bool get onboardingComplete => _user.onboardingComplete;

  // ── Auth helpers ────────────────────────────────────────────────────────────

  /// Sign up with email + password, then complete onboarding in one step.
  Future<void> signUp({
    required String email,
    required String password,
    required String name,
    required int semester,
    required List<String> topics,
  }) async {
    _setLoading(true);
    try {
      final response = await SupabaseService.client.auth
          .signUp(email: email, password: password);

      final userId = response.user?.id;
      if (userId == null) throw Exception('Sign-up failed – no user returned');

      _user = UserModel(
        id: userId,
        name: name,
        semester: semester,
        topicsOfInterest: topics,
        onboardingComplete: true,
      );

      await ProfileService.upsertProfile(_user);
      _clearError();
    } on AuthException catch (e) {
      _setError(e.message);
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Sign in with email + password and load the user's profile.
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    try {
      await SupabaseService.client.auth
          .signInWithPassword(email: email, password: password);
      await loadUser();
      _clearError();
    } on AuthException catch (e) {
      _setError(e.message);
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Sign out the current user.
  Future<void> signOut() async {
    await SupabaseService.client.auth.signOut();
    _user = UserModel();
    notifyListeners();
  }

  // ── Profile ─────────────────────────────────────────────────────────────────

  /// Load the profile for the currently authenticated user.
  Future<void> loadUser() async {
    final userId = SupabaseService.currentUserId;
    _initializing = false; // startup check is done regardless of result
    if (userId == null) {
      notifyListeners();
      return;
    }

    _setLoading(true);
    try {
      final profile = await ProfileService.fetchProfile(userId);
      if (profile != null) {
        _user = profile;
      } else {
        _user = UserModel(id: userId);
      }
      _clearError();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  /// Complete onboarding for an already-authenticated user.
  Future<void> completeOnboarding({
    required String name,
    required int semester,
    required List<String> topics,
  }) async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) return;

    _user = _user.copyWith(
      id: userId,
      name: name,
      semester: semester,
      topicsOfInterest: topics,
      onboardingComplete: true,
    );

    await ProfileService.upsertProfile(_user);
    notifyListeners();
  }

  Future<void> toggleRole() async {
    _user = _user.copyWith(isMentor: !_user.isMentor);
    notifyListeners();
    await ProfileService.updateProfile(_user.id, {'is_mentor': _user.isMentor});

    // Ensure a mentors row exists when opting in
    if (_user.isMentor) {
      await ProfileService.optInAsMentor(_user.id);
    }
  }

  Future<void> addMentorPoints(int points) async {
    _user = _user.copyWith(mentorPoints: _user.mentorPoints + points);
    notifyListeners();
    await ProfileService.addMentorPoints(_user.id, points);
  }

  Future<void> updateMentorTopics(List<String> topics) async {
    _user = _user.copyWith(mentorTopics: topics);
    notifyListeners();
    await ProfileService.updateProfile(_user.id, {'mentor_topics': topics});
  }

  Future<void> updateProfile({String? name, int? semester}) async {
    _user = _user.copyWith(name: name, semester: semester);
    notifyListeners();
    await ProfileService.updateProfile(_user.id, {
      if (name != null) 'name': name,
      if (semester != null) 'semester': semester,
    });
  }

  /// Reload mentor_points from the database (e.g. after a reward redemption).
  Future<void> refreshPoints() async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) return;
    final profile = await ProfileService.fetchProfile(userId);
    if (profile != null) {
      _user = _user.copyWith(mentorPoints: profile.mentorPoints);
      notifyListeners();
    }
  }

  // ── Private helpers ─────────────────────────────────────────────────────────

  void _setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }

  void _setError(String msg) {
    _error = msg;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }
}
