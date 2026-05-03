import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../home/cubit/home_cubit.dart';
import '../home/cubit/home_state.dart';

import '../auth/login_screen.dart';
import '../auth/cubit/auth_cubit.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  IconData _badgeIcon(String badge) {
    if (badge.contains("Rookie")) return Icons.shield;
    if (badge.contains("Beginner")) return Icons.security;
    if (badge.contains("Intermediate")) return Icons.workspace_premium;
    if (badge.contains("Hero")) return Icons.emoji_events;
    if (badge.contains("Consistent")) return Icons.local_fire_department;
    return Icons.star;
  }

  void _showResetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Reset Progress"),
        content: const Text(
          "Are you sure you want to reset all progress? This cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);

              await context.read<HomeCubit>().resetProgress();

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Progress reset successfully.")),
              );
            },
            child: const Text("Reset"),
          ),
        ],
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    await context.read<AuthCubit>().signOut();

    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text("Profile"),
        backgroundColor: const Color(0xFF0D1B3E),
        foregroundColor: Colors.white,
      ),
      body: BlocBuilder<HomeCubit, HomeState>(
        builder: (context, state) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // 🔷 HEADER
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D1B3E),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 42,
                      backgroundColor: Color(0xFF38BDF8),
                      child: Text(
                        "SF",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "Siti Farhana",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "FSKM Mobile Computing",
                      style: TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Level ${state.level} • ${state.xp} XP • 🔥 ${state.streak} days",
                      style: const TextStyle(
                        color: Color(0xFF38BDF8),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 🔷 STATS
              Row(
                children: [
                  _StatCard("XP", "${state.xp}"),
                  const SizedBox(width: 10),
                  _StatCard("Level", "${state.level}"),
                  const SizedBox(width: 10),
                  _StatCard("Badges", "${state.badges.length}"),
                ],
              ),

              const SizedBox(height: 24),

              // 🔷 BADGES
              const Text(
                "Badge Collection",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 10),

              state.badges.isEmpty
                  ? const Text("No badges yet.")
                  : Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: state.badges.map((badge) {
                        return Chip(
                          avatar: Icon(_badgeIcon(badge), size: 18),
                          label: Text(badge),
                          backgroundColor: const Color(0xFFFEF3C7),
                        );
                      }).toList(),
                    ),

              const SizedBox(height: 24),

              // 🔥 RESET BUTTON
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showResetDialog(context),
                  icon: const Icon(Icons.restore),
                  label: const Text("Reset Progress"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // 🚪 LOGOUT BUTTON
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _logout(context),
                  icon: const Icon(Icons.logout),
                  label: const Text("Logout"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// 🔹 STAT CARD
class _StatCard extends StatelessWidget {
  final String title;
  final String value;

  const _StatCard(this.title, this.value);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Color(0xFF0D1B3E),
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(title, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
