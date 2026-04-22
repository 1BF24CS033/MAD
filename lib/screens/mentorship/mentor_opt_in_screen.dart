import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/constants.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/topic_chip.dart';

class MentorOptInScreen extends StatefulWidget {
  const MentorOptInScreen({super.key});

  @override
  State<MentorOptInScreen> createState() => _MentorOptInScreenState();
}

class _MentorOptInScreenState extends State<MentorOptInScreen> {
  final List<String> _selectedTopics = [];

  @override
  void initState() {
    super.initState();
    final user = context.read<UserProvider>().user;
    _selectedTopics.addAll(user.mentorTopics);
  }

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
    final userProvider = context.watch<UserProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Become a Mentor'),
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              // Info card
              GlassCard(
                borderColor: AppColors.peach.withValues(alpha: 0.3),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.peach.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.volunteer_activism_rounded,
                        color: AppColors.peach,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Earn MentorPoints',
                            style: TextStyle(
                              color: AppColors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Help peers and earn 10 points per session. Redeem them in the Rewards Store!',
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
              ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),
              const SizedBox(height: 24),
              Text(
                'Choose topics you can mentor',
                style: Theme.of(context).textTheme.titleMedium,
              ).animate().fadeIn(delay: 200.ms),
              const SizedBox(height: 16),
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
              // Save button
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _selectedTopics.isNotEmpty
                        ? () {
                            userProvider.updateMentorTopics(_selectedTopics);
                            if (!userProvider.user.isMentor) {
                              userProvider.toggleRole();
                            }
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text(
                                  'You\'re now a mentor! 🎉',
                                  style: TextStyle(color: AppColors.white),
                                ),
                                backgroundColor: AppColors.primaryGreen,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            );
                            Navigator.pop(context);
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.tealAccent,
                      disabledBackgroundColor:
                          AppColors.tealAccent.withValues(alpha: 0.2),
                    ),
                    child: Text(
                      _selectedTopics.isEmpty
                          ? 'Select at least one topic'
                          : 'Opt-in as Mentor (${_selectedTopics.length} topics)',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
