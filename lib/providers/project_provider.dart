import 'package:flutter/material.dart';
import '../models/project_model.dart';
import '../services/project_service.dart';
import '../services/supabase_service.dart';

class ProjectProvider extends ChangeNotifier {
  List<ProjectModel> _projects = [];
  String _filterTopic = '';
  bool _loading = false;

  bool get loading => _loading;
  String get filterTopic => _filterTopic;

  List<ProjectModel> get allProjects => _projects;

  List<ProjectModel> get projects {
    if (_filterTopic.isEmpty) return _projects;
    return _projects
        .where((p) => p.skillsRequired
            .any((s) => s.toLowerCase().contains(_filterTopic.toLowerCase())))
        .toList();
  }

  // ── Load ────────────────────────────────────────────────────────────────────

  Future<void> loadData() async {
    _loading = true;
    notifyListeners();

    try {
      _projects = await ProjectService.fetchProjects();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // ── Mutations ───────────────────────────────────────────────────────────────

  Future<void> addProject(ProjectModel project) async {
    final created = await ProjectService.createProject(project);
    _projects.insert(0, created);
    notifyListeners();
  }

  Future<void> joinProject(String projectId) async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) return;

    await ProjectService.joinProject(projectId, userId);

    // Update local state
    final index = _projects.indexWhere((p) => p.id == projectId);
    if (index != -1) {
      final old = _projects[index];
      _projects[index] = ProjectModel(
        id: old.id,
        title: old.title,
        description: old.description,
        postedBy: old.postedBy,
        postedById: old.postedById,
        skillsRequired: old.skillsRequired,
        teamSize: old.teamSize,
        currentMembers: old.currentMembers + 1,
        postedDate: old.postedDate,
        isOpen: old.currentMembers + 1 < old.teamSize,
      );
      notifyListeners();
    }
  }

  // ── Filters ─────────────────────────────────────────────────────────────────

  void setFilter(String topic) {
    _filterTopic = topic;
    notifyListeners();
  }

  void clearFilter() {
    _filterTopic = '';
    notifyListeners();
  }
}
