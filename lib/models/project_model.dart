class ProjectModel {
  final String id;
  final String title;
  final String description;
  final String postedBy;
  final List<String> skillsRequired;
  final int teamSize;
  final int currentMembers;
  final DateTime postedDate;

  ProjectModel({
    required this.id,
    required this.title,
    required this.description,
    required this.postedBy,
    required this.skillsRequired,
    this.teamSize = 4,
    this.currentMembers = 1,
    required this.postedDate,
  });
}
