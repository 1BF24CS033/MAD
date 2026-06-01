import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../models/project_model.dart';
import '../../providers/project_provider.dart';
import '../../services/supabase_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_card.dart';
import '../sessions/group_chat_screen.dart';

class ProjectDetailScreen extends StatefulWidget {
  final ProjectModel project;

  const ProjectDetailScreen({super.key, required this.project});

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  List<Map<String, dynamic>> _members = [];
  bool _loading = true;
  bool _hasJoined = false;
  bool _joining = false;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    final db = SupabaseService.client;
    final userId = SupabaseService.currentUserId ?? '';

    try {
      final rows = await db
          .from('project_members')
          .select(
              'user_id, joined_at, profile:profiles!project_members_user_id_fkey(name, semester, topics_of_interest)')
          .eq('project_id', widget.project.id)
          .order('joined_at');

      final joined = rows
          .cast<Map<String, dynamic>>()
          .any((r) => r['user_id'] == userId);

      if (mounted) {
        setState(() {
          _members = rows.cast<Map<String, dynamic>>();
          _hasJoined = joined;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _join() async {
    setState(() => _joining = true);
    try {
      await context.read<ProjectProvider>().joinProject(widget.project.id);
      await _loadMembers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Joined "${widget.project.title}" 🎉'),
            backgroundColor: AppColors.primaryGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().contains('already')
                ? 'You already joined this project'
                : 'Could not join: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _joining = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final project = widget.project;
    final spotsLeft = project.teamSize - project.currentMembers;
    final isOwner = project.postedById == SupabaseService.currentUserId;

    return Scaffold(
      appBar: AppBar(
        title: Text(project.title,
            overflow: TextOverflow.ellipsis),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        actions: [
          // Chat button in app bar
          if (_hasJoined || isOwner)
            IconButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => GroupChatScreen(
                    roomId: project.id,
                    roomType: 'project',
                    title: project.title,
                    subtitle: 'Project Chat',
                  ),
                ),
              ),
              icon: const Icon(Icons.chat_bubble_outline_rounded),
              tooltip: 'Project Chat',
            ),
        ],
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
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Project info ─────────────────────────────────
                      GlassCard(
                        borderColor:
                            AppColors.sage.withValues(alpha: 0.3),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(project.title,
                                      style: const TextStyle(
                                          color: AppColors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700)),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: spotsLeft > 0
                                        ? AppColors.sage
                                            .withValues(alpha: 0.2)
                                        : AppColors.peach
                                            .withValues(alpha: 0.2),
                                    borderRadius:
                                        BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    spotsLeft > 0
                                        ? '$spotsLeft spots left'
                                        : 'Full',
                                    style: TextStyle(
                                        color: spotsLeft > 0
                                            ? AppColors.sage
                                            : AppColors.peach,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(project.description,
                                style: const TextStyle(
                                    color: AppColors.subtleText,
                                    fontSize: 13,
                                    height: 1.5)),
                            const SizedBox(height: 14),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: project.skillsRequired
                                  .map((s) => Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: AppColors.tealAccent
                                              .withValues(alpha: 0.15),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          border: Border.all(
                                              color: AppColors.tealAccent
                                                  .withValues(alpha: 0.3)),
                                        ),
                                        child: Text(s,
                                            style: const TextStyle(
                                                color: AppColors.tealAccent,
                                                fontSize: 11,
                                                fontWeight:
                                                    FontWeight.w500)),
                                      ))
                                  .toList(),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                const Icon(Icons.person_outline,
                                    size: 14,
                                    color: AppColors.subtleText),
                                const SizedBox(width: 4),
                                Text('Posted by ${project.postedBy}',
                                    style: const TextStyle(
                                        color: AppColors.subtleText,
                                        fontSize: 12)),
                              ],
                            ),
                          ],
                        ),
                      ).animate().fadeIn(duration: 300.ms),

                      const SizedBox(height: 24),

