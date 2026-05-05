import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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

  Color _rankColor(int rank) {
    if (rank == 1) return const Color(0xFFF59E0B);
    if (rank == 2) return const Color(0xFF94A3B8);
    if (rank == 3) return const Color(0xFFF97316);
    return const Color(0xFF2563EB);
  }

  String _initials(String name) {
    final cleanName = name.trim();

    if (cleanName.isEmpty) return "U";

    if (cleanName.contains("@")) {
      return cleanName.substring(0, 1).toUpperCase();
    }

    final parts = cleanName.split(" ");

    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }

    return "${parts[0][0]}${parts[1][0]}".toUpperCase();
  }

  String _displayName(String name) {
    if (!name.contains("@")) return name;
    return name.split("@").first;
  }

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
    context.read<QuizCubit>().loadQuiz();

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const QuizScreen()),
    );
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
              .orderBy('xp', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    "Leaderboard error:\n${snapshot.error}",
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final allUsers = snapshot.data?.docs ?? [];
            final users = _filterUsers(allUsers);

            if (users.isEmpty) {
              return Column(
                children: [
                  _LeaderboardHeader(
                    selectedFilter: selectedFilter,
                    filters: filters,
                    onFilterSelected: (value) {
                      setState(() => selectedFilter = value);
                    },
                  ),
                  const Expanded(
                    child: Center(
                      child: Text("No users found for this category."),
                    ),
                  ),
                ],
              );
            }

            final currentUserIndex = allUsers.indexWhere(
              (doc) => doc.id == currentUser?.uid,
            );

            return ListView(
              padding: EdgeInsets.zero,
              children: [
                _LeaderboardHeader(
                  selectedFilter: selectedFilter,
                  filters: filters,
                  onFilterSelected: (value) {
                    setState(() => selectedFilter = value);
                  },
                ),

                Container(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
                  decoration: const BoxDecoration(color: Color(0xFFF1F5F9)),
                  child: Column(
                    children: [
                      _PodiumSection(
                        users: users.take(3).toList(),
                        initials: _initials,
                        displayName: _displayName,
                        rankColor: _rankColor,
                      ),

                      const SizedBox(height: 22),

                      if (currentUserIndex != -1)
                        _CurrentRankCard(
                          rank: currentUserIndex + 1,
                          targetXp: currentUserIndex == 0
                              ? 0
                              : (((allUsers[currentUserIndex - 1].data()
                                                as Map<
                                                  String,
                                                  dynamic
                                                >)['xp'] ??
                                            0) -
                                        ((allUsers[currentUserIndex].data()
                                                as Map<
                                                  String,
                                                  dynamic
                                                >)['xp'] ??
                                            0))
                                    .clamp(0, 999999),
                        ),

                      if (currentUserIndex != -1) const SizedBox(height: 14),

                      ...List.generate(users.length, (index) {
                        final doc = users[index];
                        final data = doc.data() as Map<String, dynamic>;

                        final rank =
                            allUsers.indexWhere((item) => item.id == doc.id) +
                            1;

                        final name = data['name']?.toString() ?? "User";
                        final xp = data['xp'] ?? 0;
                        final level = data['level'] ?? 1;
                        final tier = _tierFromLevel(level);
                        final isCurrentUser = doc.id == currentUser?.uid;

                        return _RankListCard(
                          rank: rank,
                          initials: _initials(name),
                          name: _displayName(name),
                          tier: tier,
                          xp: xp,
                          isCurrentUser: isCurrentUser,
                          color: _rankColor(rank),
                        );
                      }),

                      const SizedBox(height: 16),

                      _QuizCtaCard(onTap: () => _goToQuiz(context)),
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

class _LeaderboardHeader extends StatelessWidget {
  final String selectedFilter;
  final List<String> filters;
  final ValueChanged<String> onFilterSelected;

  const _LeaderboardHeader({
    required this.selectedFilter,
    required this.filters,
    required this.onFilterSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0D1B3E), Color(0xFF1E3A8A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text(
                "9:41",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Spacer(),
              Text(
                "WIFI 🔋",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          const Text(
            "CyberBuddy Leaderboard",
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            "Weekly top learners · updates in real time",
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: filters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final item = filters[index];
                final selected = selectedFilter == item;

                return GestureDetector(
                  onTap: () => onFilterSelected(item),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selected
                          ? Colors.white
                          : Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected
                            ? Colors.white
                            : Colors.white.withOpacity(0.15),
                      ),
                    ),
                    child: Text(
                      item,
                      style: TextStyle(
                        color: selected
                            ? const Color(0xFF0D1B3E)
                            : Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
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

class _PodiumSection extends StatelessWidget {
  final List<QueryDocumentSnapshot> users;
  final String Function(String) initials;
  final String Function(String) displayName;
  final Color Function(int) rankColor;

  const _PodiumSection({
    required this.users,
    required this.initials,
    required this.displayName,
    required this.rankColor,
  });

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) return const SizedBox();

    final first = users.isNotEmpty ? users[0] : null;
    final second = users.length > 1 ? users[1] : null;
    final third = users.length > 2 ? users[2] : null;

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: second == null
                ? const SizedBox(height: 150)
                : _PodiumUser(
                    doc: second,
                    rank: 2,
                    height: 70,
                    color: rankColor(2),
                    initials: initials,
                    displayName: displayName,
                  ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: first == null
                ? const SizedBox(height: 170)
                : _PodiumUser(
                    doc: first,
                    rank: 1,
                    height: 96,
                    color: rankColor(1),
                    initials: initials,
                    displayName: displayName,
                    champion: true,
                  ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: third == null
                ? const SizedBox(height: 150)
                : _PodiumUser(
                    doc: third,
                    rank: 3,
                    height: 70,
                    color: rankColor(3),
                    initials: initials,
                    displayName: displayName,
                  ),
          ),
        ],
      ),
    );
  }
}

class _PodiumUser extends StatelessWidget {
  final QueryDocumentSnapshot doc;
  final int rank;
  final double height;
  final Color color;
  final String Function(String) initials;
  final String Function(String) displayName;
  final bool champion;

  const _PodiumUser({
    required this.doc,
    required this.rank,
    required this.height,
    required this.color,
    required this.initials,
    required this.displayName,
    this.champion = false,
  });

  @override
  Widget build(BuildContext context) {
    final data = doc.data() as Map<String, dynamic>;
    final name = data['name']?.toString() ?? "User";
    final xp = data['xp'] ?? 0;

    return Column(
      children: [
        CircleAvatar(
          radius: champion ? 34 : 28,
          backgroundColor: color,
          child: Text(
            initials(name),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          displayName(name),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontWeight: FontWeight.bold,
            fontSize: 11,
          ),
        ),
        Text(
          "$xp XP",
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w900,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: height,
          width: double.infinity,
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          ),
          child: Center(
            child: Text(
              rank == 1 ? "👑" : "$rank",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CurrentRankCard extends StatelessWidget {
  final int rank;
  final int targetXp;

  const _CurrentRankCard({required this.rank, required this.targetXp});

  @override
  Widget build(BuildContext context) {
    final message = rank == 1
        ? "You are currently #1. Keep defending your rank!"
        : "You need $targetXp more XP to reach the next rank.";

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const CircleAvatar(backgroundColor: Colors.white, child: Text("🎯")),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RankListCard extends StatelessWidget {
  final int rank;
  final String initials;
  final String name;
  final String tier;
  final int xp;
  final bool isCurrentUser;
  final Color color;

  const _RankListCard({
    required this.rank,
    required this.initials,
    required this.name,
    required this.tier,
    required this.xp,
    required this.isCurrentUser,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrentUser
              ? const Color(0xFF2563EB)
              : const Color(0xFFE2E8F0),
          width: isCurrentUser ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 34,
            child: Text(
              "#$rank",
              style: const TextStyle(
                color: Color(0xFF94A3B8),
                fontWeight: FontWeight.w900,
                fontSize: 15,
              ),
            ),
          ),
          CircleAvatar(
            radius: 20,
            backgroundColor: color,
            child: Text(
              initials,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 13,
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
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF0F172A),
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    if (isCurrentUser) ...[
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
                Text(
                  tier,
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Text(
            "$xp",
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontWeight: FontWeight.w900,
              fontSize: 15,
            ),
          ),
          const SizedBox(width: 6),
          const Icon(Icons.chevron_right, color: Color(0xFF94A3B8), size: 18),
        ],
      ),
    );
  }
}

class _QuizCtaCard extends StatelessWidget {
  final VoidCallback onTap;

  const _QuizCtaCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "🎯 Earn more XP to climb the ranks!",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            "Complete modules, quizzes, and threat checks to improve your leaderboard position.",
            style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.35),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF2563EB),
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
              child: const Text(
                "Start a quiz now →",
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
