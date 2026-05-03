import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../quiz/cubit/quiz_cubit.dart';
import '../quiz/quiz_screen.dart';
import '../leaderboard/leaderboard_screen.dart';
import '../learning/learning_screen.dart';

import 'cubit/home_cubit.dart';
import 'cubit/home_state.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  IconData _badgeIcon(String badge) {
    if (badge.contains("Rookie")) return Icons.shield;
    if (badge.contains("Beginner")) return Icons.security;
    if (badge.contains("Intermediate")) return Icons.workspace_premium;
    if (badge.contains("Hero")) return Icons.emoji_events;
    if (badge.contains("Consistent")) return Icons.local_fire_department;
    return Icons.star;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text("CyberBuddy"),
        backgroundColor: const Color(0xFF0D1B3E),
        foregroundColor: Colors.white,
      ),
      body: BlocBuilder<HomeCubit, HomeState>(
        builder: (context, state) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D1B3E),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Welcome back 👋",
                              style: TextStyle(color: Colors.white70),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Level ${state.level}",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              "${state.xp} XP",
                              style: const TextStyle(
                                color: Color(0xFF38BDF8),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "🔥 Streak: ${state.streak} days",
                              style: const TextStyle(color: Colors.orange),
                            ),
                            const SizedBox(height: 10),
                            LinearProgressIndicator(
                              value: (state.xp % 100) / 100,
                              backgroundColor: Colors.white24,
                              color: const Color(0xFF38BDF8),
                              minHeight: 8,
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      const Text(
                        "Recommended Modules",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 8),

                      ...state.recommendedModules.map(
                        (module) => Card(
                          elevation: 0,
                          color: Colors.white,
                          child: ListTile(
                            leading: const Icon(
                              Icons.security,
                              color: Color(0xFF2563EB),
                            ),
                            title: Text(
                              module,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: const Text(
                              "Recommended based on your learning progress",
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      const Text(
                        "Your Badges",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 8),

                      if (state.badges.isEmpty)
                        const Text(
                          "No badges yet. Complete learning modules or quizzes to unlock badges.",
                          style: TextStyle(color: Colors.grey),
                        )
                      else
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: state.badges.map((badge) {
                            return Chip(
                              avatar: Icon(_badgeIcon(badge), size: 18),
                              label: Text(badge),
                            );
                          }).toList(),
                        ),

                      const SizedBox(height: 20),

                      const Text(
                        "Topic Performance",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 8),

                      _TopicProgress(
                        "Phishing",
                        state.topicScores["phishing"] ?? 0,
                      ),
                      _TopicProgress(
                        "Password",
                        state.topicScores["password"] ?? 0,
                      ),
                      _TopicProgress(
                        "Social",
                        state.topicScores["social"] ?? 0,
                      ),

                      const SizedBox(height: 20),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const LearningScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.menu_book),
                          label: const Text("Open Learning Modules"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0D1B3E),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const LeaderboardScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.leaderboard),
                          label: const Text("View Leaderboard"),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      context.read<QuizCubit>().loadQuiz();

                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const QuizScreen()),
                      );
                    },
                    icon: const Icon(Icons.quiz),
                    label: const Text("Start Quiz"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TopicProgress extends StatelessWidget {
  final String title;
  final double value;

  const _TopicProgress(this.title, this.value);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "$title ${(value * 100).toInt()}%",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: value,
              minHeight: 8,
              borderRadius: BorderRadius.circular(20),
            ),
          ],
        ),
      ),
    );
  }
}
