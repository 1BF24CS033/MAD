import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/session_provider.dart';
import '../../providers/help_request_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/mentor_points_badge.dart';
import '../../widgets/role_toggle.dart';
import '../../widgets/session_tile.dart';
import '../mentorship/mentor_list_screen.dart';
import '../projects/project_board_screen.dart';
import '../rewards/rewards_store_screen.dart';
import '../sessions/browse_requests_screen.dart';
import '../sessions/browse_group_studies_screen.dart';
import '../sessions/my_requests_screen.dart';
import '../about/about_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  void _navigateTo(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      _DashboardView(onNavigate: _navigateTo),
      const MentorListScreen(),
      const ProjectBoardScreen(),
      const RewardsStoreScreen(),
      const AboutScreen(),
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
            BottomNavigationBarItem(
              icon: Icon(Icons.rocket_launch_rounded),
              label: 'Projects',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.stars_rounded),
              label: 'Rewards',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardView extends StatelessWidget {
  final void Function(int) onNavigate;

  const _DashboardView({required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final sessionProvider = context.watch<SessionProvider>();
    final helpProvider = context.watch<HelpRequestProvider>();
    final user = userProvider.user;

    // Open requests that mentors can accept
    final openRequestCount = helpProvider.openRequests.length;
    // Learner's own pending requests
    final myPendingCount =
        helpProvider.myRequests.where((r) => r.isOpen).length;

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
              const SizedBox(height: 20),
              // Profile Card
              GlassCard(
                borderColor: AppColors.primaryGreen.withValues(alpha: 0.3),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.primaryGreen, AppColors.tealAccent],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Text(
                          user.name.isNotEmpty
                              ? user.name[0].toUpperCase()
                              : 'S',
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.name,
                            style: const TextStyle(
                              color: AppColors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'BMSCE · Sem ${user.semester}',
                            style: const TextStyle(
                              color: AppColors.subtleText,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    MentorPointsBadge(points: user.mentorPoints, compact: true),
                  ],
                ),
              ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),
              const SizedBox(height: 6),
              // Role toggle
              Center(
                child: RoleToggle(
                  isMentor: user.isMentor,
                  onToggle: (_) => userProvider.toggleRole(),
                ),
              ).animate().fadeIn(delay: 200.ms),
              const SizedBox(height: 22),

              // ── Quick Actions ──────────────────────────────────────────────
              Text('Quick Actions',
                      style: Theme.of(context).textTheme.titleLarge)
                  .animate()
                  .fadeIn(delay: 250.ms),
              const SizedBox(height: 12),

              // Row 1: Learner actions
              Row(
                children: [
                  Expanded(
                    child: _QuickActionCard(
                      title: 'Ask for\nHelp',
                      subtitle: 'Post a doubt request',
                      icon: Icons.help_outline_rounded,
                      color: AppColors.tealAccent,
                      badge: myPendingCount,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const MyRequestsScreen()),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _QuickActionCard(
                      title: 'Help\nOthers',
                      subtitle: 'Browse open requests',
                      icon: Icons.volunteer_activism_rounded,
                      color: AppColors.peach,
                      badge: openRequestCount,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const BrowseRequestsScreen()),
                      ),
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.15),
              const SizedBox(height: 12),

              // Row 2: Navigation shortcuts
              Row(
                children: [
                  Expanded(
                    child: _QuickActionCard(
                      title: 'Projects',
                      subtitle: 'Find teammates',
                      icon: Icons.rocket_launch_rounded,
                      color: AppColors.sage,
                      onTap: () => onNavigate(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _QuickActionCard(
                      title: 'Rewards',
                      subtitle: 'Redeem your points',
                      icon: Icons.stars_rounded,
                      color: AppColors.primaryGreen,
                      onTap: () => onNavigate(3),
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 380.ms).slideY(begin: 0.15),
              const SizedBox(height: 12),

              // Row 3: Group Study
              Row(
                children: [
                  Expanded(
                    child: _QuickActionCard(
                      title: 'Group\nStudy',
                      subtitle: 'Study together',
                      icon: Icons.groups_rounded,
                      color: AppColors.tealAccent,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const BrowseGroupStudiesScreen()),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _QuickActionCard(
                      title: 'Find\nMentors',
                      subtitle: 'Browse mentors',
                      icon: Icons.psychology_rounded,
                      color: AppColors.peach,
                      onTap: () => onNavigate(1),
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 440.ms).slideY(begin: 0.15),

              const SizedBox(height: 28),

              // ── My Help Requests preview ───────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('My Help Requests',
                      style: Theme.of(context).textTheme.titleLarge),
                  TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const MyRequestsScreen()),
                    ),
                    child: const Text('See all',
                        style: TextStyle(color: AppColors.tealAccent)),
                  ),
                ],
              ).animate().fadeIn(delay: 420.ms),
              const SizedBox(height: 8),
              if (helpProvider.myRequests.isEmpty)
                GlassCard(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        const Icon(Icons.help_outline_rounded,
                            size: 36, color: AppColors.subtleText),
                        const SizedBox(height: 8),
                        const Text('No requests yet',
                            style:
                                TextStyle(color: AppColors.subtleText)),
                        const SizedBox(height: 10),
                        ElevatedButton.icon(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    const MyRequestsScreen()),
                          ),
                          icon: const Icon(Icons.add_rounded, size: 16),
                          label: const Text('Post a Help Request'),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.tealAccent),
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(delay: 450.ms)
              else
                ...helpProvider.myRequests.take(2).map((req) {
                  final statusColor = req.isOpen
                      ? AppColors.tealAccent
                      : req.isAccepted
                          ? AppColors.primaryGreen
                          : AppColors.subtleText;
                  return GlassCard(
                    borderColor: statusColor.withValues(alpha: 0.25),
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(req.topic,
                                  style: const TextStyle(
                                      color: AppColors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13)),
                              const SizedBox(height: 3),
                              Text(req.description,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      color: AppColors.subtleText,
                                      fontSize: 12)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            req.status.toUpperCase(),
                            style: TextStyle(
                                color: statusColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 450.ms);
                }),

              const SizedBox(height: 28),

              // ── Session History ────────────────────────────────────────────
              Text('Session History',
                      style: Theme.of(context).textTheme.titleLarge)
                  .animate()
                  .fadeIn(delay: 500.ms),
              const SizedBox(height: 12),
              if (sessionProvider.activeSessions.isEmpty)
                GlassCard(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        const Icon(Icons.history_rounded,
                            size: 36, color: AppColors.subtleText),
                        const SizedBox(height: 8),
                        const Text('No sessions yet',
                            style:
                                TextStyle(color: AppColors.subtleText)),
                      ],
                    ),
                  ),
                ).animate().fadeIn(delay: 520.ms)
              else
                ...sessionProvider.activeSessions
                    .take(3)
                    .map((s) => SessionTile(session: s))
                    .toList()
                    .animate(interval: 80.ms)
                    .fadeIn()
                    .slideX(begin: 0.05),

              const SizedBox(height: 28),

              // ── Study History ──────────────────────────────────────────────
              if (sessionProvider.studyHistory.isNotEmpty) ...[
                Text('Study History',
                        style: Theme.of(context).textTheme.titleLarge)
                    .animate()
                    .fadeIn(delay: 600.ms),
                const SizedBox(height: 12),
                GlassCard(
                  child: Column(
                    children: sessionProvider.studyHistory
                        .take(5)
                        .map(
                          (topic) => Padding(
                            padding:
                                const EdgeInsets.symmetric(vertical: 8),
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
                                  child: Text(topic,
                                      style: const TextStyle(
                                          color: AppColors.white,
                                          fontSize: 13)),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ).animate().fadeIn(delay: 650.ms),
              ],
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Quick Action Card ──────────────────────────────────────────────────────────

class _QuickActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final int badge;

  const _QuickActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.onTap,
    this.badge = 0,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        borderColor: color.withValues(alpha: 0.25),
        child: Stack(
          children: [
            Column(
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
                  style: const TextStyle(
                      color: AppColors.subtleText, fontSize: 11),
                ),
              ],
            ),
            if (badge > 0)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: AppColors.peach,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      '$badge',
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
