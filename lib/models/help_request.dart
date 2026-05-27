class HelpRequest {
  final String id;
  final String learnerId;
  final String learnerName;
  final int learnerSemester;
  final String? learnerEmail;
  final String topic;
  final String description;
  final int durationMinutes;
  final String status; // open | accepted | pending_review | completed | cancelled
  final String type; // help | group_study
  final String? mentorId;
  final String? mentorName;
  final String? mentorEmail;
  final bool emailShared;
  final bool wantsMeet;
  final String? meetLink;
  final int maxParticipants;
  final int currentParticipants;
  final DateTime createdAt;

  HelpRequest({
    required this.id,
    required this.learnerId,
    required this.learnerName,
    this.learnerSemester = 1,
    this.learnerEmail,
    required this.topic,
    required this.description,
    this.durationMinutes = 30,
    this.status = 'open',
    this.type = 'help',
    this.mentorId,
    this.mentorName,
    this.mentorEmail,
    this.emailShared = false,
    this.wantsMeet = false,
    this.meetLink,
    this.maxParticipants = 1,
    this.currentParticipants = 0,
    required this.createdAt,
  });

  bool get isOpen => status == 'open';
  bool get isAccepted => status == 'accepted';
  bool get isPendingReview => status == 'pending_review';
  bool get isCompleted => status == 'completed';
  bool get isGroupStudy => type == 'group_study';
  bool get isHelp => type == 'help';
  bool get isFull => currentParticipants >= maxParticipants;

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
      learnerSemester: learner?['semester'] as int? ?? 1,
      learnerEmail: learner?['email'] as String?,
      topic: json['topic'] as String,
      description: json['description'] as String? ?? '',
      durationMinutes: json['duration_minutes'] as int? ?? 30,
      status: json['status'] as String? ?? 'open',
      type: json['type'] as String? ?? 'help',
      mentorId: json['mentor_id'] as String?,
      mentorName: json['mentor_id'] == currentUserId
          ? 'You'
          : (mentor?['name'] as String?),
      mentorEmail: mentor?['email'] as String?,
      emailShared: json['email_shared'] as bool? ?? false,
      wantsMeet: json['wants_meet'] as bool? ?? false,
      meetLink: json['meet_link'] as String?,
      maxParticipants: json['max_participants'] as int? ?? 1,
      currentParticipants: json['member_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'learner_id': learnerId,
        'topic': topic,
        'description': description,
        'duration_minutes': durationMinutes,
        'status': status,
        'type': type,
        'email_shared': emailShared,
        'wants_meet': wantsMeet,
        'max_participants': maxParticipants,
      };
}
