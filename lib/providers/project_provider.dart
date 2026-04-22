import 'package:flutter/material.dart';
import '../models/project_model.dart';
import '../utils/dummy_data.dart';

class ProjectProvider extends ChangeNotifier {
  List<ProjectModel> _projects = [];
  String _filterTopic = '';

  List<ProjectModel> get projects {
    if (_filterTopic.isEmpty) return _projects;
    return _projects
        .where((p) => p.skillsRequired
            .any((s) => s.toLowerCase().contains(_filterTopic.toLowerCase())))
        .toList();
  }

  List<ProjectModel> get allProjects => _projects;
  String get filterTopic => _filterTopic;

  void loadDummyData() {
    _projects = List.from(DummyData.sampleProjects);
    notifyListeners();
  }

  void addProject(ProjectModel project) {
    _projects.insert(0, project);
    notifyListeners();
  }

  void setFilter(String topic) {
    _filterTopic = topic;
    notifyListeners();
  }

  void clearFilter() {
    _filterTopic = '';
    notifyListeners();
  }
}
