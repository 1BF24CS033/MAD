class UserModel {
  final String id; // Supabase auth UUID
  String name;
  String college;
  int semester;
  List<String> topicsOfInterest;
  bool isMentor;
  int mentorPoints;
  List<String> mentorTopics;
  String? avatarUrl;
  bool onboardingComplete;

  UserModel({
    this.id = '',
    this.name = 'Student',
    this.college = 'BMS College of Engineering',
    this.semester = 1,
    this.topicsOfInterest = const [],
    this.isMentor = false,
    this.mentorPoints = 0,
    this.mentorTopics = const [],
    this.avatarUrl,
    this.onboardingComplete = false,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Student',
      college: json['college'] as String? ?? 'BMS College of Engineering',
      semester: json['semester'] as int? ?? 1,
      topicsOfInterest: List<String>.from(json['topics_of_interest'] ?? []),
      isMentor: json['is_mentor'] as bool? ?? false,
      mentorPoints: json['mentor_points'] as int? ?? 0,
      mentorTopics: List<String>.from(json['mentor_topics'] ?? []),
      avatarUrl: json['avatar_url'] as String?,
      onboardingComplete: json['onboarding_complete'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'college': college,
        'semester': semester,
        'topics_of_interest': topicsOfInterest,
        'is_mentor': isMentor,
        'mentor_points': mentorPoints,
        'mentor_topics': mentorTopics,
        'avatar_url': avatarUrl,
        'onboarding_complete': onboardingComplete,
      };

  UserModel copyWith({
    String? id,
    String? name,
    String? college,
    int? semester,
    List<String>? topicsOfInterest,
    bool? isMentor,
    int? mentorPoints,
    List<String>? mentorTopics,
    String? avatarUrl,
    bool? onboardingComplete,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      college: college ?? this.college,
      semester: semester ?? this.semester,
      topicsOfInterest: topicsOfInterest ?? this.topicsOfInterest,
      isMentor: isMentor ?? this.isMentor,
      mentorPoints: mentorPoints ?? this.mentorPoints,
      mentorTopics: mentorTopics ?? this.mentorTopics,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
    );
  }
}
