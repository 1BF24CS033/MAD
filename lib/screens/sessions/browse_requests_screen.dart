import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../providers/help_request_provider.dart';
import '../../providers/user_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/constants.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/search_bar_widget.dart';

class BrowseRequestsScreen extends StatelessWidget {
  const BrowseRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HelpRequestProvider>();
    final userProvider = context.watch<UserProvider>();
    final requests = provider.openRequests;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Help Requests'),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        actions: [
          IconButton(
            onPressed: () => provider.loadData(),
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
          ),
        ],
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
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SearchBarWidget(
                      hintText: 'Filter by topic...',
                      onChanged: (v) => provider.setFilter(v),
                    ).animate().fadeIn(duration: 300.ms),
                    if (provider.topicFilter.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.tealAccent
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    provider.topicFilter,
                                    style: const TextStyle(
                                        color: AppColors.tealAccent,
                                        fontSize: 12),
                                  ),
                                  const SizedBox(width: 6),
                                  GestureDetector(
                                    onTap: () => provider.clearFilter(),
                                    child: const Icon(Icons.close,
                                        size: 14,
                                        color: AppColors.tealAccent),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
              Expanded(
                child: provider.loading
                    ? const Center(child: CircularProgressIndicator())
                    : requests.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.inbox_rounded,
                                    size: 56,
                                    color: AppColors.subtleText),
                                const SizedBox(height: 12),
                                const Text(
                                  'No open help requests',
                                  style: TextStyle(
                                      color: AppColors.subtleText),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'Check back later or refresh',
                                  style: TextStyle(
                                      color: AppColors.subtleText,
                                      fontSize: 12),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 4),
                            itemCount: requests.length,
                            itemBuilder: (context, index) {
                              final req = requests[index];
                              return _RequestCard(
                                request: req,
                                onAccept: () async {
                                  await provider.acceptRequest(req.id);
                                  // Award points to mentor
                                  await userProvider.addMentorPoints(
                                      AppConstants.pointsPerSession);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            'You accepted ${req.learnerName}\'s request! +${AppConstants.pointsPerSession} pts'),
                                        backgroundColor:
                                            AppColors.primaryGreen,
                                        behavior:
                                            SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(
                                                    12)),
                                      ),
                                    );
                                  }
                                },
                              )
                                  .animate()
                                  .fadeIn(delay: (index * 80).ms)
                                  .slideY(begin: 0.05);
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final request;
  final VoidCallback onAccept;

  const _RequestCard({required this.request, required this.onAccept});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderColor: AppColors.primaryGreen.withValues(alpha: 0.2),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              // Topic badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.tealAccent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: AppColors.tealAccent.withValues(alpha: 0.3)),
                ),
                child: Text(
                  request.topic,
                  style: const TextStyle(
                    color: AppColors.tealAccent,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '${request.durationMinutes} min',
                style: const TextStyle(
                    color: AppColors.subtleText, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Description
          Text(
            request.description,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 14,
              height: 1.4,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          // Learner name + time
          Row(
            children: [
              const Icon(Icons.person_outline,
                  size: 14, color: AppColors.subtleText),
              const SizedBox(width: 4),
              Text(
                request.learnerName,
                style: const TextStyle(
                    color: AppColors.subtleText, fontSize: 12),
              ),
              const Spacer(),
              Text(
                _timeAgo(request.createdAt),
                style: const TextStyle(
                    color: AppColors.subtleText, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Accept button
          SizedBox(
            width: double.infinity,
            height: 40,
            child: ElevatedButton.icon(
              onPressed: onAccept,
              icon: const Icon(Icons.check_rounded, size: 16),
              label: const Text('Accept & Help'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen),
            ),
          ),
        ],
      ),
    );
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
