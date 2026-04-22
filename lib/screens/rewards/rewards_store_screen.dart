import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/dummy_data.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/mentor_points_badge.dart';

class RewardsStoreScreen extends StatelessWidget {
  const RewardsStoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().user;
    final rewards = DummyData.sampleRewards;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.peach.withValues(alpha: 0.06),
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
              // Header
              Center(
                child: MentorPointsBadge(points: user.mentorPoints),
              ).animate().fadeIn(duration: 500.ms).scale(begin: const Offset(0.9, 0.9)),
              const SizedBox(height: 28),
              Text(
                'Rewards Store',
                style: Theme.of(context).textTheme.titleLarge,
              ).animate().fadeIn(delay: 200.ms),
              const SizedBox(height: 4),
              const Text(
                'Redeem your MentorPoints for exclusive benefits',
                style: TextStyle(color: AppColors.subtleText, fontSize: 13),
              ).animate().fadeIn(delay: 300.ms),
              const SizedBox(height: 20),
              // Rewards Grid
              Expanded(
                child: GridView.builder(
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.9,
                  ),
                  itemCount: rewards.length,
                  itemBuilder: (context, index) {
                    final reward = rewards[index];
                    final canAfford =
                        user.mentorPoints >= reward.pointsCost;

                    return GlassCard(
                      margin: EdgeInsets.zero,
                      padding: const EdgeInsets.all(16),
                      borderColor: canAfford
                          ? AppColors.peach.withValues(alpha: 0.3)
                          : AppColors.glassBorder,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: canAfford
                                  ? AppColors.peach.withValues(alpha: 0.15)
                                  : AppColors.subtleText.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              _getIcon(reward.iconName),
                              color: canAfford
                                  ? AppColors.peach
                                  : AppColors.subtleText,
                              size: 22,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            reward.title,
                            style: const TextStyle(
                              color: AppColors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            reward.description,
                            style: const TextStyle(
                              color: AppColors.subtleText,
                              fontSize: 11,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const Spacer(),
                          // Cost & Redeem
                          Row(
                            children: [
                              const Icon(Icons.stars_rounded,
                                  size: 14, color: AppColors.peach),
                              const SizedBox(width: 4),
                              Text(
                                '${reward.pointsCost}',
                                style: const TextStyle(
                                  color: AppColors.peach,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                              const Spacer(),
                              if (canAfford)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.peach.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'Redeem',
                                    style: TextStyle(
                                      color: AppColors.peach,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    )
                        .animate()
                        .fadeIn(delay: (300 + index * 100).ms)
                        .scale(begin: const Offset(0.95, 0.95));
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIcon(String name) {
    switch (name) {
      case 'menu_book':
        return Icons.menu_book_rounded;
      case 'quiz':
        return Icons.quiz_rounded;
      case 'verified':
        return Icons.verified_rounded;
      case 'groups':
        return Icons.groups_rounded;
      default:
        return Icons.card_giftcard_rounded;
    }
  }
}
