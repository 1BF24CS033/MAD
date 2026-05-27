import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/review_model.dart';
import 'supabase_service.dart';

/// Handles CRUD for the [reviews] table.
class ReviewService {
  static SupabaseClient get _db => SupabaseService.client;

  static const _select = '''
    *,
    reviewer:profiles!reviews_reviewer_id_fkey(name),
    mentor:profiles!reviews_mentor_id_fkey(name)
  ''';

  /// Submit a review for a help request.
  static Future<ReviewModel> submitReview({
    required String requestId,
    required String reviewerId,
    required String mentorId,
    required int rating,
    required String comment,
  }) async {
    final row = await _db
        .from('reviews')
        .insert({
          'request_id': requestId,
          'reviewer_id': reviewerId,
          'mentor_id': mentorId,
          'rating': rating,
          'comment': comment,
        })
        .select(_select)
        .single();

    // Update the mentor's average rating
    await _db.rpc('update_mentor_rating', params: {'p_mentor_id': mentorId});

    return ReviewModel.fromJson(row);
  }

  /// Fetch all reviews for a specific mentor.
  static Future<List<ReviewModel>> fetchMentorReviews(
      String mentorId) async {
    final rows = await _db
        .from('reviews')
        .select(_select)
        .eq('mentor_id', mentorId)
        .order('created_at', ascending: false);

    return rows
        .cast<Map<String, dynamic>>()
        .map((r) => ReviewModel.fromJson(r))
        .toList();
  }

  /// Check if a review already exists for a given request.
  static Future<bool> hasReview(String requestId) async {
    final rows = await _db
        .from('reviews')
        .select('id')
        .eq('request_id', requestId);
    return (rows as List).isNotEmpty;
  }
}
