class UserModel {
  String name;
  String college;
  int semester;
  List<String> topicsOfInterest;
  bool isMentor;
  int mentorPoints;
  List<String> mentorTopics;
  String? avatarUrl;

  UserModel({
    this.name = 'Student',
    this.college = 'BMS College of Engineering',
    this.semester = 1,
    this.topicsOfInterest = const [],
    this.isMentor = false,
    this.mentorPoints = 0,
    this.mentorTopics = const [],
    this.avatarUrl,
  });

  UserModel copyWith({
    String? name,
    String? college,
    int? semester,
    List<String>? topicsOfInterest,
    bool? isMentor,
    int? mentorPoints,
    List<String>? mentorTopics,
    String? avatarUrl,
  }) {
    return UserModel(
      name: name ?? this.name,
      college: college ?? this.college,
      semester: semester ?? this.semester,
      topicsOfInterest: topicsOfInterest ?? this.topicsOfInterest,
      isMentor: isMentor ?? this.isMentor,
      mentorPoints: mentorPoints ?? this.mentorPoints,
      mentorTopics: mentorTopics ?? this.mentorTopics,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}
