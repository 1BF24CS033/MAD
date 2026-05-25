import 'package:flutter/material.dart';
import '../services/profile_service.dart';

class MentorProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _mentors = [];
  bool _loading = false;

  List<Map<String, dynamic>> get mentors => _mentors;
  bool get loading => _loading;

  Future<void> loadMentors({
    String? searchQuery,
    int? semester,
    String? topic,
  }) async {
    _loading = true;
    notifyListeners();

    try {
      _mentors = await ProfileService.fetchMentors(
        searchQuery: searchQuery,
        semester: semester,
        topic: topic,
      );
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
