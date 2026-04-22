import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../models/project_model.dart';
import '../../providers/project_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/constants.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/topic_chip.dart';

class PostProjectScreen extends StatefulWidget {
  const PostProjectScreen({super.key});

  @override
  State<PostProjectScreen> createState() => _PostProjectScreenState();
}

class _PostProjectScreenState extends State<PostProjectScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final List<String> _selectedSkills = [];
  int _teamSize = 4;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Post a Project'),
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              // Title
              GlassCard(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: TextField(
                  controller: _titleController,
                  style: const TextStyle(color: AppColors.white),
                  decoration: const InputDecoration(
                    labelText: 'Project Title',
                    labelStyle: TextStyle(color: AppColors.subtleText),
                    prefixIcon:
                        Icon(Icons.title_rounded, color: AppColors.primaryGreen),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                ),
              ).animate().fadeIn(duration: 400.ms),
              // Description
              GlassCard(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: TextField(
                  controller: _descController,
                  style: const TextStyle(color: AppColors.white),
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    labelStyle: TextStyle(color: AppColors.subtleText),
                    prefixIcon: Icon(Icons.description_rounded,
                        color: AppColors.primaryGreen),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                ),
              ).animate().fadeIn(delay: 100.ms),
              const SizedBox(height: 8),
              // Team size
              GlassCard(
                child: Row(
                  children: [
                    const Text(
                      'Team Size',
                      style: TextStyle(color: AppColors.white, fontSize: 14),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed:
                          _teamSize > 2 ? () => setState(() => _teamSize--) : null,
                      icon: const Icon(Icons.remove_circle_outline),
                      color: AppColors.primaryGreen,
                    ),
                    Text(
                      '$_teamSize',
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    IconButton(
                      onPressed:
                          _teamSize < 10 ? () => setState(() => _teamSize++) : null,
                      icon: const Icon(Icons.add_circle_outline),
                      color: AppColors.primaryGreen,
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 200.ms),
              const SizedBox(height: 8),
              Text(
                'Skills Required',
                style: Theme.of(context).textTheme.titleMedium,
              ).animate().fadeIn(delay: 300.ms),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 10,
                children: AppConstants.availableTopics.map((topic) {
                  return TopicChip(
                    label: topic,
                    isSelected: _selectedSkills.contains(topic),
                    onTap: () {
                      setState(() {
                        if (_selectedSkills.contains(topic)) {
                          _selectedSkills.remove(topic);
                        } else {
                          _selectedSkills.add(topic);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _titleController.text.isNotEmpty &&
                          _selectedSkills.isNotEmpty
                      ? () {
                          context.read<ProjectProvider>().addProject(
                                ProjectModel(
                                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                                  title: _titleController.text,
                                  description: _descController.text,
                                  postedBy: 'You',
                                  skillsRequired: _selectedSkills,
                                  teamSize: _teamSize,
                                  postedDate: DateTime.now(),
                                ),
                              );
                          Navigator.pop(context);
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.sage,
                  ),
                  child: const Text('Post Project'),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
