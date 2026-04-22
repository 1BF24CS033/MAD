import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_card.dart';
import 'topics_interest_screen.dart';

class SemesterSelectScreen extends StatefulWidget {
  const SemesterSelectScreen({super.key});

  @override
  State<SemesterSelectScreen> createState() => _SemesterSelectScreenState();
}

class _SemesterSelectScreenState extends State<SemesterSelectScreen> {
  int? _selectedSemester;
  final _nameController = TextEditingController(text: 'Student');

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.tealAccent.withValues(alpha: 0.06),
              AppColors.scaffoldBg,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
                const SizedBox(height: 24),
                Text(
                  'Tell us about\nyourself',
                  style: Theme.of(context).textTheme.displayLarge,
                ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.2),
                const SizedBox(height: 8),
                Text(
                  'We\'ll personalize your experience',
                  style: Theme.of(context).textTheme.bodyMedium,
                ).animate().fadeIn(delay: 200.ms),
                const SizedBox(height: 32),
                // Name field
                GlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: TextField(
                    controller: _nameController,
                    style: const TextStyle(color: AppColors.white),
                    decoration: const InputDecoration(
                      labelText: 'Your Name',
                      labelStyle: TextStyle(color: AppColors.subtleText),
                      prefixIcon: Icon(Icons.person_outline, color: AppColors.primaryGreen),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                  ),
                ).animate().fadeIn(delay: 300.ms).slideX(begin: 0.1),
                const SizedBox(height: 8),
                // Semester Selection
                Text(
                  'Select your Semester',
                  style: Theme.of(context).textTheme.titleMedium,
                ).animate().fadeIn(delay: 500.ms),
                const SizedBox(height: 14),
                Expanded(
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 1.4,
                    ),
                    itemCount: 8,
                    itemBuilder: (context, index) {
                      final sem = index + 1;
                      final isSelected = _selectedSemester == sem;
                      return GestureDetector(
                        onTap: () {
                          setState(() => _selectedSemester = sem);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primaryGreen.withValues(alpha: 0.25)
                                : AppColors.cardBg.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primaryGreen
                                  : AppColors.glassBorder,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              'Sem $sem',
                              style: TextStyle(
                                color: isSelected
                                    ? AppColors.primaryGreen
                                    : AppColors.white,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w400,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      )
                          .animate()
                          .fadeIn(delay: (500 + index * 50).ms)
                          .scale(begin: const Offset(0.9, 0.9));
                    },
                  ),
                ),
                // Next button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _selectedSemester != null
                        ? () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => TopicsInterestScreen(
                                  name: _nameController.text,
                                  semester: _selectedSemester!,
                                ),
                              ),
                            );
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      disabledBackgroundColor:
                          AppColors.primaryGreen.withValues(alpha: 0.2),
                      disabledForegroundColor:
                          AppColors.white.withValues(alpha: 0.3),
                    ),
                    child: const Text('Continue'),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
