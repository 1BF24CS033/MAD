import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../providers/help_request_provider.dart';
import '../../models/help_request.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/search_bar_widget.dart';
import 'create_group_study_screen.dart';
import 'group_study_detail_screen.dart';

class BrowseGroupStudiesScreen extends StatelessWidget {
  const BrowseGroupStudiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HelpRequestProvider>();
    final studies = provider.openGroupStudies;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Group Studies'),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        actions: [
          IconButton(
            onPressed: () => provider.loadData(),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const CreateGroupStudyScreen()),
          );
        },
        backgroundColor: AppColors.sage,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Create'),
      ),
      body: Container(
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
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: SearchBarWidget(
                  hintText: 'Search by topic...',
                  onChanged: (v) => provider.setFilter(v),
                ).animate().fadeIn(duration: 300.ms),
              ),
              Expanded(
                child: provider.loading
                    ? const Center(child: CircularProgressIndicator())
                    : studies.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.groups_rounded,
                                    size: 56,
                                    color: AppColors.subtleText),
                                const SizedBox(height: 12),
                                const Text(
                                  'No group studies yet',
                                  style: TextStyle(
                                      color: AppColors.subtleText),
                                ),
                                const SizedBox(height: 8),
                                ElevatedButton.icon(
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            const CreateGroupStudyScreen()),
                                  ),
                                  icon: const Icon(Icons.add_rounded,
                                      size: 16),
                                  label: const Text(
                                      'Start a Group Study'),
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.sage),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 4),
                            itemCount: studies.length,
                            itemBuilder: (context, index) {
                              final study = studies[index];
                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          GroupStudyDetailScreen(
                                              study: study),
                                    ),
                                  );
                                },
                                child: _GroupStudyCard(study: study),
                              )
                                  .animate()
                                  .fadeIn(delay: (index * 80).ms)
                                  .slideY(begin: 0.05);
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GroupStudyCard extends StatelessWidget {
  final HelpRequest study;

  const _GroupStudyCard({required this.study});

  @override
  Widget build(BuildContext context) {
    final spotsLeft = study.maxParticipants - study.currentParticipants;

    return GlassCard(
      borderColor: AppColors.sage.withValues(alpha: 0.25),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.sage.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: AppColors.sage.withValues(alpha: 0.3)),
                ),
                child: Text(
                  study.topic,
                  style: const TextStyle(
                    color: AppColors.sage,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: spotsLeft > 0
                      ? AppColors.primaryGreen.withValues(alpha: 0.15)
                      : AppColors.peach.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  spotsLeft > 0 ? '$spotsLeft spots left' : 'Full',
                  style: TextStyle(
                    color: spotsLeft > 0
                        ? AppColors.primaryGreen
                        : AppColors.peach,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Description
          Text(
            study.description,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 14,
              height: 1.4,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
          // Footer
          Row(
            children: [
              const Icon(Icons.person_outline,
                  size: 14, color: AppColors.subtleText),
              const SizedBox(width: 4),
              Text(
                study.learnerName,
                style: const TextStyle(
                    color: AppColors.subtleText, fontSize: 12),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.peach.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Sem ${study.learnerSemester}',
                  style: const TextStyle(
                    color: AppColors.peach,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              Icon(Icons.groups_rounded,
                  size: 16, color: AppColors.sage),
              const SizedBox(width: 4),
              Text(
                '${study.currentParticipants}/${study.maxParticipants}',
                style: const TextStyle(
                    color: AppColors.sage,
                    fontSize: 12,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
