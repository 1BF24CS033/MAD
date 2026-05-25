import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../providers/help_request_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_card.dart';
import 'post_help_request_screen.dart';

class MyRequestsScreen extends StatelessWidget {
  const MyRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HelpRequestProvider>();
    final requests = provider.myRequests;

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
  final request;
  final VoidCallback? onCancel;

  const _MyRequestCard({required this.request, this.onCancel});

  Color get _statusColor {
    switch (request.status) {
      case 'open':
        return AppColors.tealAccent;
      case 'accepted':
        return AppColors.primaryGreen;
      case 'completed':
        return AppColors.sage;
      default:
        return AppColors.subtleText;
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
                  request.status.toUpperCase(),
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
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '${request.durationMinutes} min',
                style: const TextStyle(
                    color: AppColors.subtleText, fontSize: 12),
              ),
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
        ],
      ),
    );
  }
}
