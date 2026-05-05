import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../home/cubit/home_cubit.dart';
import '../quiz/cubit/quiz_cubit.dart';
import '../quiz/quiz_screen.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  String selectedFilter = "All Users";

  final filters = const ["All Users", "Beginner", "Intermediate", "Advanced"];

  String _tierFromLevel(int level) {
    if (level >= 5) return "Advanced";
    if (level >= 3) return "Intermediate";
    return "Beginner";
  }

  List<QueryDocumentSnapshot> _filterUsers(List<QueryDocumentSnapshot> users) {
    if (selectedFilter == "All Users") return users;

    return users.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final level = data['level'] ?? 1;
      return _tierFromLevel(level) == selectedFilter;
    }).toList();
  }

  void _goToQuiz(BuildContext context) {
    final homeState = context.read<HomeCubit>().state;

    context.read<QuizCubit>().loadQuiz(homeState: homeState);

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const QuizScreen()),
    );
  }

  String _displayName(String name) {
    if (!name.contains("@")) return name;
    return name.split("@").first;
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('leaderboard')
              .orderBy('leaderboardScore', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  "Leaderboard error:\n${snapshot.error}",
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final allUsers = snapshot.data?.docs ?? [];
            final users = _filterUsers(allUsers);

            return ListView(
              padding: EdgeInsets.zero,
              children: [
                _Header(
                  selectedFilter: selectedFilter,
                  filters: filters,
                  onSelect: (value) {
                    setState(() => selectedFilter = value);
                  },
                ),

                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      if (users.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(40),
                          child: Text("No users found."),
                        )
                      else
                        ...List.generate(users.length, (index) {
                          final doc = users[index];
                          final data = doc.data() as Map<String, dynamic>;

                          final rank =
                              allUsers.indexWhere((item) => item.id == doc.id) +
                              1;

                          final name = data['name']?.toString() ?? "User";
                          final xp = data['xp'] ?? 0;
                          final level = data['level'] ?? 1;
                          final streak = data['streak'] ?? 0;
                          final badges = data['badges'] ?? 0;
                          final score = data['leaderboardScore'] ?? xp;
                          final isMe = doc.id == currentUser?.uid;

                          return _RankTile(
                            rank: rank,
                            name: _displayName(name),
                            xp: xp,
                            level: level,
                            streak: streak,
                            badges: badges,
                            leaderboardScore: score,
                            isMe: isMe,
                          );
                        }),

                      const SizedBox(height: 20),

                      _ScoreFormulaCard(),

                      const SizedBox(height: 16),

                      _QuizCTA(onTap: () => _goToQuiz(context)),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String selectedFilter;
  final List<String> filters;
  final ValueChanged<String> onSelect;

  const _Header({
    required this.selectedFilter,
    required this.filters,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0D1B3E), Color(0xFF1E3A8A)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "CyberBuddy Leaderboard",
            style: TextStyle(
              color: Colors.white,
              fontSize: 23,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            "Ranking = XP + streak bonus + badge bonus",
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 36,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: filters.length,
              itemBuilder: (_, index) {
                final item = filters[index];
                final selected = item == selectedFilter;

                return GestureDetector(
                  onTap: () => onSelect(item),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selected
                          ? Colors.white
                          : Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      item,
                      style: TextStyle(
                        color: selected
                            ? const Color(0xFF0D1B3E)
                            : Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _RankTile extends StatelessWidget {
  final int rank;
  final String name;
  final int xp;
  final int level;
  final int streak;
  final int badges;
  final int leaderboardScore;
  final bool isMe;

  const _RankTile({
    required this.rank,
    required this.name,
    required this.xp,
    required this.level,
    required this.streak,
    required this.badges,
    required this.leaderboardScore,
    required this.isMe,
  });

  Color _rankColor() {
    if (rank == 1) return const Color(0xFFF59E0B);
    if (rank == 2) return const Color(0xFF94A3B8);
    if (rank == 3) return const Color(0xFFF97316);
    return const Color(0xFF2563EB);
  }

  String _rankIcon() {
    if (rank == 1) return "👑";
    if (rank == 2) return "🥈";
    if (rank == 3) return "🥉";
    return "#$rank";
  }

  @override
  Widget build(BuildContext context) {
    final initial = name.isEmpty ? "U" : name[0].toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isMe ? const Color(0xFFEFF6FF) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isMe ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
          width: isMe ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Text(
              _rankIcon(),
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
            ),
          ),

          CircleAvatar(
            backgroundColor: _rankColor(),
            child: Text(
              initial,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF0F172A),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDBEAFE),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          "YOU",
                          style: TextStyle(
                            color: Color(0xFF2563EB),
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  "Lv $level · $xp XP · 🔥 $streak · 🏅 $badges",
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "$leaderboardScore",
                style: const TextStyle(
                  color: Color(0xFF0F172A),
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
              const Text(
                "score",
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ScoreFormulaCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: const Text(
        "Leaderboard Score = XP + (Streak × 10) + (Badges × 25)",
        style: TextStyle(
          color: Color(0xFF1E3A8A),
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _QuizCTA extends StatelessWidget {
  final VoidCallback onTap;

  const _QuizCTA({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "🎯 Earn more score to climb the ranks!",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          const Text(
            "Complete quizzes, maintain streaks, and unlock badges to increase your leaderboard score.",
            style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.35),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF2563EB),
            ),
            child: const Text("Start a quiz now"),
          ),
        ],
      ),
    );
  }
}
