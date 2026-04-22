import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/session_provider.dart';
import '../../providers/project_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/constants.dart';
import '../../widgets/topic_chip.dart';
import '../../widgets/role_toggle.dart';
import '../home/home_screen.dart';

class TopicsInterestScreen extends StatefulWidget {
  final String name;
  final int semester;

  const TopicsInterestScreen({
    super.key,
    required this.name,
    required this.semester,
  });

  @override
  State<TopicsInterestScreen> createState() => _TopicsInterestScreenState();
}

class _TopicsInterestScreenState extends State<TopicsInterestScreen> {
  final List<String> _selectedTopics = [];
  bool _isMentor = false;

  void _toggleTopic(String topic) {
    setState(() {
      if (_selectedTopics.contains(topic)) {
        _selectedTopics.remove(topic);
      } else {
        _selectedTopics.add(topic);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              AppColors.sage.withValues(alpha: 0.06),
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
                  'What are you\ninterested in?',
                  style: Theme.of(context).textTheme.displayLarge,
                ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.2),
                const SizedBox(height: 8),
                Text(
                  'Select topics you want to learn or teach',
                  style: Theme.of(context).textTheme.bodyMedium,
                ).animate().fadeIn(delay: 200.ms),
                const SizedBox(height: 24),
                // Role toggle
                Center(
                  child: RoleToggle(
                    isMentor: _isMentor,
                    onToggle: (val) => setState(() => _isMentor = val),
                  ),
                ).animate().fadeIn(delay: 300.ms).scale(begin: const Offset(0.9, 0.9)),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    _isMentor
                        ? 'You\'ll help others learn these topics'
                        : 'You want to study these topics',
                    style: const TextStyle(
                      color: AppColors.subtleText,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Topic chips
                Expanded(
                  child: SingleChildScrollView(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 10,
                      children: AppConstants.availableTopics.map((topic) {
                        return TopicChip(
                          label: topic,
                          isSelected: _selectedTopics.contains(topic),
                          onTap: () => _toggleTopic(topic),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Selected count
                if (_selectedTopics.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      '${_selectedTopics.length} topic${_selectedTopics.length > 1 ? 's' : ''} selected',
                      style: const TextStyle(
                        color: AppColors.primaryGreen,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                // Start button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _selectedTopics.isNotEmpty
                        ? () async {
                            final userProvider =
                                context.read<UserProvider>();
                            await userProvider.completeOnboarding(
                              name: widget.name,
                              semester: widget.semester,
                              topics: _selectedTopics,
                            );
                            if (_isMentor) {
                              userProvider.toggleRole();
                              userProvider.updateMentorTopics(_selectedTopics);
                            }
                            // Load dummy data
                            context.read<SessionProvider>().loadDummyData();
                            context.read<ProjectProvider>().loadDummyData();

                            if (!context.mounted) return;
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                builder: (_) => const HomeScreen(),
                              ),
                              (route) => false,
                            );
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      disabledBackgroundColor:
                          AppColors.primaryGreen.withValues(alpha: 0.2),
                      disabledForegroundColor:
                          AppColors.white.withValues(alpha: 0.3),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Start Learning'),
                        SizedBox(width: 8),
                        Icon(Icons.rocket_launch_rounded, size: 20),
                      ],
                    ),
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
