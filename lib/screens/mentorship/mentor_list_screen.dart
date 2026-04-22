import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_theme.dart';
import '../../utils/dummy_data.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/search_bar_widget.dart';
import 'mentor_opt_in_screen.dart';

class MentorListScreen extends StatefulWidget {
  const MentorListScreen({super.key});

  @override
  State<MentorListScreen> createState() => _MentorListScreenState();
}

class _MentorListScreenState extends State<MentorListScreen> {
  String _searchQuery = '';
  String? _semesterFilter;
  String? _subjectFilter;

  static const List<String> _cseSubjects = [
    'Data Structures',
    'Algorithms',
    'Operating Systems',
    'Database Systems',
    'Computer Networks',
    'Machine Learning',
    'Software Engineering',
    'Web Development',
    'Cloud Computing',
    'Cyber Security',
    'Discrete Mathematics',
    'Computer Architecture',
    'Object Oriented Programming',
    'Compiler Design',
    'Theory of Computation',
    'Artificial Intelligence',
    'Data Science',
    'Digital Logic Design',
  ];

  List<Map<String, dynamic>> get _filteredMentors {
    return DummyData.mentors.where((m) {
      final matchesSearch = _searchQuery.isEmpty ||
          m['name'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (m['topics'] as List).any(
              (t) => t.toLowerCase().contains(_searchQuery.toLowerCase()));
      final matchesSem = _semesterFilter == null ||
          m['semester'].toString() == _semesterFilter;
      final matchesSubject = _subjectFilter == null ||
          (m['topics'] as List)
              .any((t) => t.toLowerCase().contains(_subjectFilter!.toLowerCase()));
      return matchesSearch && matchesSem && matchesSubject;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              // Search
              SearchBarWidget(
                onChanged: (v) => setState(() => _searchQuery = v),
              ).animate().fadeIn(duration: 400.ms),
              const SizedBox(height: 14),
              // Filters
              Row(
                children: [
                  // Semester Dropdown
                  Expanded(
                    child: GlassCard(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                      margin: EdgeInsets.zero,
                      child: DropdownButtonFormField<String>(
                        value: _semesterFilter,
                        isExpanded: true,
                        dropdownColor: AppColors.cardBg,
                        icon: const Icon(Icons.arrow_drop_down, color: AppColors.primaryGreen),
                        style: const TextStyle(color: AppColors.white, fontSize: 14),
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.primaryGreen),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 12),
                          filled: false,
                        ),
                        hint: const Text(
                          'All Semesters',
                          style: TextStyle(color: AppColors.subtleText, fontSize: 13),
                        ),
                        items: [
                          const DropdownMenuItem<String>(
                            value: null,
                            child: Text('All Semesters', style: TextStyle(color: AppColors.subtleText)),
                          ),
                          ...List.generate(8, (i) {
                            final sem = '${i + 1}';
                            return DropdownMenuItem<String>(
                              value: sem,
                              child: Text('Semester $sem'),
                            );
                          }),
                        ],
                        onChanged: (v) => setState(() => _semesterFilter = v),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Subject Dropdown
                  Expanded(
                    child: GlassCard(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                      margin: EdgeInsets.zero,
                      child: DropdownButtonFormField<String>(
                        value: _subjectFilter,
                        isExpanded: true,
                        dropdownColor: AppColors.cardBg,
                        icon: const Icon(Icons.arrow_drop_down, color: AppColors.primaryGreen),
                        style: const TextStyle(color: AppColors.white, fontSize: 14),
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.menu_book_rounded, size: 18, color: AppColors.primaryGreen),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 12),
                          filled: false,
                        ),
                        hint: const Text(
                          'All Subjects',
                          style: TextStyle(color: AppColors.subtleText, fontSize: 13),
                        ),
                        items: [
                          const DropdownMenuItem<String>(
                            value: null,
                            child: Text('All Subjects', style: TextStyle(color: AppColors.subtleText)),
                          ),
                          ..._cseSubjects.map((subject) {
                            return DropdownMenuItem<String>(
                              value: subject,
                              child: Text(subject, overflow: TextOverflow.ellipsis),
                            );
                          }),
                        ],
                        onChanged: (v) => setState(() => _subjectFilter = v),
                      ),
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 100.ms),
              const SizedBox(height: 20),
              // Mentor Grid
              Expanded(
                child: _filteredMentors.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.search_off_rounded, size: 48, color: AppColors.subtleText),
                            const SizedBox(height: 12),
                            const Text(
                              'No mentors found',
                              style: TextStyle(color: AppColors.subtleText),
                            ),
                          ],
                        ),
                      )
                    : GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.85,
                        ),
                        itemCount: _filteredMentors.length,
                        itemBuilder: (context, index) {
                          final mentor = _filteredMentors[index];
                          return _MentorCard(mentor: mentor)
                              .animate()
                              .fadeIn(delay: (200 + index * 100).ms)
                              .scale(begin: const Offset(0.95, 0.95));
                        },
                      ),
              ),
              // Opt-in FAB
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const MentorOptInScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.volunteer_activism_rounded, size: 20),
                    label: const Text('Become a Mentor'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.tealAccent,
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2),
            ],
          ),
        ),
      ),
    );
  }
}

class _MentorCard extends StatelessWidget {
  final Map<String, dynamic> mentor;

  const _MentorCard({required this.mentor});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      margin: EdgeInsets.zero,
      borderColor: AppColors.tealAccent.withValues(alpha: 0.2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.tealAccent, AppColors.primaryGreen],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                mentor['name'][0],
                style: const TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            mentor['name'],
            style: const TextStyle(
              color: AppColors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            'Sem ${mentor['semester']}',
            style: const TextStyle(
              color: AppColors.subtleText,
              fontSize: 11,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          // Rating
          Row(
            children: [
              const Icon(Icons.star_rounded, size: 14, color: AppColors.peach),
              const SizedBox(width: 4),
              Text(
                '${mentor['rating']}',
                style: const TextStyle(
                  color: AppColors.peach,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              Text(
                '${mentor['sessions']} sessions',
                style: const TextStyle(
                  color: AppColors.subtleText,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Topics
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: (mentor['topics'] as List<String>)
                .take(2)
                .map((t) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.sage.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        t,
                        style: const TextStyle(
                          color: AppColors.sage,
                          fontSize: 9,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}
