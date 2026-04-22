import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../providers/project_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/project_card.dart';
import '../../widgets/search_bar_widget.dart';
import 'post_project_screen.dart';

class ProjectBoardScreen extends StatelessWidget {
  const ProjectBoardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final projectProvider = context.watch<ProjectProvider>();
    final projects = projectProvider.projects;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.sage.withValues(alpha: 0.05),
            AppColors.scaffoldBg,
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Text(
                'Project Board',
                style: Theme.of(context).textTheme.displayMedium,
              ).animate().fadeIn(duration: 400.ms),
              const SizedBox(height: 4),
              const Text(
                'Find teammates & collaborate',
                style: TextStyle(color: AppColors.subtleText, fontSize: 13),
              ).animate().fadeIn(delay: 100.ms),
              const SizedBox(height: 16),
              // Search & Filter
              SearchBarWidget(
                hintText: 'Filter by skill...',
                onChanged: (v) => projectProvider.setFilter(v),
              ).animate().fadeIn(delay: 200.ms),
              const SizedBox(height: 8),
              if (projectProvider.filterTopic.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.sage.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Filtered: ${projectProvider.filterTopic}',
                              style: const TextStyle(
                                color: AppColors.sage,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: () => projectProvider.clearFilter(),
                              child: const Icon(Icons.close,
                                  size: 14, color: AppColors.sage),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 8),
              // Project list
              Expanded(
                child: projects.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.folder_open_rounded,
                                size: 48, color: AppColors.subtleText),
                            const SizedBox(height: 12),
                            const Text(
                              'No projects found',
                              style:
                                  TextStyle(color: AppColors.subtleText),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: projects.length,
                        itemBuilder: (context, index) {
                          return ProjectCard(
                            project: projects[index],
                            onJoin: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Joined "${projects[index].title}" 🎉',
                                    style: const TextStyle(
                                        color: AppColors.white),
                                  ),
                                  backgroundColor: AppColors.primaryGreen,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              );
                            },
                          )
                              .animate()
                              .fadeIn(delay: (200 + index * 100).ms)
                              .slideY(begin: 0.1);
                        },
                      ),
              ),
              // Post project button
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PostProjectScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add_rounded, size: 20),
                    label: const Text('Post a Project'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.sage,
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2),
            ],
          ),
        ),
      ),
    );
  }
}
