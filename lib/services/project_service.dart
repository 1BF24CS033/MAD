import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/project_model.dart';
import 'supabase_service.dart';

/// Handles all database operations for [projects] and [project_members].
class ProjectService {
  static SupabaseClient get _db => SupabaseService.client;

  /// Fetch all open projects, optionally filtered by a skill topic.
  static Future<List<ProjectModel>> fetchProjects({String? topic}) async {
    var query = _db
        .from('projects')
        .select('*, profiles!projects_posted_by_fkey(name)')
        .eq('is_open', true)
        .order('posted_date', ascending: false);

    final List<dynamic> rows = await query;

    return rows
        .cast<Map<String, dynamic>>()
        .where((r) {
          if (topic == null || topic.isEmpty) return true;
          final skills = List<String>.from(r['skills_required'] ?? []);
          return skills
              .any((s) => s.toLowerCase().contains(topic.toLowerCase()));
        })
        .map(ProjectModel.fromJson)
        .toList();
  }

  /// Insert a new project and return the created record.
  static Future<ProjectModel> createProject(ProjectModel project) async {
    final row = await _db
        .from('projects')
        .insert(project.toJson())
        .select('*, profiles!projects_posted_by_fkey(name)')
        .single();

    return ProjectModel.fromJson(row);
  }

  /// Join a project: insert a project_members row and increment current_members.
  static Future<void> joinProject(
      String projectId, String userId) async {
    // Insert membership (will throw if already a member due to PK constraint)
    await _db.from('project_members').insert({
      'project_id': projectId,
      'user_id': userId,
    });

    // Increment current_members
    await _db.rpc('increment_project_members',
        params: {'project_id': projectId});
  }

  /// Check whether [userId] is already a member of [projectId].
  static Future<bool> isMember(String projectId, String userId) async {
    final row = await _db
        .from('project_members')
        .select('project_id')
        .eq('project_id', projectId)
        .eq('user_id', userId)
        .maybeSingle();

    return row != null;
  }
}
