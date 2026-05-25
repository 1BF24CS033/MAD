class PeerWorkSession {
  final String id;
  final String topic;
  final String mentorName;
  final String learnerName;
  final String mentorId;
  final String learnerId;
  final DateTime date;
  final int durationMinutes;
  final int pointsAwarded;
  final bool completed;
  final String status; // pending | accepted | completed | declined

  PeerWorkSession({
    required this.id,
    required this.topic,
    required this.mentorName,
    required this.learnerName,
    this.mentorId = '',
    this.learnerId = '',
    required this.date,
    this.durationMinutes = 30,
    this.pointsAwarded = 10,
    this.completed = false,
    this.status = 'pending',
  });

  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';

  factory PeerWorkSession.fromJson(Map<String, dynamic> json,
      {required String currentUserId}) {
    final mentor = json['mentor'] as Map<String, dynamic>?;
    final learner = json['learner'] as Map<String, dynamic>?;
    final mentorId = json['mentor_id'] as String? ?? '';
    final learnerId = json['learner_id'] as String? ?? '';

    return PeerWorkSession(
      id: json['id'] as String,
      topic: json['topic'] as String,
      mentorId: mentorId,
      learnerId: learnerId,
      mentorName: mentorId == currentUserId
          ? 'You'
          : (mentor?['name'] as String? ?? 'Unknown'),
      learnerName: learnerId == currentUserId
          ? 'You'
          : (learner?['name'] as String? ?? 'Unknown'),
      date: DateTime.parse(json['date'] as String),
      durationMinutes: json['duration_minutes'] as int? ?? 30,
      pointsAwarded: json['points_awarded'] as int? ?? 10,
      completed: json['completed'] as bool? ?? false,
      status: json['status'] as String? ?? 'pending',
    );
  }

  Map<String, dynamic> toJson() => {
        'topic': topic,
        'mentor_id': mentorId,
        'learner_id': learnerId,
        'date': date.toIso8601String(),
        'duration_minutes': durationMinutes,
        'points_awarded': pointsAwarded,
        'completed': completed,
        'status': status,
      };
}
