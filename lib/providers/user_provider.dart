import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class UserProvider extends ChangeNotifier {
  UserModel _user = UserModel();
  bool _onboardingComplete = false;

  UserModel get user => _user;
  bool get onboardingComplete => _onboardingComplete;

  Future<void> loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    _onboardingComplete = prefs.getBool('onboarding_complete') ?? false;
    if (_onboardingComplete) {
      _user = UserModel(
        name: prefs.getString('user_name') ?? 'Student',
        college: 'BMS College of Engineering',
        semester: prefs.getInt('user_semester') ?? 1,
        topicsOfInterest: prefs.getStringList('user_topics') ?? [],
        isMentor: prefs.getBool('user_is_mentor') ?? false,
        mentorPoints: prefs.getInt('user_mentor_points') ?? 0,
        mentorTopics: prefs.getStringList('user_mentor_topics') ?? [],
      );
    }
    notifyListeners();
  }

  Future<void> completeOnboarding({
    required String name,
    required int semester,
    required List<String> topics,
  }) async {
    _user = UserModel(
      name: name,
      college: 'BMS College of Engineering',
      semester: semester,
      topicsOfInterest: topics,
    );
    _onboardingComplete = true;
    await _saveUser();
    notifyListeners();
  }

  void toggleRole() {
    _user = _user.copyWith(isMentor: !_user.isMentor);
    _saveUser();
    notifyListeners();
  }

  void addMentorPoints(int points) {
    _user = _user.copyWith(mentorPoints: _user.mentorPoints + points);
    _saveUser();
    notifyListeners();
  }

  void updateMentorTopics(List<String> topics) {
    _user = _user.copyWith(mentorTopics: topics);
    _saveUser();
    notifyListeners();
  }

  void updateProfile({String? name, int? semester}) {
    _user = _user.copyWith(
      name: name,
      semester: semester,
    );
    _saveUser();
    notifyListeners();
  }

  Future<void> _saveUser() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('onboarding_complete', _onboardingComplete);
    prefs.setString('user_name', _user.name);
    prefs.setString('user_college', _user.college);
    prefs.setInt('user_semester', _user.semester);
    prefs.setStringList('user_topics', _user.topicsOfInterest);
    prefs.setBool('user_is_mentor', _user.isMentor);
    prefs.setInt('user_mentor_points', _user.mentorPoints);
    prefs.setStringList('user_mentor_topics', _user.mentorTopics);
  }
}
