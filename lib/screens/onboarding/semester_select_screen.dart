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
  final _nameController = TextEditingController(text: '');
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool get _canContinue =>
      _selectedSemester != null &&
      _nameController.text.trim().isNotEmpty &&
      _emailController.text.trim().isNotEmpty &&
      _passwordController.text.length >= 6;

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
                const SizedBox(height: 16),
                Text(
                  'Create your\naccount',
                  style: Theme.of(context).textTheme.displayLarge,
                ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.2),
                const SizedBox(height: 8),
                Text(
                  'We\'ll personalise your experience',
                  style: Theme.of(context).textTheme.bodyMedium,
                ).animate().fadeIn(delay: 200.ms),
                const SizedBox(height: 20),
                // Name field
                GlassCard(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: TextField(
                    controller: _nameController,
                    style: const TextStyle(color: AppColors.white),
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      labelText: 'Your Name',
                      labelStyle: TextStyle(color: AppColors.subtleText),
                      prefixIcon: Icon(Icons.person_outline,
                          color: AppColors.primaryGreen),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                  ),
                ).animate().fadeIn(delay: 300.ms).slideX(begin: 0.1),
                // Email field
                GlassCard(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: AppColors.white),
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      labelStyle: TextStyle(color: AppColors.subtleText),
                      prefixIcon: Icon(Icons.email_outlined,
                          color: AppColors.primaryGreen),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                  ),
                ).animate().fadeIn(delay: 350.ms).slideX(begin: 0.1),
                // Password field
                GlassCard(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: const TextStyle(color: AppColors.white),
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: 'Password (min 6 chars)',
                      labelStyle:
                          const TextStyle(color: AppColors.subtleText),
                      prefixIcon: const Icon(Icons.lock_outline,
                          color: AppColors.primaryGreen),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: AppColors.subtleText,
                        ),
                        onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword),
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                  ),
                ).animate().fadeIn(delay: 400.ms).slideX(begin: 0.1),
                const SizedBox(height: 8),
                // Semester Selection
                Text(
                  'Select your Semester',
                  style: Theme.of(context).textTheme.titleMedium,
                ).animate().fadeIn(delay: 450.ms),
                const SizedBox(height: 12),
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
                                ? AppColors.primaryGreen
                                    .withValues(alpha: 0.25)
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
                    onPressed: _canContinue
                        ? () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => TopicsInterestScreen(
                                  name: _nameController.text.trim(),
                                  semester: _selectedSemester!,
                                  email: _emailController.text.trim(),
                                  password: _passwordController.text,
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
