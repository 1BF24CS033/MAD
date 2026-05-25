import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../providers/session_provider.dart';
import '../../providers/user_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/constants.dart';
import '../../widgets/glass_card.dart';

class PendingRequestsScreen extends StatelessWidget {
  const PendingRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sessionProvider = context.watch<SessionProvider>();
    final userProvider = context.watch<UserProvider>();
    final pending = sessionProvider.pendingRequests;
    final accepted = sessionProvider.acceptedMentorSessions;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Session Requests'),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.tealAccent.withValues(alpha: 0.05),
              AppColors.scaffoldBg,
            ],
          ),
        ),
        child: SafeArea(
          child: sessionProvider.loading
              ? const Center(child: CircularProgressIndicator())
              : (pending.isEmpty && accepted.isEmpty)
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.inbox_rounded,
                              size: 56, color: AppColors.subtleText),
                          const SizedBox(height: 12),
                          const Text(
                            'No session requests yet',
                            style: TextStyle(color: AppColors.subtleText),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Learners will send requests here',
                            style: TextStyle(
                                color: AppColors.subtleText, fontSize: 12),
                          ),
                        ],
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        if (pending.isNotEmpty) ...[
                          Text('Pending Requests (${pending.length})',
                              style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: 12),
                          ...pending.asMap().entries.map((e) {
                            final s = e.value;
                            return _RequestCard(
                              session: s,
                              onAccept: () async {
                                await sessionProvider.acceptSession(s.id);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          'Accepted session with ${s.learnerName}'),
                                      backgroundColor: AppColors.primaryGreen,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              },
                              onDecline: () async {
                                await sessionProvider.declineSession(s.id);
                              },
                            )
                                .animate()
                                .fadeIn(delay: (e.key * 80).ms)
                                .slideX(begin: 0.05);
                          }),
                          const SizedBox(height: 24),
                        ],
                        if (accepted.isNotEmpty) ...[
                          Text('Accepted Sessions (${accepted.length})',
                              style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: 12),
                          ...accepted.asMap().entries.map((e) {
                            final s = e.value;
                            return _AcceptedCard(
                              session: s,
                              onComplete: () async {
                                await sessionProvider.completeSession(
                                    s.id, AppConstants.pointsPerSession);
                                await userProvider.addMentorPoints(
                                    AppConstants.pointsPerSession);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          'Session completed! +${AppConstants.pointsPerSession} MentorPoints'),
                                      backgroundColor: AppColors.primaryGreen,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              },
                            )
                                .animate()
                                .fadeIn(delay: (e.key * 80).ms)
                                .slideX(begin: 0.05);
                          }),
                        ],
                      ],
                    ),
        ),
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final session;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const _RequestCard({
    required this.session,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderColor: AppColors.peach.withValues(alpha: 0.3),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.peach.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('Pending',
                    style: TextStyle(
                        color: AppColors.peach,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
              ),
              const Spacer(),
              Text(
                '${session.durationMinutes} min',
                style: const TextStyle(
                    color: AppColors.subtleText, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            session.topic,
            style: const TextStyle(
              color: AppColors.white,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'From: ${session.learnerName}',
            style: const TextStyle(
                color: AppColors.subtleText, fontSize: 13),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onDecline,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.subtleText,
                    side: BorderSide(
                        color: AppColors.subtleText.withValues(alpha: 0.3)),
                  ),
                  child: const Text('Decline'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: onAccept,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.tealAccent),
                  child: const Text('Accept'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AcceptedCard extends StatelessWidget {
  final session;
  final VoidCallback onComplete;

  const _AcceptedCard({required this.session, required this.onComplete});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderColor: AppColors.primaryGreen.withValues(alpha: 0.3),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('Accepted',
                    style: TextStyle(
                        color: AppColors.primaryGreen,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
              ),
              const Spacer(),
              Text('${session.durationMinutes} min',
                  style: const TextStyle(
                      color: AppColors.subtleText, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            session.topic,
            style: const TextStyle(
              color: AppColors.white,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 4),
          Text('With: ${session.learnerName}',
              style: const TextStyle(
                  color: AppColors.subtleText, fontSize: 13)),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onComplete,
              icon: const Icon(Icons.check_circle_outline, size: 18),
              label: const Text('Mark as Completed'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen),
            ),
          ),
        ],
      ),
    );
  }
}
