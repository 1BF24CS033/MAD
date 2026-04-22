import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_card.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
              const SizedBox(height: 20),
              // Search bar style header (matching wireframe)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.peach.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.peach.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.search_rounded, color: AppColors.peach, size: 20),
                    SizedBox(width: 10),
                    Text(
                      'Search for Topics...',
                      style: TextStyle(
                        color: AppColors.subtleText,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 400.ms),
              const SizedBox(height: 24),
              // About Us Header
              GlassCard(
                borderColor: AppColors.primaryGreen.withValues(alpha: 0.3),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.primaryGreen.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.auto_stories_rounded,
                            color: AppColors.primaryGreen,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ABOUT US',
                                style: TextStyle(
                                  color: AppColors.peach,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Benkyo · v1.0.0',
                                style: TextStyle(
                                  color: AppColors.subtleText,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),
              // About Us Content
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'About Us Content',
                      style: TextStyle(
                        color: AppColors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Benkyo (勉強) — Japanese for "study" — is a peer-to-peer learning platform designed by students, for students.',
                      style: TextStyle(
                        color: AppColors.subtleText,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'We believe the best learning happens when students teach each other. Benkyo connects learners with mentors across campuses, making quality help accessible to everyone.',
                      style: TextStyle(
                        color: AppColors.subtleText,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Features list
                    _buildFeatureItem(
                      Icons.people_rounded,
                      'Peer-to-Peer Learning',
                      'Connect with classmates for study sessions',
                    ),
                    _buildFeatureItem(
                      Icons.psychology_rounded,
                      'Mentorship',
                      'Opt-in as a mentor and earn MentorPoints',
                    ),
                    _buildFeatureItem(
                      Icons.groups_rounded,
                      'Project Collaboration',
                      'Find teammates for projects and hackathons',
                    ),
                    _buildFeatureItem(
                      Icons.stars_rounded,
                      'Gamified Rewards',
                      'Earn and redeem MentorPoints for benefits',
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
              // SDG Goals
              GlassCard(
                borderColor: AppColors.tealAccent.withValues(alpha: 0.3),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.public_rounded, color: AppColors.tealAccent, size: 22),
                        SizedBox(width: 10),
                        Text(
                          'Alignment of Benkyo with SDG Goals',
                          style: TextStyle(
                            color: AppColors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _buildSdgItem(
                      '4',
                      'Quality Education',
                      'Democratizing access to peer mentoring.',
                    ),
                    _buildSdgItem(
                      '10',
                      'Reduced Inequalities',
                      'Free, inclusive learning for all students.',
                    ),
                    _buildSdgItem(
                      '17',
                      'Partnerships for Goals',
                      'Building cross-campus learning communities.',
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primaryGreen, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.subtleText,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSdgItem(String number, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: AppColors.tealAccent.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: AppColors.tealAccent,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
                Text(
                  desc,
                  style: const TextStyle(
                    color: AppColors.subtleText,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
