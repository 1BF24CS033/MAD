import 'package:flutter/material.dart';
import '../models/project_model.dart';
import '../theme/app_theme.dart';
import 'glass_card.dart';

class ProjectCard extends StatelessWidget {
  final ProjectModel project;
  final VoidCallback? onJoin;

  const ProjectCard({
    super.key,
    required this.project,
    this.onJoin,
  });

  @override
  Widget build(BuildContext context) {
    final spotsLeft = project.teamSize - project.currentMembers;

    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  project.title,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.sage.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$spotsLeft spots left',
                  style: const TextStyle(
                    color: AppColors.sage,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            project.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.subtleText,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: project.skillsRequired.map((skill) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.tealAccent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.tealAccent.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  skill,
                  style: const TextStyle(
                    color: AppColors.tealAccent,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(Icons.person_outline, size: 14, color: AppColors.subtleText),
              const SizedBox(width: 4),
              Text(
                project.postedBy,
                style: const TextStyle(
                  color: AppColors.subtleText,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              SizedBox(
                height: 34,
                child: ElevatedButton(
                  onPressed: onJoin,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                  child: const Text('Join'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
