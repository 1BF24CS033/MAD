import '../models/peer_work_session.dart';
import '../models/project_model.dart';
import '../models/reward_model.dart';

class DummyData {
  static final List<Map<String, dynamic>> mentors = [
    {
      'name': 'Arjun Mehta',
      'college': 'BMSCE',
      'semester': 6,
      'topics': ['Data Structures', 'Algorithms'],
      'rating': 4.8,
      'sessions': 24,
    },
    {
      'name': 'Priya Sharma',
      'college': 'BMSCE',
      'semester': 5,
      'topics': ['Machine Learning', 'Data Science'],
      'rating': 4.9,
      'sessions': 31,
    },
    {
      'name': 'Rahul Kapoor',
      'college': 'BMSCE',
      'semester': 7,
      'topics': ['Web Development', 'Cloud Computing'],
      'rating': 4.7,
      'sessions': 18,
    },
    {
      'name': 'Sneha Iyer',
      'college': 'BMSCE',
      'semester': 4,
      'topics': ['Database Systems', 'Software Engineering'],
      'rating': 4.6,
      'sessions': 15,
    },
  ];

  static final List<PeerWorkSession> sampleSessions = [
    PeerWorkSession(
      id: '1',
      topic: 'Data Structures - Trees',
      mentorName: 'Arjun Mehta',
      learnerName: 'You',
      date: DateTime.now().subtract(const Duration(days: 1)),
      durationMinutes: 45,
      pointsAwarded: 10,
      completed: true,
    ),
    PeerWorkSession(
      id: '2',
      topic: 'Machine Learning Basics',
      mentorName: 'Priya Sharma',
      learnerName: 'You',
      date: DateTime.now().subtract(const Duration(days: 3)),
      durationMinutes: 60,
      pointsAwarded: 15,
      completed: true,
    ),
    PeerWorkSession(
      id: '3',
      topic: 'SQL Optimization',
      mentorName: 'You',
      learnerName: 'Rahul Kapoor',
      date: DateTime.now().subtract(const Duration(days: 5)),
      durationMinutes: 30,
      pointsAwarded: 10,
      completed: true,
    ),
  ];

  static final List<ProjectModel> sampleProjects = [
    ProjectModel(
      id: '1',
      title: 'AI Study Companion',
      description: 'Building a chatbot that helps students review topics using spaced repetition and quizzes.',
      postedBy: 'Arjun Mehta',
      skillsRequired: ['Machine Learning', 'Mobile Development', 'UI/UX Design'],
      teamSize: 4,
      currentMembers: 2,
      postedDate: DateTime.now().subtract(const Duration(days: 2)),
    ),
    ProjectModel(
      id: '2',
      title: 'Campus Event Tracker',
      description: 'A web app for tracking hackathons, workshops, and club events across colleges.',
      postedBy: 'Sneha Iyer',
      skillsRequired: ['Web Development', 'Database Systems'],
      teamSize: 3,
      currentMembers: 1,
      postedDate: DateTime.now().subtract(const Duration(days: 4)),
    ),
    ProjectModel(
      id: '3',
      title: 'Blockchain Voting System',
      description: 'Decentralized voting system for student council elections.',
      postedBy: 'Rahul Kapoor',
      skillsRequired: ['Blockchain', 'Cyber Security', 'Web Development'],
      teamSize: 5,
      currentMembers: 3,
      postedDate: DateTime.now().subtract(const Duration(days: 7)),
    ),
  ];

  static final List<RewardModel> sampleRewards = [
    RewardModel(
      id: '1',
      title: 'Premium Notes Access',
      description: 'Get access to premium study notes for any one subject.',
      pointsCost: 50,
      iconName: 'menu_book',
    ),
    RewardModel(
      id: '2',
      title: 'Mock Test Pack',
      description: 'A set of 5 mock tests for your upcoming exams.',
      pointsCost: 100,
      iconName: 'quiz',
    ),
    RewardModel(
      id: '3',
      title: 'Certificate Badge',
      description: 'A verified mentor badge for your profile.',
      pointsCost: 200,
      iconName: 'verified',
    ),
    RewardModel(
      id: '4',
      title: 'Study Group Pass',
      description: 'Priority access to premium study groups.',
      pointsCost: 75,
      iconName: 'groups',
    ),
  ];

  static final List<String> studyHistory = [
    'Data Structures - Arrays & Linked Lists',
    'Machine Learning - Linear Regression',
    'Database Systems - Normalization',
    'Algorithms - Dynamic Programming',
    'Computer Networks - TCP/IP',
  ];
}