                      // ── Members ──────────────────────────────────────
                      Text(
                        'Team Members (${_members.length}/${project.teamSize})',
                        style: Theme.of(context).textTheme.titleLarge,
                      ).animate().fadeIn(delay: 150.ms),
                      const SizedBox(height: 12),

                      if (_members.isEmpty)
                        GlassCard(
                          child: const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(
                              child: Text('No members yet',
                                  style: TextStyle(
                                      color: AppColors.subtleText)),
                            ),
                          ),
                        )
                      else
                        ..._members.asMap().entries.map((entry) {
                          final m = entry.value;
                          final profile =
                              m['profile'] as Map<String, dynamic>?;
                          final name =
                              profile?['name'] as String? ?? 'Unknown';
                          final semester =
                              profile?['semester'] as int? ?? 1;
                          final topics = List<String>.from(
                              profile?['topics_of_interest'] ?? []);
                          final userId = m['user_id'] as String;
                          final isCurrentUser =
                              userId == SupabaseService.currentUserId;

                          return GlassCard(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                // Avatar
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(colors: [
                                      AppColors.primaryGreen,
                                      AppColors.tealAccent,
                                    ]),
                                    borderRadius:
                                        BorderRadius.circular(12),
                                  ),
                                  child: Center(
                                    child: Text(
                                      name[0].toUpperCase(),
                                      style: const TextStyle(
                                          color: AppColors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            isCurrentUser
                                                ? '$name (You)'
                                                : name,
                                            style: const TextStyle(
                                                color: AppColors.white,
                                                fontWeight:
                                                    FontWeight.w600,
                                                fontSize: 14),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 3),
                                      Text('Semester $semester',
                                          style: const TextStyle(
                                              color: AppColors.subtleText,
                                              fontSize: 12)),
                                      if (topics.isNotEmpty) ...[
                                        const SizedBox(height: 6),
                                        Wrap(
                                          spacing: 4,
                                          runSpacing: 4,
                                          children: topics
                                              .take(3)
                                              .map((t) => Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 7,
                                                        vertical: 2),
                                                    decoration:
                                                        BoxDecoration(
                                                      color: AppColors
                                                          .tealAccent
                                                          .withValues(
                                                              alpha: 0.12),
                                                      borderRadius:
                                                          BorderRadius
                                                              .circular(6),
                                                    ),
                                                    child: Text(t,
                                                        style: const TextStyle(
                                                            color: AppColors
                                                                .tealAccent,
                                                            fontSize: 10)),
                                                  ))
                                              .toList(),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          )
                              .animate()
                              .fadeIn(delay: (200 + entry.key * 60).ms)
                              .slideX(begin: 0.05);
                        }),

                      const SizedBox(height: 24),

                      // ── Actions ──────────────────────────────────────
                      if (_hasJoined || isOwner) ...[
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton.icon(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => GroupChatScreen(
                                  roomId: project.id,
                                  roomType: 'project',
                                  title: project.title,
                                  subtitle: 'Project Chat',
                                ),
                              ),
                            ),
                            icon: const Icon(
                                Icons.chat_bubble_outline_rounded,
                                size: 18),
                            label: const Text('Open Project Chat'),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.tealAccent),
                          ),
                        ).animate().fadeIn(delay: 350.ms),
                      ] else if (spotsLeft > 0) ...[
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton.icon(
                            onPressed: _joining ? null : _join,
                            icon: _joining
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.white))
                                : const Icon(Icons.group_add_rounded,
                                    size: 18),
                            label: const Text('Join Project'),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryGreen),
                          ),
                        ).animate().fadeIn(delay: 350.ms),
                      ] else ...[
                        GlassCard(
                          child: const Center(
                            child: Padding(
                              padding: EdgeInsets.all(12),
                              child: Text('Project is full',
                                  style: TextStyle(
                                      color: AppColors.subtleText)),
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
