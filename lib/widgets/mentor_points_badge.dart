import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class MentorPointsBadge extends StatelessWidget {
  final int points;
  final bool compact;

  const MentorPointsBadge({
    super.key,
    required this.points,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.peach.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.peach.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.stars_rounded, color: AppColors.peach, size: 16),
            const SizedBox(width: 4),
            Text(
              '$points',
              style: const TextStyle(
                color: AppColors.peach,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.peach.withValues(alpha: 0.2),
            AppColors.peach.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.peach.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.stars_rounded, color: AppColors.peach, size: 28),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your MentorPoints',
                style: TextStyle(
                  color: AppColors.subtleText,
                  fontSize: 12,
                ),
              ),
              Text(
                '$points',
                style: const TextStyle(
                  color: AppColors.peach,
                  fontWeight: FontWeight.w800,
                  fontSize: 24,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
