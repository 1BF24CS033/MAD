import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/review_service.dart';
import '../../services/supabase_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_card.dart';

class ReviewScreen extends StatefulWidget {
  final String requestId;
  final String mentorId;
  final String mentorName;
  final String topic;

  const ReviewScreen({
    super.key,
    required this.requestId,
    required this.mentorId,
    required this.mentorName,
    required this.topic,
  });

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  int _rating = 0;
  final _commentController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a rating')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final userId = SupabaseService.currentUserId!;
      await ReviewService.submitReview(
        requestId: widget.requestId,
        reviewerId: userId,
        mentorId: widget.mentorId,
        rating: _rating,
        comment: _commentController.text.trim(),
      );

      if (mounted) {
        // Pop back to my requests
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Review submitted! Thank you 🎉'),
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
            content: Text('Failed to submit review: $e'),
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
        title: const Text('Leave a Review'),
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
              AppColors.peach.withValues(alpha: 0.05),
              AppColors.scaffoldBg,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 32),
                // Mentor avatar
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.tealAccent, AppColors.primaryGreen],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Text(
                      widget.mentorName[0].toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ).animate().fadeIn(duration: 400.ms).scale(
                    begin: const Offset(0.8, 0.8)),
                const SizedBox(height: 16),
                Text(
                  'How was your session with',
                  style: Theme.of(context).textTheme.bodyMedium,
                ).animate().fadeIn(delay: 100.ms),
                Text(
                  '${widget.mentorName}?',
                  style: Theme.of(context).textTheme.displayMedium,
                ).animate().fadeIn(delay: 150.ms),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.tealAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    widget.topic,
                    style: const TextStyle(
                        color: AppColors.tealAccent, fontSize: 12),
                  ),
                ).animate().fadeIn(delay: 200.ms),
                const SizedBox(height: 32),

                // Star rating
                GlassCard(
                  child: Column(
                    children: [
                      const Text(
                        'Rate your experience',
                        style: TextStyle(
                            color: AppColors.subtleText, fontSize: 14),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (index) {
                          final starNum = index + 1;
                          return GestureDetector(
                            onTap: () =>
                                setState(() => _rating = starNum),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.all(6),
                              child: Icon(
                                starNum <= _rating
                                    ? Icons.star_rounded
                                    : Icons.star_outline_rounded,
                                color: starNum <= _rating
                                    ? AppColors.peach
                                    : AppColors.subtleText,
                                size: 40,
                              ),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 8),
                      if (_rating > 0)
                        Text(
                          _ratingText,
                          style: TextStyle(
                            color: AppColors.peach,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ).animate().fadeIn(delay: 300.ms),
                const SizedBox(height: 20),

                // Comment
                GlassCard(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 4, vertical: 2),
                  child: TextField(
                    controller: _commentController,
                    maxLines: 4,
                    style: const TextStyle(color: AppColors.white),
                    decoration: const InputDecoration(
                      hintText:
                          'Share your experience... (optional)',
                      hintStyle: TextStyle(
                          color: AppColors.subtleText, fontSize: 13),
                      prefixIcon: Padding(
                        padding: EdgeInsets.only(bottom: 60),
                        child: Icon(Icons.rate_review_outlined,
                            color: AppColors.primaryGreen),
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                  ),
                ).animate().fadeIn(delay: 400.ms),
                const SizedBox(height: 32),

                // Submit
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: _rating > 0 && !_loading ? _submit : null,
                    icon: _loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.white))
                        : const Icon(Icons.send_rounded, size: 18),
                    label: const Text('Submit Review'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      disabledBackgroundColor:
                          AppColors.primaryGreen.withValues(alpha: 0.2),
                    ),
                  ),
                ).animate().fadeIn(delay: 500.ms),

                // Skip
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Skip for now',
                    style: TextStyle(color: AppColors.subtleText),
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

  String get _ratingText {
    switch (_rating) {
      case 1:
        return 'Poor';
      case 2:
        return 'Below Average';
      case 3:
        return 'Good';
      case 4:
        return 'Very Good';
      case 5:
        return 'Excellent!';
      default:
        return '';
    }
  }
}
