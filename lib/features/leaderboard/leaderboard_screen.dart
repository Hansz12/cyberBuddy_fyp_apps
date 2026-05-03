import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  Color _rankColor(int rank) {
    if (rank == 1) return const Color(0xFFF59E0B);
    if (rank == 2) return const Color(0xFF94A3B8);
    if (rank == 3) return const Color(0xFFB45309);
    return const Color(0xFF2563EB);
  }

  String _rankText(int rank) {
    if (rank == 1) return "👑";
    if (rank == 2) return "🥈";
    if (rank == 3) return "🥉";
    return "$rank";
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text("Leaderboard"),
        backgroundColor: const Color(0xFF0D1B3E),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
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

          final users = snapshot.data?.docs ?? [];

          if (users.isEmpty) {
            return const Center(
              child: Text("No leaderboard data yet. Earn XP first!"),
            );
          }

          final currentUserIndex = users.indexWhere(
            (doc) => doc.id == currentUser?.uid,
          );

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D1B3E),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Top Defenders 🏆",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      "Live ranking is updated automatically based on XP.",
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              if (currentUserIndex != -1)
                _CurrentUserRankCard(
                  doc: users[currentUserIndex],
                  rank: currentUserIndex + 1,
                ),

              if (currentUserIndex != -1) const SizedBox(height: 20),

              if (users.isNotEmpty)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (users.length > 1)
                      _TopUserCard(doc: users[1], rank: 2, color: _rankColor(2))
                    else
                      const SizedBox(width: 86),

                    _TopUserCard(
                      doc: users[0],
                      rank: 1,
                      color: _rankColor(1),
                      isChampion: true,
                    ),

                    if (users.length > 2)
                      _TopUserCard(doc: users[2], rank: 3, color: _rankColor(3))
                    else
                      const SizedBox(width: 86),
                  ],
                ),

              const SizedBox(height: 24),

              const Text(
                "All Rankings",
                style: TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              ...List.generate(users.length, (index) {
                final doc = users[index];
                final data = doc.data() as Map<String, dynamic>;

                final rank = index + 1;
                final name = data['name']?.toString() ?? "User";
                final xp = data['xp'] ?? 0;
                final level = data['level'] ?? 1;
                final isCurrentUser = doc.id == currentUser?.uid;

                return Card(
                  elevation: 0,
                  color: isCurrentUser ? const Color(0xFFEFF6FF) : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(
                      color: isCurrentUser
                          ? const Color(0xFF2563EB)
                          : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _rankColor(rank),
                      child: Text(
                        _rankText(rank),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        if (isCurrentUser)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDBEAFE),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              "YOU",
                              style: TextStyle(
                                color: Color(0xFF2563EB),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    subtitle: Text("Level $level"),
                    trailing: Text(
                      "$xp XP",
                      style: const TextStyle(
                        color: Color(0xFF0D1B3E),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}

class _CurrentUserRankCard extends StatelessWidget {
  final QueryDocumentSnapshot doc;
  final int rank;

  const _CurrentUserRankCard({required this.doc, required this.rank});

  @override
  Widget build(BuildContext context) {
    final data = doc.data() as Map<String, dynamic>;

    final xp = data['xp'] ?? 0;
    final level = data['level'] ?? 1;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF0D1B3E)],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white,
            child: Text(
              "#$rank",
              style: const TextStyle(
                color: Color(0xFF2563EB),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Your Current Rank",
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  "$xp XP • Level $level",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.shield, color: Color(0xFF38BDF8)),
        ],
      ),
    );
  }
}

class _TopUserCard extends StatelessWidget {
  final QueryDocumentSnapshot doc;
  final int rank;
  final Color color;
  final bool isChampion;

  const _TopUserCard({
    required this.doc,
    required this.rank,
    required this.color,
    this.isChampion = false,
  });

  @override
  Widget build(BuildContext context) {
    final data = doc.data() as Map<String, dynamic>;

    final name = data['name']?.toString() ?? "User";
    final xp = data['xp'] ?? 0;
    final level = data['level'] ?? 1;

    return SizedBox(
      width: 86,
      child: Column(
        children: [
          if (isChampion) const Text("👑", style: TextStyle(fontSize: 26)),
          CircleAvatar(
            radius: isChampion ? 36 : 30,
            backgroundColor: color,
            child: Text(
              rank == 1
                  ? "1"
                  : rank == 2
                  ? "2"
                  : "3",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          Text(
            "$xp XP",
            style: const TextStyle(
              color: Color(0xFF2563EB),
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
          Text(
            "Lv $level",
            style: const TextStyle(color: Colors.grey, fontSize: 10),
          ),
        ],
      ),
    );
  }
}
