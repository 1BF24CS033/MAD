import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import 'supabase_service.dart';

/// Handles all database operations for the [profiles] table.
class ProfileService {
  static SupabaseClient get _db => SupabaseService.client;

  /// Fetch the profile for [userId]. Returns null if not found.
  static Future<UserModel?> fetchProfile(String userId) async {
    final data = await _db
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (data == null) return null;
    return UserModel.fromJson(data);
  }

  /// Upsert (create or update) the profile for the current user.
  static Future<void> upsertProfile(UserModel user) async {
    await _db.from('profiles').upsert({
      'id': user.id,
      ...user.toJson(),
    });
  }

  /// Update only the fields that changed (partial update).
  static Future<void> updateProfile(
      String userId, Map<String, dynamic> fields) async {
    await _db.from('profiles').update(fields).eq('id', userId);
  }

  /// Increment mentor_points by [delta] for [userId].
  /// Uses a Postgres RPC to avoid race conditions.
  static Future<void> addMentorPoints(String userId, int delta) async {
    await _db.rpc('increment_mentor_points',
        params: {'user_id': userId, 'delta': delta});
  }

  /// Fetch all profiles that are mentors, with their mentor stats.
  /// Returns a list of maps ready for the MentorListScreen.
  static Future<List<Map<String, dynamic>>> fetchMentors({
    String? searchQuery,
    int? semester,
    String? topic,
  }) async {
    var query = _db
        .from('profiles')
        .select('''
          id, name, college, semester, mentor_topics, avatar_url,
          mentors!inner(rating, total_sessions)
        ''')
        .eq('is_mentor', true);

    if (semester != null) {
      query = query.eq('semester', semester);
    }

    final List<dynamic> rows = await query.order('name');

    // Apply in-memory filters for search and topic (Postgres array contains
    // is available but keeping it simple here)
    return rows
        .cast<Map<String, dynamic>>()
        .where((m) {
          final name = (m['name'] as String).toLowerCase();
          final topics = List<String>.from(m['mentor_topics'] ?? []);

          final matchesSearch = searchQuery == null ||
              searchQuery.isEmpty ||
              name.contains(searchQuery.toLowerCase()) ||
              topics.any((t) =>
                  t.toLowerCase().contains(searchQuery.toLowerCase()));

          final matchesTopic = topic == null ||
              topic.isEmpty ||
              topics.any(
                  (t) => t.toLowerCase().contains(topic.toLowerCase()));

          return matchesSearch && matchesTopic;
        })
        .map((m) {
          final mentorStats = m['mentors'] as Map<String, dynamic>? ?? {};
          return {
            'id': m['id'],
            'name': m['name'],
            'college': m['college'],
            'semester': m['semester'],
            'topics': List<String>.from(m['mentor_topics'] ?? []),
            'avatar_url': m['avatar_url'],
            'rating': (mentorStats['rating'] as num?)?.toDouble() ?? 5.0,
            'sessions': mentorStats['total_sessions'] as int? ?? 0,
          };
        })
        .toList();
  }

  /// Opt a user in as a mentor (upsert the mentors row).
  static Future<void> optInAsMentor(String profileId) async {
    await _db.from('mentors').upsert({'profile_id': profileId});
  }
}
