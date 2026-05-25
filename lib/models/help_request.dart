class HelpRequest {
  final String id;
  final String learnerId;
  final String learnerName;
  final String topic;
  final String description;
  final int durationMinutes;
  final String status; // open | accepted | completed | cancelled
  final String? mentorId;
  final String? mentorName;
  final DateTime createdAt;

  HelpRequest({
    required this.id,
    required this.learnerId,
    required this.learnerName,
    required this.topic,
    required this.description,
    this.durationMinutes = 30,
    this.status = 'open',
    this.mentorId,
    this.mentorName,
    required this.createdAt,
  });

  bool get isOpen => status == 'open';
  bool get isAccepted => status == 'accepted';

  factory HelpRequest.fromJson(Map<String, dynamic> json,
      {String currentUserId = ''}) {
    final learner = json['learner'] as Map<String, dynamic>?;
    final mentor = json['mentor'] as Map<String, dynamic>?;
    return HelpRequest(
      id: json['id'] as String,
      learnerId: json['learner_id'] as String? ?? '',
      learnerName: json['learner_id'] == currentUserId
          ? 'You'
          : (learner?['name'] as String? ?? 'Unknown'),
      topic: json['topic'] as String,
      description: json['description'] as String? ?? '',
      durationMinutes: json['duration_minutes'] as int? ?? 30,
      status: json['status'] as String? ?? 'open',
      mentorId: json['mentor_id'] as String?,
      mentorName: json['mentor_id'] == currentUserId
          ? 'You'
          : (mentor?['name'] as String?),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'learner_id': learnerId,
        'topic': topic,
        'description': description,
        'duration_minutes': durationMinutes,
        'status': status,
      };
}
