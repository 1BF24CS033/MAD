import 'package:flutter/material.dart';
import '../models/peer_work_session.dart';
import '../theme/app_theme.dart';
import 'glass_card.dart';

class SessionTile extends StatelessWidget {
  final PeerWorkSession session;

  const SessionTile({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    final isMentor = session.mentorName == 'You';
    final timeAgo = _formatTimeAgo(session.date);

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isMentor
                  ? AppColors.tealAccent.withValues(alpha: 0.2)
                  : AppColors.sage.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isMentor ? Icons.psychology_rounded : Icons.school_rounded,
              color: isMentor ? AppColors.tealAccent : AppColors.sage,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.topic,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isMentor
                      ? 'Mentored ${session.learnerName}'
                      : 'With ${session.mentorName}',
                  style: const TextStyle(
                    color: AppColors.subtleText,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (session.completed)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.stars_rounded,
                      color: AppColors.peach,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '+${session.pointsAwarded}',
                      style: const TextStyle(
                        color: AppColors.peach,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 4),
              Text(
                timeAgo,
                style: const TextStyle(
                  color: AppColors.subtleText,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTimeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    return '${diff.inMinutes}m ago';
  }
}
