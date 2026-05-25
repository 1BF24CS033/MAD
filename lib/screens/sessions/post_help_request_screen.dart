import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../providers/help_request_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/constants.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/topic_chip.dart';

class PostHelpRequestScreen extends StatefulWidget {
  const PostHelpRequestScreen({super.key});

  @override
  State<PostHelpRequestScreen> createState() =>
      _PostHelpRequestScreenState();
}

class _PostHelpRequestScreenState extends State<PostHelpRequestScreen> {
  final _descController = TextEditingController();
  String? _selectedTopic;
  int _duration = 30;
  bool _loading = false;

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selectedTopic == null) return;
    if (_descController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please describe your doubt')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      await context.read<HelpRequestProvider>().postRequest(
            topic: _selectedTopic!,
            description: _descController.text.trim(),
            durationMinutes: _duration,
          );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Help request posted! A mentor will accept it soon.'),
            backgroundColor: AppColors.primaryGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to post: $e'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Post a Help Request'),
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
              AppColors.sage.withValues(alpha: 0.05),
              AppColors.scaffoldBg,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                // Info banner
                GlassCard(
                  borderColor: AppColors.tealAccent.withValues(alpha: 0.3),
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded,
                          color: AppColors.tealAccent, size: 20),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Post your doubt and a mentor will accept your request to help you.',
                          style: TextStyle(
                              color: AppColors.subtleText, fontSize: 12, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 300.ms),
                const SizedBox(height: 24),

                // Topic selection
                Text('What subject do you need help with?',
                    style: Theme.of(context).textTheme.titleMedium)
                    .animate().fadeIn(delay: 100.ms),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 10,
                  children: AppConstants.availableTopics.map((topic) {
                    return TopicChip(
                      label: topic,
                      isSelected: _selectedTopic == topic,
                      onTap: () => setState(() => _selectedTopic = topic),
                    );
                  }).toList(),
                ).animate().fadeIn(delay: 150.ms),
                const SizedBox(height: 24),

                // Description
                Text('Describe your doubt',
                    style: Theme.of(context).textTheme.titleMedium)
                    .animate().fadeIn(delay: 200.ms),
                const SizedBox(height: 10),
                GlassCard(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 4, vertical: 2),
                  child: TextField(
                    controller: _descController,
                    maxLines: 4,
                    style: const TextStyle(color: AppColors.white),
                    decoration: const InputDecoration(
                      hintText:
                          'e.g. I don\'t understand how recursion works in trees...',
                      hintStyle: TextStyle(
                          color: AppColors.subtleText, fontSize: 13),
                      prefixIcon: Padding(
                        padding: EdgeInsets.only(bottom: 60),
                        child: Icon(Icons.edit_note_rounded,
                            color: AppColors.primaryGreen),
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                  ),
                ).animate().fadeIn(delay: 250.ms),
                const SizedBox(height: 20),

                // Duration
                Text('How long do you need?',
                    style: Theme.of(context).textTheme.titleMedium)
                    .animate().fadeIn(delay: 300.ms),
                const SizedBox(height: 10),
                GlassCard(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: _duration > 15
                            ? () => setState(() => _duration -= 15)
                            : null,
                        icon: const Icon(Icons.remove_circle_outline),
                        color: AppColors.primaryGreen,
                      ),
                      Text(
                        '$_duration min',
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      IconButton(
                        onPressed: _duration < 120
                            ? () => setState(() => _duration += 15)
                            : null,
                        icon: const Icon(Icons.add_circle_outline),
                        color: AppColors.primaryGreen,
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 350.ms),
                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: _selectedTopic != null && !_loading
                        ? _submit
                        : null,
                    icon: _loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.white))
                        : const Icon(Icons.send_rounded, size: 18),
                    label: const Text('Post Help Request'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      disabledBackgroundColor:
                          AppColors.primaryGreen.withValues(alpha: 0.2),
                    ),
                  ),
                ).animate().fadeIn(delay: 400.ms),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
