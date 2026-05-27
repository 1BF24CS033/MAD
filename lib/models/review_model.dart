class ReviewModel {
  final String id;
  final String requestId;
  final String reviewerId;
  final String mentorId;
  final int rating;
  final String comment;
  final DateTime createdAt;

  // Joined fields
  final String? reviewerName;
  final String? mentorName;

  ReviewModel({
    required this.id,
    required this.requestId,
    required this.reviewerId,
    required this.mentorId,
    required this.rating,
    this.comment = '',
    required this.createdAt,
    this.reviewerName,
    this.mentorName,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    final reviewer = json['reviewer'] as Map<String, dynamic>?;
    final mentor = json['mentor'] as Map<String, dynamic>?;
    return ReviewModel(
      id: json['id'] as String,
      requestId: json['request_id'] as String,
      reviewerId: json['reviewer_id'] as String,
      mentorId: json['mentor_id'] as String,
      rating: json['rating'] as int,
      comment: json['comment'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
      reviewerName: reviewer?['name'] as String?,
      mentorName: mentor?['name'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'request_id': requestId,
        'reviewer_id': reviewerId,
        'mentor_id': mentorId,
        'rating': rating,
        'comment': comment,
      };
}
