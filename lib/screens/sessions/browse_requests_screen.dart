import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../providers/help_request_provider.dart';
import '../../providers/user_provider.dart';
import '../../models/help_request.dart';
import '../../theme/app_theme.dart';
import '../../utils/constants.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/search_bar_widget.dart';
import 'chat_screen.dart';

class BrowseRequestsScreen extends StatefulWidget {
  const BrowseRequestsScreen({super.key});

  @override
  State<BrowseRequestsScreen> createState() => _BrowseRequestsScreenState();
}

class _BrowseRequestsScreenState extends State<BrowseRequestsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HelpRequestProvider>();
    final userProvider = context.watch<UserProvider>();

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
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: AppColors.primaryGreen,
          labelColor: AppColors.primaryGreen,
          unselectedLabelColor: AppColors.subtleText,
          tabs: [
            const Tab(text: 'Browse'),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('My Sessions'),
                  if (provider.myAcceptedRequests.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreen,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Center(
                        child: Text(
                          '${provider.myAcceptedRequests.length}',
                          style: const TextStyle(
                              color: AppColors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.tealAccent.withValues(alpha: 0.04),
              AppColors.scaffoldBg,
            ],
          ),
        ),
        child: TabBarView(
          controller: _tabs,
          children: [
            // ── Tab 1: Browse open requests ──────────────────────────────
            _BrowseTab(provider: provider, userProvider: userProvider),
            // ── Tab 2: My accepted sessions ──────────────────────────────
            _MySessionsTab(provider: provider),
          ],
        ),
      ),
    );
  }
}

// ── Browse Tab ─────────────────────────────────────────────────────────────

class _BrowseTab extends StatelessWidget {
  final HelpRequestProvider provider;
  final UserProvider userProvider;

  const _BrowseTab(
      {required this.provider, required this.userProvider});

  @override
  Widget build(BuildContext context) {
    final requests = provider.openRequests;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
          child: Column(
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
                          color: AppColors.tealAccent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(provider.topicFilter,
                                style: const TextStyle(
                                    color: AppColors.tealAccent,
                                    fontSize: 12)),
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: () => provider.clearFilter(),
                              child: const Icon(Icons.close,
                                  size: 14, color: AppColors.tealAccent),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 10),
            ],
          ),
        ),
        Expanded(
          child: provider.loading
              ? const Center(child: CircularProgressIndicator())
              : requests.isEmpty
                  ? const _EmptyState(
                      icon: Icons.inbox_rounded,
                      message: 'No open help requests',
                      sub: 'Check back later or refresh',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                      itemCount: requests.length,
                      itemBuilder: (context, i) {
                        final req = requests[i];
                        return _OpenRequestCard(
                          request: req,
                          onAccept: () async {
                            final meetLink =
                                await provider.acceptRequest(req.id);
                            await userProvider.addMentorPoints(
                                AppConstants.pointsPerSession);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(meetLink != null
                                      ? 'Accepted! Meet link created ✓'
                                      : 'Accepted! +${AppConstants.pointsPerSession} pts'),
                                  backgroundColor: AppColors.primaryGreen,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          },
                        )
                            .animate()
                            .fadeIn(delay: (i * 60).ms)
                            .slideY(begin: 0.05);
                      },
                    ),
        ),
      ],
    );
  }
}

// ── My Sessions Tab ────────────────────────────────────────────────────────

class _MySessionsTab extends StatelessWidget {
  final HelpRequestProvider provider;
  const _MySessionsTab({required this.provider});

  @override
  Widget build(BuildContext context) {
    final sessions = provider.myAcceptedRequests;

    if (provider.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (sessions.isEmpty) {
      return const _EmptyState(
        icon: Icons.psychology_rounded,
        message: 'No active sessions',
        sub: 'Accept a request from the Browse tab',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: sessions.length,
      itemBuilder: (context, i) {
        final req = sessions[i];
        return _AcceptedSessionCard(
          request: req,
          onChat: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatScreen(
                requestId: req.id,
                otherPersonName: req.learnerName,
                topic: req.topic,
              ),
            ),
          ),
          onMarkDone: () async {
            await provider.markPendingReview(req.id);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                      'Marked as done — waiting for learner to confirm'),
                  backgroundColor: AppColors.primaryGreen,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
        )
            .animate()
            .fadeIn(delay: (i * 60).ms)
            .slideY(begin: 0.05);
      },
    );
  }
}

