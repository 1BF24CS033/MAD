import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_card.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().user;
    final userProvider = context.read<UserProvider>();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.primaryGreen.withValues(alpha: 0.05),
            AppColors.scaffoldBg,
          ],
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),

              // ── Profile card ───────────────────────────────────────────────
              GlassCard(
                borderColor: AppColors.primaryGreen.withValues(alpha: 0.3),
                child: Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.primaryGreen, AppColors.tealAccent],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: Text(
                          user.name.isNotEmpty
                              ? user.name[0].toUpperCase()
                              : 'S',
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.name,
                            style: const TextStyle(
                              color: AppColors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user.college,
                            style: const TextStyle(
                                color: AppColors.subtleText, fontSize: 12),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Semester ${user.semester}  ·  ${user.isMentor ? "Mentor" : "Learner"}',
                            style: const TextStyle(
                                color: AppColors.subtleText, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),

              const SizedBox(height: 16),

              // ── Stats row ──────────────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      label: 'MentorPoints',
                      value: '${user.mentorPoints}',
                      icon: Icons.stars_rounded,
                      color: AppColors.peach,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      label: 'Topics',
                      value: '${user.topicsOfInterest.length}',
                      icon: Icons.menu_book_rounded,
                      color: AppColors.tealAccent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      label: 'Semester',
                      value: '${user.semester}',
                      icon: Icons.school_rounded,
                      color: AppColors.sage,
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 150.ms),

              const SizedBox(height: 24),

              // ── Topics of interest ─────────────────────────────────────────
              if (user.topicsOfInterest.isNotEmpty) ...[
                Text('Your Topics',
                        style: Theme.of(context).textTheme.titleMedium)
                    .animate()
                    .fadeIn(delay: 200.ms),
                const SizedBox(height: 10),
                GlassCard(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: user.topicsOfInterest
                        .map((t) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: AppColors.tealAccent
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: AppColors.tealAccent
                                        .withValues(alpha: 0.3)),
                              ),
                              child: Text(t,
                                  style: const TextStyle(
                                      color: AppColors.tealAccent,
                                      fontSize: 12)),
                            ))
                        .toList(),
                  ),
                ).animate().fadeIn(delay: 250.ms),
                const SizedBox(height: 20),
              ],

              // ── About Benkyo ───────────────────────────────────────────────
              Text('About Benkyo',
                      style: Theme.of(context).textTheme.titleMedium)
                  .animate()
                  .fadeIn(delay: 300.ms),
              const SizedBox(height: 10),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.primaryGreen
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.auto_stories_rounded,
                              color: AppColors.primaryGreen, size: 20),
                        ),
                        const SizedBox(width: 12),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Benkyo · v1.0.0',
                                style: TextStyle(
                                    color: AppColors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14)),
                            Text('勉強 — Japanese for "study"',
                                style: TextStyle(
                                    color: AppColors.subtleText,
                                    fontSize: 11)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'A peer-to-peer learning platform designed by students, for students. Post doubts, find mentors, collaborate on projects, and earn rewards.',
                      style: TextStyle(
                          color: AppColors.subtleText,
                          fontSize: 13,
                          height: 1.5),
                    ),
                    const SizedBox(height: 14),
                    _buildFeatureRow(Icons.help_outline_rounded,
                        'Post doubts, get help from mentors'),
                    _buildFeatureRow(Icons.volunteer_activism_rounded,
                        'Mentor peers and earn MentorPoints'),
                    _buildFeatureRow(Icons.rocket_launch_rounded,
                        'Collaborate on real projects'),
                    _buildFeatureRow(Icons.stars_rounded,
                        'Redeem points for rewards'),
                  ],
                ),
              ).animate().fadeIn(delay: 350.ms),

              const SizedBox(height: 20),

              // ── SDG alignment ──────────────────────────────────────────────
              GlassCard(
                borderColor: AppColors.tealAccent.withValues(alpha: 0.3),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.public_rounded,
                            color: AppColors.tealAccent, size: 18),
                        SizedBox(width: 8),
                        Text('UN SDG Alignment',
                            style: TextStyle(
                                color: AppColors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildSdgRow('4', 'Quality Education'),
                    _buildSdgRow('10', 'Reduced Inequalities'),
                    _buildSdgRow('17', 'Partnerships for Goals'),
                  ],
                ),
              ).animate().fadeIn(delay: 400.ms),

              const SizedBox(height: 24),

              // ── Sign out ───────────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: AppColors.cardBg,
                        title: const Text('Sign Out',
                            style: TextStyle(color: AppColors.white)),
                        content: const Text(
                            'Are you sure you want to sign out?',
                            style: TextStyle(color: AppColors.subtleText)),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Cancel',
                                style:
                                    TextStyle(color: AppColors.subtleText)),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red.shade700),
                            child: const Text('Sign Out'),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true) {
                      await userProvider.signOut();
                    }
                  },
                  icon: const Icon(Icons.logout_rounded,
                      color: Colors.red, size: 18),
                  label: const Text('Sign Out',
                      style: TextStyle(color: Colors.red)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.red.withValues(alpha: 0.4)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ).animate().fadeIn(delay: 450.ms),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primaryGreen, size: 16),
          const SizedBox(width: 10),
          Text(text,
              style: const TextStyle(
                  color: AppColors.subtleText, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildSdgRow(String number, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: AppColors.tealAccent.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Text(number,
                  style: const TextStyle(
                      color: AppColors.tealAccent,
                      fontWeight: FontWeight.w700,
                      fontSize: 12)),
            ),
          ),
          const SizedBox(width: 10),
          Text(title,
              style: const TextStyle(
                  color: AppColors.subtleText, fontSize: 12)),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(12),
      margin: EdgeInsets.zero,
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                  color: color,
                  fontSize: 18,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  color: AppColors.subtleText, fontSize: 10),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
