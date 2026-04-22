class PeerWorkSession {
  final String id;
  final String topic;
  final String mentorName;
  final String learnerName;
  final DateTime date;
  final int durationMinutes;
  final int pointsAwarded;
  final bool completed;

  PeerWorkSession({
    required this.id,
    required this.topic,
    required this.mentorName,
    required this.learnerName,
    required this.date,
    this.durationMinutes = 30,
    this.pointsAwarded = 10,
    this.completed = false,
  });
}
