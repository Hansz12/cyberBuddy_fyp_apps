import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../auth/splash_screen.dart';
import '../home/cubit/home_cubit.dart';
import '../home/cubit/home_state.dart';
import '../learning/cubit/learning_cubit.dart';
import '../learning/module_detail_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? user;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    await FirebaseAuth.instance.currentUser?.reload();

    if (!mounted) return;

    setState(() {
      user = FirebaseAuth.instance.currentUser;
    });
  }

  String getUserName() {
    if (user == null) return "Guest User";

    if (user!.displayName != null && user!.displayName!.trim().isNotEmpty) {
      return user!.displayName!.trim();
    }

    final email = user!.email;

    if (email != null && email.contains("@")) {
      return email.split("@").first;
    }

    return "User";
  }

  String getUserEmail() {
    if (user == null) return "Not signed in";
    return user!.email ?? "No email";
  }

  String getInitials() {
    final name = getUserName().trim();

    if (name.isEmpty) return "U";

    final parts = name.split(" ");

    if (parts.length >= 2) {
      return "${parts[0][0]}${parts[1][0]}".toUpperCase();
    }

    return name.substring(0, 1).toUpperCase();
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  String _titleCase(String text) {
    if (text.trim().isEmpty) return "-";

    final clean = text.trim();
    return clean[0].toUpperCase() + clean.substring(1);
  }

  String _badgeEmoji(String badge) {
    final lower = badge.toLowerCase();

    if (lower.contains("phishing")) return "🛡️";
    if (lower.contains("password")) return "🔐";
    if (lower.contains("streak")) return "🔥";
    if (lower.contains("quiz")) return "🏆";
    if (lower.contains("perfect")) return "⭐";
    if (lower.contains("malware")) return "🦠";
    if (lower.contains("privacy")) return "👁️";
    if (lower.contains("threat")) return "🎯";
    if (lower.contains("rookie")) return "🌱";
    if (lower.contains("champion")) return "💎";
    if (lower.contains("defender")) return "🛡️";
    if (lower.contains("learner")) return "📚";

    return "🏅";
  }

  Color _topicColor(String topic) {
    switch (topic.toLowerCase()) {
      case "phishing":
        return Colors.orange;
      case "password":
        return Colors.green;
      case "social":
        return Colors.indigo;
      case "malware":
        return Colors.red;
      case "privacy":
        return Colors.purple;
      case "scam":
        return Colors.blue;
      case "mobile":
        return Colors.teal;
      case "network":
        return Colors.cyan;
      case "ethics":
        return Colors.deepPurple;
      case "banking":
        return Colors.lightBlue;
      default:
        return Colors.grey;
    }
  }

  String _getWeakestTopic(HomeState state) {
    final attempted = state.topicScores.entries.where((entry) {
      return (state.topicAnswered[entry.key] ?? 0) > 0;
    }).toList();

    if (attempted.isEmpty) return "No quiz data yet";

    attempted.sort((a, b) => a.value.compareTo(b.value));

    final weakest = attempted.first;

    return "${_titleCase(weakest.key)} (${(weakest.value * 100).round()}%)";
  }

  String _getStrongestTopic(HomeState state) {
    final attempted = state.topicScores.entries.where((entry) {
      return (state.topicAnswered[entry.key] ?? 0) > 0;
    }).toList();

    if (attempted.isEmpty) return "No quiz data yet";

    attempted.sort((a, b) => b.value.compareTo(a.value));

    final strongest = attempted.first;

    return "${_titleCase(strongest.key)} (${(strongest.value * 100).round()}%)";
  }

  String _preferredTopics(HomeState state) {
    final attempted = state.topicScores.entries.where((entry) {
      return (state.topicAnswered[entry.key] ?? 0) > 0 && entry.value >= 0.6;
    }).toList();

    if (attempted.isEmpty) return "No quiz data yet";

    return attempted.map((e) => _titleCase(e.key)).join(" • ");
  }

  String _difficultyPreference(HomeState state) {
    if (state.level >= 8) return "Advanced";
    if (state.level >= 4) return "Intermediate";
    return "Beginner";
  }

  Future<void> _editProfile() async {
    final controller = TextEditingController(text: getUserName());

    await showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Edit Profile"),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: "Display name",
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                final newName = controller.text.trim();

                if (newName.isEmpty) {
                  _showSnack("Name cannot be empty.");
                  return;
                }

                await FirebaseAuth.instance.currentUser?.updateDisplayName(
                  newName,
                );

                await _loadUser();

                if (mounted) {
                  Navigator.pop(context);
                  _showSnack("Profile updated successfully.");
                }
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _changePassword() async {
    final email = FirebaseAuth.instance.currentUser?.email;

    if (email == null || email.isEmpty) {
      _showSnack("No email found for this account.");
      return;
    }

    await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
    _showSnack("Password reset email sent to $email.");
  }

  Future<void> _resetProgress() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Reset Progress?"),
          content: const Text(
            "This will reset your XP, level, streak, badges, topic progress, quiz scores, recommendations and notifications. This action cannot be undone.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Reset"),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    await context.read<HomeCubit>().resetProgress();

    if (!mounted) return;

    _showSnack("Progress has been reset.");
  }

  void _openNotifications() {
    final notifications = context.read<HomeCubit>().state.notifications;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFF1F5F9),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.55,
          minChildSize: 0.35,
          maxChildSize: 0.85,
          builder: (context, scrollController) {
            return ListView(
              controller: scrollController,
              padding: const EdgeInsets.all(18),
              children: [
                const Text(
                  "Notifications 🔔",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 14),
                if (notifications.isEmpty)
                  _MiniCard(
                    child: const Text(
                      "No notifications yet.",
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                else
                  ...notifications.map(
                    (item) => _MiniCard(
                      child: Text(
                        item,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  void _openHelp() {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Help & Support"),
          content: const Text(
            "CyberBuddy helps students improve cybersecurity awareness through gamified modules, quizzes, threat checking, XP, badges, topic progress, and content-based learning recommendations.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close"),
            ),
          ],
        );
      },
    );
  }

  void _showBadgeInfo(String title, String desc) {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text(title),
          content: Text(desc),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close"),
            ),
          ],
        );
      },
    );
  }

  void _openRecommendedModule() {
    final homeState = context.read<HomeCubit>().state;
    final learningState = context.read<LearningCubit>().state;

    if (homeState.recommendedModules.isEmpty) {
      _showSnack("Complete quizzes first to generate recommendations.");
      return;
    }

    if (learningState.modules.isEmpty) {
      _showSnack("Modules not loaded yet.");
      return;
    }

    final recommendedTitle = homeState.recommendedModules.first;

    final module = learningState.modules.firstWhere(
      (m) => m.title == recommendedTitle,
      orElse: () => learningState.modules.first,
    );

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ModuleDetailScreen(module: module)),
    );
  }

  Future<void> logout() async {
    context.read<HomeCubit>().clearSession();

    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {}

    await FirebaseAuth.instance.signOut();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const SplashScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final homeState = context.watch<HomeCubit>().state;
    final learningState = context.watch<LearningCubit>().state;

    final xp = homeState.xp;
    final level = homeState.level;
    final streak = homeState.streak;
    final modules = learningState.modules.length;
    final badges = homeState.badges.length;
    final avgScore = homeState.avgScore;

    final hasQuizData = homeState.totalQuestionsAnswered > 0;
    final hasBadges = homeState.badges.isNotEmpty;
    final hasRecommendation =
        hasQuizData && homeState.recommendedModules.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadUser,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 30),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0D1B3E), Color(0xFF1E3A8A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 48,
                      backgroundColor: Colors.white,
                      child: Text(
                        getInitials(),
                        style: const TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0D1B3E),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      getUserName(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      getUserEmail(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _HeaderBadge(text: "LV $level • Threat Spotter"),
                    const SizedBox(height: 10),
                    _HeaderBadge(text: "🔥 $streak-day streak", green: true),
                  ],
                ),
              ),
              Transform.translate(
                offset: const Offset(0, -18),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    children: [
                      _StatCard(title: "Total XP", value: "$xp"),
                      _StatCard(title: "Modules", value: "$modules"),
                      _StatCard(title: "Avg Score", value: "$avgScore%"),
                      _StatCard(title: "Badges", value: "$badges"),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    _SectionCard(
                      title: "🏅 Badge Collection",
                      child: !hasBadges
                          ? const Text(
                              "No badges unlocked yet. Complete modules and quizzes to earn badges.",
                              style: TextStyle(
                                color: Colors.grey,
                                fontWeight: FontWeight.w600,
                                height: 1.4,
                              ),
                            )
                          : GridView.count(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisCount: 4,
                              childAspectRatio: 0.82,
                              children: homeState.badges.map((badge) {
                                return _BadgeItem(
                                  _badgeEmoji(badge),
                                  badge.replaceAll(" ", "\n"),
                                  onTap: () => _showBadgeInfo(
                                    badge,
                                    "Unlocked through your CyberBuddy learning progress.",
                                  ),
                                );
                              }).toList(),
                            ),
                    ),
                    const SizedBox(height: 16),
                    _SectionCard(
                      title: "📊 Topic Progress",
                      child: !hasQuizData
                          ? const Text(
                              "No topic progress yet. Complete quizzes first to analyse your topic performance.",
                              style: TextStyle(
                                color: Colors.grey,
                                fontWeight: FontWeight.w600,
                                height: 1.4,
                              ),
                            )
                          : Column(
                              children: homeState.topicScores.entries
                                  .where((entry) {
                                    return (homeState.topicAnswered[entry
                                                .key] ??
                                            0) >
                                        0;
                                  })
                                  .map((entry) {
                                    return _ProgressRow(
                                      label: _titleCase(entry.key),
                                      value: entry.value,
                                      color: _topicColor(entry.key),
                                    );
                                  })
                                  .toList(),
                            ),
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: hasRecommendation ? _openRecommendedModule : null,
                      borderRadius: BorderRadius.circular(18),
                      child: _SectionCard(
                        title: "🎯 Recommendation Profile",
                        child: !hasRecommendation
                            ? const Text(
                                "No recommendation available yet. Complete quizzes first so CyberBuddy can analyse your learning performance.",
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w600,
                                  height: 1.4,
                                ),
                              )
                            : Column(
                                children: [
                                  _InfoRow(
                                    label: "Preferred topics",
                                    value: _preferredTopics(homeState),
                                  ),
                                  _InfoRow(
                                    label: "Difficulty preference",
                                    value: _difficultyPreference(homeState),
                                  ),
                                  _InfoRow(
                                    label: "Strongest topic",
                                    value: _getStrongestTopic(homeState),
                                    valueColor: Colors.green,
                                  ),
                                  _InfoRow(
                                    label: "Weak area detected",
                                    value: _getWeakestTopic(homeState),
                                    valueColor: Colors.red,
                                  ),
                                  _InfoRow(
                                    label: "Average score",
                                    value: "${homeState.avgScore}%",
                                  ),
                                  _InfoRow(
                                    label: "Next recommendation",
                                    value: homeState.recommendedModules.first,
                                    valueColor: Colors.blue,
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    _MenuTile(
                      icon: Icons.person_outline,
                      title: "Edit Profile",
                      onTap: _editProfile,
                    ),
                    _MenuTile(
                      icon: Icons.lock_outline,
                      title: "Change Password",
                      onTap: _changePassword,
                    ),
                    _MenuTile(
                      icon: Icons.notifications_none,
                      title: "Notifications",
                      onTap: _openNotifications,
                    ),
                    _MenuTile(
                      icon: Icons.help_outline,
                      title: "Help & Support",
                      onTap: _openHelp,
                    ),
                    _MenuTile(
                      icon: Icons.restart_alt,
                      title: "Reset Progress",
                      color: Colors.orange,
                      onTap: _resetProgress,
                    ),
                    const SizedBox(height: 12),
                    _MenuTile(
                      icon: Icons.logout,
                      title: "Logout",
                      color: Colors.red,
                      onTap: logout,
                    ),
                    const SizedBox(height: 120),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderBadge extends StatelessWidget {
  final String text;
  final bool green;

  const _HeaderBadge({required this.text, this.green = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: green
            ? Colors.green.withOpacity(0.18)
            : Colors.cyan.withOpacity(0.15),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: green ? Colors.greenAccent : Colors.cyanAccent,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;

  const _StatCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _BadgeItem extends StatelessWidget {
  final String emoji;
  final String title;
  final VoidCallback onTap;

  const _BadgeItem(this.emoji, this.title, {required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Column(
        children: [
          Container(
            height: 54,
            width: 54,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(emoji, style: const TextStyle(fontSize: 24)),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _ProgressRow extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _ProgressRow({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final safeValue = value.clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: LinearProgressIndicator(
                value: safeValue,
                minHeight: 8,
                backgroundColor: Colors.grey.shade300,
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            "${(safeValue * 100).round()}%",
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: valueColor ?? const Color(0xFF0F172A),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color? color;
  final VoidCallback onTap;

  const _MenuTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final itemColor = color ?? const Color(0xFF0F172A);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Icon(icon, color: itemColor),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: itemColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: itemColor),
          ],
        ),
      ),
    );
  }
}

class _MiniCard extends StatelessWidget {
  final Widget child;

  const _MiniCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }
}
