import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/session_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/mentor_points_badge.dart';
import '../../widgets/role_toggle.dart';
import '../../widgets/search_bar_widget.dart';
import '../../widgets/session_tile.dart';
import '../mentorship/mentor_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      const _DashboardView(),
      const MentorListScreen(),
    ];

    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: screens[_currentIndex],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: AppColors.glassBorder.withValues(alpha: 0.5),
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.psychology_rounded),
              label: 'Mentors',
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardView extends StatelessWidget {
  const _DashboardView();

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final sessionProvider = context.watch<SessionProvider>();
    final user = userProvider.user;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryGreen.withValues(alpha: 0.05),
            AppColors.scaffoldBg,
            AppColors.tealAccent.withValues(alpha: 0.03),
          ],
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              // Search bar
              const SearchBarWidget()
                  .animate()
                  .fadeIn(duration: 400.ms)
                  .slideY(begin: -0.2),
              const SizedBox(height: 20),
              // Profile Card
              GlassCard(
                borderColor: AppColors.primaryGreen.withValues(alpha: 0.3),
                child: Row(
                  children: [
                    // Avatar
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primaryGreen,
                            AppColors.tealAccent,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Center(
                        child: Text(
                          user.name.isNotEmpty ? user.name[0].toUpperCase() : 'S',
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 24,
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
                            'BMSCE · Sem ${user.semester}',
                            style: const TextStyle(
                              color: AppColors.subtleText,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    MentorPointsBadge(points: user.mentorPoints, compact: true),
                  ],
                ),
              ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),
              const SizedBox(height: 4),
              // Role toggle
              Center(
                child: RoleToggle(
                  isMentor: user.isMentor,
                  onToggle: (_) => userProvider.toggleRole(),
                ),
              ).animate().fadeIn(delay: 200.ms),
              const SizedBox(height: 20),
              // Quick Actions Grid (matching wireframe)
              Row(
                children: [
                  Expanded(
                    child: _QuickActionCard(
                      title: 'Exam Crunch\nTopics',
                      subtitle: 'Categorized by Semester',
                      icon: Icons.bolt_rounded,
                      color: AppColors.peach,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _QuickActionCard(
                      title: 'Mentor\nWork',
                      subtitle: 'Help your peers',
                      icon: Icons.psychology_rounded,
                      color: AppColors.tealAccent,
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.15),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _QuickActionCard(
                      title: 'Brush up\nskills',
                      subtitle: 'DSA, Math, etc.',
                      icon: Icons.fitness_center_rounded,
                      color: AppColors.sage,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _QuickActionCard(
                      title: 'Study by\nTopic',
                      subtitle: 'With your Peers',
                      icon: Icons.group_work_rounded,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.15),
              const SizedBox(height: 28),
              // PeerWork History
              Text(
                'Your PeerWork History',
                style: Theme.of(context).textTheme.titleLarge,
              ).animate().fadeIn(delay: 500.ms),
              const SizedBox(height: 12),
              if (sessionProvider.sessions.isEmpty)
                GlassCard(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Icon(Icons.history_rounded, size: 40, color: AppColors.subtleText),
                          const SizedBox(height: 8),
                          const Text(
                            'No sessions yet',
                            style: TextStyle(color: AppColors.subtleText),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                ...sessionProvider.sessions
                    .take(3)
                    .map((s) => SessionTile(session: s))
                    .toList()
                    .animate(interval: 100.ms)
                    .fadeIn()
                    .slideX(begin: 0.05),
              const SizedBox(height: 28),
              // Study History
              Text(
                'Your Study History',
                style: Theme.of(context).textTheme.titleLarge,
              ).animate().fadeIn(delay: 600.ms),
              const SizedBox(height: 12),
              GlassCard(
                child: Column(
                  children: sessionProvider.studyHistory
                      .take(5)
                      .map(
                        (topic) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: AppColors.sage,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  topic,
                                  style: const TextStyle(
                                    color: AppColors.white,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
              ).animate().fadeIn(delay: 700.ms),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _QuickActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      borderColor: color.withValues(alpha: 0.25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: AppColors.subtleText,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
