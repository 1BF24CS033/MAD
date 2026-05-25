import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../providers/session_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/constants.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/topic_chip.dart';

class RequestSessionScreen extends StatefulWidget {
  final String mentorId;
  final String mentorName;
  final List<String> mentorTopics;

  const RequestSessionScreen({
    super.key,
    required this.mentorId,
    required this.mentorName,
    required this.mentorTopics,
  });

  @override
  State<RequestSessionScreen> createState() => _RequestSessionScreenState();
}

class _RequestSessionScreenState extends State<RequestSessionScreen> {
  String? _selectedTopic;
  int _duration = 30;
  bool _loading = false;

  // Use mentor's topics if available, otherwise all topics
  List<String> get _topics =>
      widget.mentorTopics.isNotEmpty
          ? widget.mentorTopics
          : AppConstants.availableTopics;

  Future<void> _submit() async {
    if (_selectedTopic == null) return;
    setState(() => _loading = true);

    try {
      await context.read<SessionProvider>().requestSession(
            mentorId: widget.mentorId,
            topic: _selectedTopic!,
            durationMinutes: _duration,
          );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Session request sent to ${widget.mentorName}!'),
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
            content: Text('Failed: $e'),
            backgroundColor: Colors.red,
          ),
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
        title: Text('Request Session'),
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
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                // Mentor info card
                GlassCard(
                  borderColor: AppColors.tealAccent.withValues(alpha: 0.3),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [
                            AppColors.tealAccent,
                            AppColors.primaryGreen
                          ]),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(
                          child: Text(
                            widget.mentorName[0].toUpperCase(),
                            style: const TextStyle(
                              color: AppColors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.mentorName,
                            style: const TextStyle(
                              color: AppColors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Your mentor',
                            style: TextStyle(
                                color: AppColors.subtleText, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 400.ms),
                const SizedBox(height: 24),
                Text('Choose a topic',
                    style: Theme.of(context).textTheme.titleMedium)
                    .animate().fadeIn(delay: 100.ms),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 10,
                  children: _topics.map((topic) {
                    return TopicChip(
                      label: topic,
                      isSelected: _selectedTopic == topic,
                      onTap: () => setState(() => _selectedTopic = topic),
                    );
                  }).toList(),
                ).animate().fadeIn(delay: 150.ms),
                const SizedBox(height: 24),
                Text('Session duration',
                    style: Theme.of(context).textTheme.titleMedium)
                    .animate().fadeIn(delay: 200.ms),
                const SizedBox(height: 12),
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
                ).animate().fadeIn(delay: 250.ms),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _selectedTopic != null && !_loading
                        ? _submit
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.tealAccent,
                      disabledBackgroundColor:
                          AppColors.tealAccent.withValues(alpha: 0.2),
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: AppColors.white),
                          )
                        : const Text('Send Request'),
                  ),
                ).animate().fadeIn(delay: 300.ms),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
