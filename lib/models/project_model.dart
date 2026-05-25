class ProjectModel {
  final String id;
  final String title;
  final String description;
  final String postedBy;       // display name (denormalised for UI)
  final String postedById;     // profile UUID (foreign key)
  final List<String> skillsRequired;
  final int teamSize;
  final int currentMembers;
  final DateTime postedDate;
  final bool isOpen;

  ProjectModel({
    required this.id,
    required this.title,
    required this.description,
    required this.postedBy,
    this.postedById = '',
    required this.skillsRequired,
    this.teamSize = 4,
    this.currentMembers = 1,
    required this.postedDate,
    this.isOpen = true,
  });

  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    // The query joins profiles so we can get the poster's name
    final poster = json['profiles'] as Map<String, dynamic>?;
    return ProjectModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      postedBy: poster?['name'] as String? ?? 'Unknown',
      postedById: json['posted_by'] as String? ?? '',
      skillsRequired: List<String>.from(json['skills_required'] ?? []),
      teamSize: json['team_size'] as int? ?? 4,
      currentMembers: json['current_members'] as int? ?? 1,
      postedDate: DateTime.parse(json['posted_date'] as String),
      isOpen: json['is_open'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'posted_by': postedById,
        'skills_required': skillsRequired,
        'team_size': teamSize,
        'current_members': currentMembers,
        'posted_date': postedDate.toIso8601String(),
        'is_open': isOpen,
      };
}
