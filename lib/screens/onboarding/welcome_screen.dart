import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_theme.dart';
import 'semester_select_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.scaffoldBg,
              AppColors.primaryGreen.withValues(alpha: 0.08),
              AppColors.scaffoldBg,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                const Spacer(flex: 2),
                // Logo / Icon
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: AppColors.primaryGreen.withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Icon(
                    Icons.auto_stories_rounded,
                    size: 48,
                    color: AppColors.primaryGreen,
                  ),
                )
                    .animate()
                    .fadeIn(duration: 600.ms)
                    .scale(begin: const Offset(0.8, 0.8)),
                const SizedBox(height: 32),
                // App name
                Text(
                  'Benkyo',
                  style:
                      Theme.of(context).textTheme.displayLarge?.copyWith(
                            fontSize: 40,
                            letterSpacing: -1,
                          ),
                ).animate().fadeIn(delay: 200.ms, duration: 600.ms).slideY(
                      begin: 0.3,
                      end: 0,
                    ),
                const SizedBox(height: 12),
                Text(
                  'Learn together. Grow together.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 16,
                        color: AppColors.subtleText,
                      ),
                ).animate().fadeIn(delay: 400.ms, duration: 600.ms),
                const Spacer(flex: 1),
                // Features Overview
                _buildFeatureRow(
                  Icons.people_rounded,
                  'Peer-to-peer study sessions',
                ).animate().fadeIn(delay: 500.ms).slideX(begin: -0.2),
                const SizedBox(height: 18),
                _buildFeatureRow(
                  Icons.psychology_rounded,
                  'Become a mentor & earn MentorPoints',
                ).animate().fadeIn(delay: 600.ms).slideX(begin: -0.2),
                const SizedBox(height: 18),
                _buildFeatureRow(
                  Icons.rocket_launch_rounded,
                  'Collaborate on real projects',
                ).animate().fadeIn(delay: 700.ms).slideX(begin: -0.2),
                const Spacer(flex: 2),
                // CTA Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const SemesterSelectScreen(),
                        ),
                      );
                    },
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Get Started'),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward_rounded, size: 20),
                      ],
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(delay: 800.ms, duration: 600.ms)
                    .slideY(begin: 0.3),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String text) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.tealAccent.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.tealAccent, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 15,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }
}
