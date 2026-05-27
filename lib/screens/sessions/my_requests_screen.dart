import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../providers/help_request_provider.dart';
import '../../models/help_request.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_card.dart';
import 'post_help_request_screen.dart';
import 'review_screen.dart';

class MyRequestsScreen extends StatelessWidget {
  const MyRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HelpRequestProvider>();
    final requests = provider.myHelpRequests;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Help Requests'),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        actions: [
          IconButton(
            onPressed: () => provider.loadData(),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const PostHelpRequestScreen()),
          );
        },
        backgroundColor: AppColors.primaryGreen,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Request'),
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
          child: provider.loading
              ? const Center(child: CircularProgressIndicator())
              : requests.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.help_outline_rounded,
                              size: 56, color: AppColors.subtleText),
                          const SizedBox(height: 12),
                          const Text(
                            'No help requests yet',
                            style:
                                TextStyle(color: AppColors.subtleText),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      const PostHelpRequestScreen()),
                            ),
                            icon: const Icon(Icons.add_rounded, size: 16),
                            label: const Text('Post a Request'),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryGreen),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: requests.length,
                      itemBuilder: (context, index) {
                        final req = requests[index];
                        return _MyRequestCard(
                          request: req,
                          onCancel: req.isOpen
                              ? () async {
                                  await provider.cancelRequest(req.id);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(
                                      const SnackBar(
                                          content:
                                              Text('Request cancelled')),
                                    );
                                  }
                                }
                              : null,
                          onShareEmail: req.isAccepted && !req.emailShared
                              ? () async {
                                  await provider.shareEmail(req.id);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            'Email shared with your mentor'),
                                        backgroundColor:
                                            AppColors.primaryGreen,
                                      ),
                                    );
                                  }
                                }
                              : null,
                          onConfirmComplete: req.isPendingReview
                              ? () async {
                                  await provider.confirmComplete(req.id);
                                  if (context.mounted) {
                                    // Navigate to review screen
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ReviewScreen(
                                          requestId: req.id,
                                          mentorId: req.mentorId!,
                                          mentorName:
                                              req.mentorName ?? 'Mentor',
                                          topic: req.topic,
                                        ),
                                      ),
                                    );
                                  }
                                }
                              : null,
                        )
                            .animate()
                            .fadeIn(delay: (index * 80).ms)
                            .slideY(begin: 0.05);
                      },
                    ),
        ),
      ),
    );
  }
}

class _MyRequestCard extends StatelessWidget {
  final HelpRequest request;
  final VoidCallback? onCancel;
  final VoidCallback? onShareEmail;
  final VoidCallback? onConfirmComplete;

  const _MyRequestCard({
    required this.request,
    this.onCancel,
    this.onShareEmail,
    this.onConfirmComplete,
  });

  Color get _statusColor {
    switch (request.status) {
      case 'open':
        return AppColors.tealAccent;
      case 'accepted':
        return AppColors.primaryGreen;
      case 'pending_review':
        return AppColors.peach;
      case 'completed':
        return AppColors.sage;
      default:
        return AppColors.subtleText;
    }
  }

  String get _statusText {
    switch (request.status) {
      case 'pending_review':
        return 'AWAITING YOUR REVIEW';
      default:
        return request.status.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderColor: _statusColor.withValues(alpha: 0.25),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _statusText,
                  style: TextStyle(
                    color: _statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                request.topic,
                style: const TextStyle(
                    color: AppColors.subtleText, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            request.description,
            style: const TextStyle(
                color: AppColors.white, fontSize: 14, height: 1.4),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          if (request.mentorName != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.psychology_rounded,
                    size: 14, color: AppColors.primaryGreen),
                const SizedBox(width: 4),
                Text(
                  'Accepted by ${request.mentorName}',
                  style: const TextStyle(
                      color: AppColors.primaryGreen, fontSize: 12),
                ),
              ],
            ),
          ],
          // Email shared / Meet link section
          if (request.isAccepted || request.isPendingReview || request.isCompleted) ...[
            const SizedBox(height: 8),
            if (request.emailShared && request.mentorEmail != null)
              _ContactRow(
                icon: Icons.email_outlined,
                label: 'Mentor: ${request.mentorEmail}',
                email: request.mentorEmail!,
              ),
            if (request.meetLink != null)
              _ContactRow(
                icon: Icons.videocam_rounded,
                label: 'Google Meet link',
                email: request.meetLink!,
                isMeetLink: true,
              ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '${request.durationMinutes} min',
                style: const TextStyle(
                    color: AppColors.subtleText, fontSize: 12),
              ),
              if (request.wantsMeet) ...[
                const SizedBox(width: 8),
                const Icon(Icons.videocam_rounded,
                    size: 14, color: AppColors.sage),
              ],
              const Spacer(),
              if (onCancel != null)
                TextButton(
                  onPressed: onCancel,
                  style: TextButton.styleFrom(
                      foregroundColor: Colors.red.shade300),
                  child: const Text('Cancel', style: TextStyle(fontSize: 12)),
                ),
            ],
          ),
          // Action buttons
          if (onShareEmail != null) ...[
            const Divider(color: AppColors.glassBorder, height: 20),
            SizedBox(
              width: double.infinity,
              height: 40,
              child: OutlinedButton.icon(
                onPressed: onShareEmail,
                icon: const Icon(Icons.mail_outline_rounded, size: 16),
                label: const Text('Share My Email with Mentor'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.tealAccent,
                  side: BorderSide(
                      color: AppColors.tealAccent.withValues(alpha: 0.4)),
                ),
              ),
            ),
          ],
          if (onConfirmComplete != null) ...[
            const Divider(color: AppColors.glassBorder, height: 20),
            const Text(
              'Your mentor marked this as done. Please confirm:',
              style: TextStyle(color: AppColors.subtleText, fontSize: 12),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                onPressed: onConfirmComplete,
                icon: const Icon(Icons.check_circle_outline, size: 18),
                label: const Text('Confirm & Leave Review'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String email;
  final bool isMeetLink;

  const _ContactRow({
    required this.icon,
    required this.label,
    required this.email,
    this.isMeetLink = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        if (isMeetLink) {
          // Open Meet link in browser
          final uri = Uri.tryParse(email);
          if (uri != null && await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          } else {
            // Fallback: copy to clipboard
            Clipboard.setData(ClipboardData(text: email));
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Meet link copied!'),
                  behavior: SnackBarBehavior.floating,
                  duration: Duration(seconds: 1),
                ),
              );
            }
          }
        } else {
          Clipboard.setData(ClipboardData(text: email));
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Email copied!'),
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 1),
              ),
            );
          }
        }
      },
      onLongPress: () {
        Clipboard.setData(ClipboardData(text: email));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isMeetLink ? 'Meet link copied!' : 'Email copied!'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 1),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isMeetLink
              ? AppColors.sage.withValues(alpha: 0.1)
              : AppColors.tealAccent.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 14,
                color:
                    isMeetLink ? AppColors.sage : AppColors.tealAccent),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                    color: isMeetLink
                        ? AppColors.sage
                        : AppColors.tealAccent,
                    fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
                isMeetLink
                    ? Icons.open_in_new_rounded
                    : Icons.copy_rounded,
                size: 14,
                color: AppColors.subtleText),
          ],
        ),
      ),
    );
  }
}
