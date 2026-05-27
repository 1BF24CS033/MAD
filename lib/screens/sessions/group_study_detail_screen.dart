import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../models/help_request.dart';
import '../../providers/help_request_provider.dart';
import '../../services/help_request_service.dart';
import '../../services/supabase_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_card.dart';

class GroupStudyDetailScreen extends StatefulWidget {
  final HelpRequest study;

  const GroupStudyDetailScreen({super.key, required this.study});

  @override
  State<GroupStudyDetailScreen> createState() =>
      _GroupStudyDetailScreenState();
}

class _GroupStudyDetailScreenState extends State<GroupStudyDetailScreen> {
  List<Map<String, dynamic>> _members = [];
  bool _hasJoined = false;
  bool _loading = true;
  bool _joining = false;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    final userId = SupabaseService.currentUserId ?? '';
    final members =
        await HelpRequestService.fetchGroupMembers(widget.study.id);
    final joined =
        await HelpRequestService.hasJoinedGroupStudy(widget.study.id, userId);
    if (mounted) {
      setState(() {
        _members = members;
        _hasJoined = joined;
        _loading = false;
      });
    }
  }

  Future<void> _join() async {
    setState(() => _joining = true);
    try {
      await context
          .read<HelpRequestProvider>()
          .joinGroupStudy(widget.study.id);
      await _loadMembers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('You joined the group study! 🎉'),
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
              content: Text('Failed to join: $e'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _joining = false);
    }
  }

  Future<void> _leave() async {
    await context
        .read<HelpRequestProvider>()
        .leaveGroupStudy(widget.study.id);
    await _loadMembers();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You left the group study')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final study = widget.study;
    final spotsLeft =
        study.maxParticipants - _members.length;
    final isCreator = study.learnerId == SupabaseService.currentUserId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Group Study'),
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
              AppColors.sage.withValues(alpha: 0.06),
              AppColors.scaffoldBg,
            ],
          ),
        ),
        child: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Topic + status
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color:
                                  AppColors.sage.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: AppColors.sage
                                      .withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              study.topic,
                              style: const TextStyle(
                                color: AppColors.sage,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: spotsLeft > 0
                                  ? AppColors.primaryGreen
                                      .withValues(alpha: 0.15)
                                  : AppColors.peach
                                      .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              spotsLeft > 0
                                  ? '$spotsLeft spots left'
                                  : 'Full',
                              style: TextStyle(
                                color: spotsLeft > 0
                                    ? AppColors.primaryGreen
                                    : AppColors.peach,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ).animate().fadeIn(duration: 300.ms),
                      const SizedBox(height: 20),

                      // Description
                      GlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'About this study',
                              style: TextStyle(
                                color: AppColors.subtleText,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              study.description,
                              style: const TextStyle(
                                color: AppColors.white,
                                fontSize: 14,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Icon(Icons.person_outline,
                                    size: 14,
                                    color: AppColors.subtleText),
                                const SizedBox(width: 4),
                                Text(
                                  'Created by ${study.learnerName}',
                                  style: const TextStyle(
                                      color: AppColors.subtleText,
                                      fontSize: 12),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.peach
                                        .withValues(alpha: 0.15),
                                    borderRadius:
                                        BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'Sem ${study.learnerSemester}',
                                    style: const TextStyle(
                                      color: AppColors.peach,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: 100.ms),
                      const SizedBox(height: 20),

                      // Members
                      Text(
                        'Members (${_members.length}/${study.maxParticipants})',
                        style: Theme.of(context).textTheme.titleLarge,
                      ).animate().fadeIn(delay: 200.ms),
                      const SizedBox(height: 12),
                      ..._members.asMap().entries.map((entry) {
                        final m = entry.value;
                        final profile =
                            m['profile'] as Map<String, dynamic>?;
                        final name =
                            profile?['name'] as String? ?? 'Unknown';
                        final email = profile?['email'] as String?;
                        final semester =
                            profile?['semester'] as int? ?? 1;

                        return GlassCard(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.sage,
                                      AppColors.primaryGreen
                                    ],
                                  ),
                                  borderRadius:
                                      BorderRadius.circular(10),
                                ),
                                child: Center(
                                  child: Text(
                                    name[0].toUpperCase(),
                                    style: const TextStyle(
                                      color: AppColors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: const TextStyle(
                                        color: AppColors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      'Sem $semester',
                                      style: const TextStyle(
                                        color: AppColors.subtleText,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (email != null && (_hasJoined || isCreator))
                                GestureDetector(
                                  onTap: () {
                                    Clipboard.setData(
                                        ClipboardData(text: email));
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            'Copied $email'),
                                        duration: const Duration(
                                            seconds: 1),
                                        behavior:
                                            SnackBarBehavior.floating,
                                      ),
                                    );
                                  },
                                  child: Container(
                                    padding:
                                        const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.tealAccent
                                          .withValues(alpha: 0.15),
                                      borderRadius:
                                          BorderRadius.circular(6),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.email_outlined,
                                            size: 12,
                                            color:
                                                AppColors.tealAccent),
                                        SizedBox(width: 4),
                                        Text(
                                          'Email',
                                          style: TextStyle(
                                            color:
                                                AppColors.tealAccent,
                                            fontSize: 10,
                                            fontWeight:
                                                FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        )
                            .animate()
                            .fadeIn(delay: (250 + entry.key * 60).ms)
                            .slideX(begin: 0.05);
                      }),

                      const SizedBox(height: 24),

                      // Join / Leave button
                      if (!isCreator)
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: _hasJoined
                              ? OutlinedButton.icon(
                                  onPressed: _leave,
                                  icon: const Icon(
                                      Icons.exit_to_app_rounded,
                                      size: 18),
                                  label: const Text('Leave Group'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.red.shade300,
                                    side: BorderSide(
                                        color: Colors.red.shade300
                                            .withValues(alpha: 0.4)),
                                  ),
                                )
                              : ElevatedButton.icon(
                                  onPressed: spotsLeft > 0 && !_joining
                                      ? _join
                                      : null,
                                  icon: _joining
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child:
                                              CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color:
                                                      AppColors.white))
                                      : const Icon(
                                          Icons.group_add_rounded,
                                          size: 18),
                                  label: Text(spotsLeft > 0
                                      ? 'Join Group Study'
                                      : 'Group is Full'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.sage,
                                    disabledBackgroundColor:
                                        AppColors.sage
                                            .withValues(alpha: 0.2),
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
