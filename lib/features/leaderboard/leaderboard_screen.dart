import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../home/cubit/home_cubit.dart';
import '../quiz/cubit/quiz_cubit.dart';
import '../quiz/quiz_screen.dart';
import 'cubit/leaderboard_cubit.dart';
import 'cubit/leaderboard_state.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      context.read<LeaderboardCubit>().listenLeaderboard();
    });
  }

  Color _avatarColor(int index) {
    final colors = [
      const Color(0xFFF59E0B),
      const Color(0xFF94A3B8),
      const Color(0xFFF97316),
      const Color(0xFF8B5CF6),
      const Color(0xFF2563EB),
      const Color(0xFF10B981),
      const Color(0xFFEC4899),
      const Color(0xFF14B8A6),
    ];

    return colors[index % colors.length];
  }

  void _startQuiz(BuildContext context) {
    context.read<QuizCubit>().loadQuiz("M001");

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const QuizScreen()),
    ).then((_) {
      context.read<LeaderboardCubit>().refreshLeaderboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: SafeArea(
        child: BlocBuilder<LeaderboardCubit, LeaderboardState>(
          builder: (context, state) {
            if (state.isLoading && state.users.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state.errorMessage.isNotEmpty && state.users.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    state.errorMessage,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            final users = state.users;

            if (users.isEmpty) {
              return RefreshIndicator(
                onRefresh: () =>
                    context.read<LeaderboardCubit>().refreshLeaderboard(),
                child: ListView(
                  children: const [
                    SizedBox(height: 250),
                    Center(
                      child: Text(
                        "No leaderboard data yet.",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              );
            }

            final topUsers = users.take(3).toList();
            final restUsers = users.skip(3).toList();

            final currentIndex = users.indexWhere((u) => u.isCurrentUser);
            final currentRank = currentIndex >= 0 ? currentIndex + 1 : 0;
            final currentUser = currentIndex >= 0 ? users[currentIndex] : null;

            final currentXp =
                currentUser?.xp ?? context.read<HomeCubit>().state.xp;

            return RefreshIndicator(
              onRefresh: () =>
                  context.read<LeaderboardCubit>().refreshLeaderboard(),
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  const _Header(),
                  _Podium(users: topUsers),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 110),
                    child: Column(
                      children: [
                        ...restUsers.asMap().entries.map((entry) {
                          final index = entry.key + 3;
                          final user = entry.value;

                          return _RankTile(
                            rank: index + 1,
                            user: user,
                            avatarColor: _avatarColor(index),
                          );
                        }),
                        const SizedBox(height: 12),
                        _ChallengeCard(
                          currentRank: currentRank,
                          currentXp: currentXp,
                          onStartQuiz: () => _startQuiz(context),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0D1B3E), Color(0xFF1E3A8A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Leaderboard",
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 4),
          Text(
            "Top CyberBuddy learners ranked by leaderboard score",
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _Podium extends StatelessWidget {
  final List<LeaderboardUser> users;

  const _Podium({required this.users});

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) return const SizedBox.shrink();

    final first = users.isNotEmpty ? users[0] : null;
    final second = users.length > 1 ? users[1] : null;
    final third = users.length > 2 ? users[2] : null;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1E293B), Color(0xFFE2E8F0)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: second == null
                ? const SizedBox()
                : _PodiumUser(
                    user: second,
                    rank: 2,
                    avatarColor: const Color(0xFF94A3B8),
                    height: 54,
                  ),
          ),
          Expanded(
            child: first == null
                ? const SizedBox()
                : _PodiumUser(
                    user: first,
                    rank: 1,
                    avatarColor: const Color(0xFFF59E0B),
                    height: 86,
                    isChampion: true,
                  ),
          ),
          Expanded(
            child: third == null
                ? const SizedBox()
                : _PodiumUser(
                    user: third,
                    rank: 3,
                    avatarColor: const Color(0xFFF97316),
                    height: 54,
                  ),
          ),
        ],
      ),
    );
  }
}

class _PodiumUser extends StatelessWidget {
  final LeaderboardUser user;
  final int rank;
  final Color avatarColor;
  final double height;
  final bool isChampion;

  const _PodiumUser({
    required this.user,
    required this.rank,
    required this.avatarColor,
    required this.height,
    this.isChampion = false,
  });

  String _initials(String name) {
    final clean = name.trim();

    if (clean.isEmpty) return "?";

    final parts = clean.split(RegExp(r'\s+'));

    if (parts.length >= 2) {
      return "${parts[0][0]}${parts[1][0]}".toUpperCase();
    }

    return clean[0].toUpperCase();
  }

  String _shortName(String name) {
    final clean = name.trim();

    if (clean.length <= 9) return clean;

    return clean.substring(0, 9);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: isChampion ? 34 : 25,
          backgroundColor: avatarColor,
          child: Text(
            _initials(user.name),
            style: TextStyle(
              color: Colors.white,
              fontSize: isChampion ? 18 : 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _shortName(user.name),
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          "${user.xp} XP",
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: height,
          width: 58,
          decoration: BoxDecoration(
            color: avatarColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          ),
          alignment: Alignment.center,
          child: Text(
            rank == 1 ? "👑" : "$rank",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }
}

class _RankTile extends StatelessWidget {
  final int rank;
  final LeaderboardUser user;
  final Color avatarColor;

  const _RankTile({
    required this.rank,
    required this.user,
    required this.avatarColor,
  });

  String _initials(String name) {
    final clean = name.trim();

    if (clean.isEmpty) return "?";

    final parts = clean.split(RegExp(r'\s+'));

    if (parts.length >= 2) {
      return "${parts[0][0]}${parts[1][0]}".toUpperCase();
    }

    return clean[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(
        color: user.isCurrentUser ? const Color(0xFFEFF6FF) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: user.isCurrentUser
              ? const Color(0xFF2563EB)
              : const Color(0xFFE2E8F0),
          width: user.isCurrentUser ? 1.4 : 1,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Text(
              "#$rank",
              style: const TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          CircleAvatar(
            radius: 18,
            backgroundColor: avatarColor,
            child: Text(
              _initials(user.name),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 12,
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
                        user.name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF0F172A),
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    if (user.isCurrentUser) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: const Text(
                          "YOU",
                          style: TextStyle(
                            color: Color(0xFF2563EB),
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  "${user.faculty} • ${user.streak} streak • ${user.badgesCount} badges",
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Text(
            "${user.xp} XP",
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right, color: Color(0xFF94A3B8), size: 16),
        ],
      ),
    );
  }
}

class _ChallengeCard extends StatelessWidget {
  final int currentRank;
  final int currentXp;
  final VoidCallback onStartQuiz;

  const _ChallengeCard({
    required this.currentRank,
    required this.currentXp,
    required this.onStartQuiz,
  });

  @override
  Widget build(BuildContext context) {
    final neededXp = currentRank <= 1 ? 0 : (1000 - currentXp).clamp(0, 1000);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4338CA), Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "🎯 Earn more XP to reach #1!",
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            currentRank <= 1
                ? "You are currently at the top. Keep completing quizzes to defend your rank."
                : "You need $neededXp more XP. Complete more quizzes this week.",
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onStartQuiz,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF4338CA),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11),
                ),
              ),
              child: const Text(
                "Start a quiz now →",
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
