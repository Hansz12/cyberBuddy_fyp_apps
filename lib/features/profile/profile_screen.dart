import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../auth/cubit/auth_cubit.dart';
import '../auth/login_screen.dart';
import '../home/cubit/home_cubit.dart';
import '../home/cubit/home_state.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

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

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Progress reset successfully.")),
                );
              }
            },
            child: const Text("Reset"),
          ),
        ],
      ),
    );
  }

  double _topicValue(HomeState state, String topic) {
    return state.topicScores[topic] ?? 0;
  }

  String _weakestTopic(HomeState state) {
    String weakest = "phishing";
    double value = state.topicScores["phishing"] ?? 0.5;

    state.topicScores.forEach((key, score) {
      if (score < value) {
        weakest = key;
        value = score;
      }
    });

    return _label(weakest);
  }

  String _label(String topic) {
    switch (topic) {
      case "phishing":
        return "Phishing";
      case "password":
        return "Password";
      case "social":
        return "Privacy";
      case "malware":
        return "Malware";
      case "scam":
        return "Scams";
      case "mobile":
        return "Mobile";
      default:
        return topic;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: SafeArea(
        child: BlocBuilder<HomeCubit, HomeState>(
          builder: (context, state) {
            final nextRecommended = state.recommendedModules.isNotEmpty
                ? state.recommendedModules.first
                : "Recommended module";

            return ListView(
              padding: EdgeInsets.zero,
              children: [
                _ProfileHeader(state: state),

                Transform.translate(
                  offset: const Offset(0, -22),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            _StatCard(value: "${state.xp}", label: "Total XP"),
                            const SizedBox(width: 8),
                            const _StatCard(value: "8", label: "Modules"),
                            const SizedBox(width: 8),
                            const _StatCard(value: "78%", label: "Avg Score"),
                            const SizedBox(width: 8),
                            _StatCard(
                              value: "${state.badges.length}",
                              label: "Badges",
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        _ProfilePanel(
                          title: "🏅 BADGE COLLECTION",
                          child: GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: 4,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            childAspectRatio: 0.82,
                            children: const [
                              _BadgeBox(
                                icon: "🛡️",
                                title: "Phishing\nShield",
                                unlocked: true,
                              ),
                              _BadgeBox(
                                icon: "🔐",
                                title: "Password\nPro",
                                unlocked: true,
                              ),
                              _BadgeBox(
                                icon: "🔥",
                                title: "7-Day\nStreak",
                                unlocked: true,
                              ),
                              _BadgeBox(
                                icon: "🌱",
                                title: "Rookie\nBadge",
                                unlocked: true,
                              ),
                              _BadgeBox(
                                icon: "🔍",
                                title: "Malware\nHunter",
                                unlocked: false,
                              ),
                              _BadgeBox(
                                icon: "🏆",
                                title: "Quiz\nMaster",
                                unlocked: false,
                              ),
                              _BadgeBox(
                                icon: "⭐",
                                title: "All\nRounder",
                                unlocked: false,
                              ),
                              _BadgeBox(
                                icon: "💎",
                                title: "Elite\nDefender",
                                unlocked: false,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 14),

                        _ProfilePanel(
                          title: "📊 TOPIC PROGRESS",
                          child: Column(
                            children: [
                              _TopicProgressRow(
                                title: "Phishing",
                                value: _topicValue(state, "phishing"),
                                color: const Color(0xFFEF4444),
                              ),
                              _TopicProgressRow(
                                title: "Password",
                                value: _topicValue(state, "password"),
                                color: const Color(0xFF10B981),
                              ),
                              _TopicProgressRow(
                                title: "Malware",
                                value: 0.50,
                                color: const Color(0xFFF59E0B),
                              ),
                              _TopicProgressRow(
                                title: "Privacy",
                                value: _topicValue(state, "social"),
                                color: const Color(0xFFD946EF),
                              ),
                              const _TopicProgressRow(
                                title: "Scams",
                                value: 0.0,
                                color: Color(0xFF2563EB),
                              ),
                              const _TopicProgressRow(
                                title: "Mobile",
                                value: 0.0,
                                color: Color(0xFF2563EB),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 14),

                        _ProfilePanel(
                          title: "🎯 RECOMMENDATION PROFILE",
                          child: Column(
                            children: [
                              _ProfileInfoRow(
                                label: "Preferred\ntopics",
                                value: "Phishing · Password ·\nPrivacy",
                                valueColor: const Color(0xFF0F172A),
                              ),
                              _ProfileInfoRow(
                                label: "Difficulty\npreference",
                                value: "Intermediate →\nAdvanced",
                                valueColor: const Color(0xFF0F172A),
                              ),
                              _ProfileInfoRow(
                                label: "Weak area\ndetected",
                                value:
                                    "${_weakestTopic(state)} needs\nattention",
                                valueColor: const Color(0xFFEF4444),
                              ),
                              _ProfileInfoRow(
                                label: "Next recommended",
                                value: nextRecommended,
                                valueColor: const Color(0xFF2563EB),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 14),

                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _showResetDialog(context),
                                icon: const Icon(Icons.restore),
                                label: const Text("Reset"),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red,
                                  side: const BorderSide(color: Colors.red),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _logout(context),
                                icon: const Icon(Icons.logout),
                                label: const Text("Logout"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0D1B3E),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 90),
                      ],
                    ),
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

class _ProfileHeader extends StatelessWidget {
  final HomeState state;

  const _ProfileHeader({required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 42),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0D1B3E), Color(0xFF1E3A8A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 92,
            height: 92,
            decoration: BoxDecoration(
              color: const Color(0xFF38BDF8),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: const Color(0xFF60A5FA), width: 4),
            ),
            child: const Center(
              child: Text(
                "SF",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            "Siti Farhana",
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            "2023820378 · Mobile Computing",
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF38BDF8).withOpacity(0.18),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Text(
              "LV ${state.level} · Threat Spotter",
              style: const TextStyle(
                color: Color(0xFF38BDF8),
                fontWeight: FontWeight.w900,
                fontSize: 11,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.18),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Text(
              "🔥 ${state.streak}-day streak",
              style: const TextStyle(
                color: Color(0xFF10B981),
                fontWeight: FontWeight.w900,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;

  const _StatCard({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 58,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfilePanel extends StatelessWidget {
  final String title;
  final Widget child;

  const _ProfilePanel({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 15,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _BadgeBox extends StatelessWidget {
  final String icon;
  final String title;
  final bool unlocked;

  const _BadgeBox({
    required this.icon,
    required this.title,
    required this.unlocked,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: unlocked ? 1 : 0.35,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(icon, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 5),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 9,
                fontWeight: FontWeight.w900,
                height: 1.05,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopicProgressRow extends StatelessWidget {
  final String title;
  final double value;
  final Color color;

  const _TopicProgressRow({
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final percent = (value * 100).round();

    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        children: [
          SizedBox(
            width: 85,
            child: Text(
              title,
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Expanded(
            child: LinearProgressIndicator(
              value: value,
              minHeight: 7,
              color: color,
              backgroundColor: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 36,
            child: Text(
              "$percent%",
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileInfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _ProfileInfoRow({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 105,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 12,
                height: 1.15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: valueColor,
                fontSize: 12,
                height: 1.15,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