// ── Open Request Card ──────────────────────────────────────────────────────

class _OpenRequestCard extends StatelessWidget {
  final HelpRequest request;
  final VoidCallback onAccept;
  const _OpenRequestCard({required this.request, required this.onAccept});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderColor: AppColors.primaryGreen.withValues(alpha: 0.2),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _TopicBadge(request.topic),
              const Spacer(),
              if (request.wantsMeet)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _Badge(
                      icon: Icons.videocam_rounded,
                      label: 'Meet',
                      color: AppColors.sage),
                ),
              Text('${request.durationMinutes} min',
                  style: const TextStyle(
                      color: AppColors.subtleText, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 10),
          Text(request.description,
              style: const TextStyle(
                  color: AppColors.white, fontSize: 14, height: 1.4),
              maxLines: 3,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.person_outline,
                  size: 14, color: AppColors.subtleText),
              const SizedBox(width: 4),
              Text(request.learnerName,
                  style: const TextStyle(
                      color: AppColors.subtleText, fontSize: 12)),
              const SizedBox(width: 8),
              _Badge(
                  label: 'Sem ${request.learnerSemester}',
                  color: AppColors.peach),
              const Spacer(),
              Text(_timeAgo(request.createdAt),
                  style: const TextStyle(
                      color: AppColors.subtleText, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 14),
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

  String _timeAgo(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

// ── Accepted Session Card ──────────────────────────────────────────────────

class _AcceptedSessionCard extends StatelessWidget {
  final HelpRequest request;
  final VoidCallback onChat;
  final VoidCallback onMarkDone;
  const _AcceptedSessionCard(
      {required this.request,
      required this.onChat,
      required this.onMarkDone});

  @override
  Widget build(BuildContext context) {
    final isPendingReview = request.isPendingReview;
    final borderColor = isPendingReview
        ? AppColors.peach.withValues(alpha: 0.3)
        : AppColors.primaryGreen.withValues(alpha: 0.3);

    return GlassCard(
      borderColor: borderColor,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _TopicBadge(request.topic),
              const Spacer(),
              _Badge(
                label: isPendingReview ? 'Awaiting Confirm' : 'Accepted',
                color: isPendingReview
                    ? AppColors.peach
                    : AppColors.primaryGreen,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(request.description,
              style: const TextStyle(
                  color: AppColors.white, fontSize: 14, height: 1.4),
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.school_rounded,
                  size: 14, color: AppColors.subtleText),
              const SizedBox(width: 4),
              Text('Learner: ${request.learnerName}',
                  style: const TextStyle(
                      color: AppColors.subtleText, fontSize: 12)),
              const Spacer(),
              Text('${request.durationMinutes} min',
                  style: const TextStyle(
                      color: AppColors.subtleText, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              // Chat button
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onChat,
                  icon: const Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 15),
                  label: const Text('Chat'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.tealAccent,
                    side: BorderSide(
                        color:
                            AppColors.tealAccent.withValues(alpha: 0.5)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Mark done button (only if not already pending review)
              if (!isPendingReview)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onMarkDone,
                    icon: const Icon(Icons.check_circle_outline,
                        size: 15),
                    label: const Text('Mark Done'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Shared small widgets ───────────────────────────────────────────────────

class _TopicBadge extends StatelessWidget {
  final String topic;
  const _TopicBadge(this.topic);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.tealAccent.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: AppColors.tealAccent.withValues(alpha: 0.3)),
      ),
      child: Text(topic,
          style: const TextStyle(
              color: AppColors.tealAccent,
              fontSize: 11,
              fontWeight: FontWeight.w600)),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  const _Badge({required this.label, required this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: color),
            const SizedBox(width: 3),
          ],
          Text(label,
              style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String sub;
  const _EmptyState(
      {required this.icon, required this.message, required this.sub});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 52, color: AppColors.subtleText),
          const SizedBox(height: 12),
          Text(message,
              style: const TextStyle(color: AppColors.subtleText)),
          const SizedBox(height: 4),
          Text(sub,
              style: const TextStyle(
                  color: AppColors.subtleText, fontSize: 12)),
        ],
      ),
    );
  }
}
