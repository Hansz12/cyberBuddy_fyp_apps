import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/services/news_service.dart';
import '../learning/learning_screen.dart';
// ignore: unused_import
import '../learning/cubit/learning_cubit.dart';
import '../news/news_screen.dart';
import '../quiz/cubit/quiz_cubit.dart';
import '../quiz/quiz_screen.dart';
import '../threat_checker/threat_checker_screen.dart';

import 'cubit/home_cubit.dart';
import 'cubit/home_state.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Map<String, dynamic>>> _newsFuture;

  @override
  void initState() {
    super.initState();
    _newsFuture = NewsService().fetchCyberNews();
  }

  Future<void> _refreshHomeNews() async {
    setState(() {
      _newsFuture = NewsService().fetchCyberNews();
    });

    await _newsFuture;
  }

  void _openQuiz(BuildContext context) {
    final learningState = context.read<LearningCubit>().state;

    if (learningState.modules.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Modules not loaded yet.")));
      return;
    }

    final module = learningState.modules.first;

    context.read<QuizCubit>().loadQuiz(module.id);

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const QuizScreen()),
    );
  }

  void _openLearning(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LearningScreen()),
    );
  }

  void _openThreatChecker(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ThreatCheckerScreen()),
    );
  }

  void _openNews(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NewsScreen()),
    );
  }

  Future<void> _openNewsUrl(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);

    if (uri == null || url.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Invalid news link.")));
      return;
    }

    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  String _cleanSource(dynamic source) {
    if (source == null) return "Online source";

    if (source is Map) {
      return source["name"]?.toString() ?? "Online source";
    }

    final text = source.toString();

    if (text.contains("name:")) {
      final match = RegExp(r'name:\s*([^,}]+)').firstMatch(text);
      return match?.group(1)?.trim() ?? "Online source";
    }

    return text;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: SafeArea(
        child: BlocBuilder<HomeCubit, HomeState>(
          builder: (context, state) {
            return RefreshIndicator(
              onRefresh: _refreshHomeNews,
              child: ListView(
                children: [
                  _HomeHeader(state: state),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const _SectionHeader(
                          title: "WEEKLY STREAK",
                          actionText: "",
                          onTap: null,
                        ),
                        const SizedBox(height: 8),
                        _WeeklyStreakRow(streak: state.streak),
                        const SizedBox(height: 18),
                        _SectionHeader(
                          title: "DAILY QUESTS",
                          actionText: "View all",
                          onTap: () => _openLearning(context),
                        ),
                        const SizedBox(height: 8),
                        GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 1.28,
                          children: [
                            _QuestCard(
                              icon: "📖",
                              title: "Complete 1\nmodule",
                              xp: "+10 XP",
                              progress: 0.15,
                              onTap: () => _openLearning(context),
                            ),
                            _QuestCard(
                              icon: "🎯",
                              title: "Score 80%+\nquiz",
                              xp: "+20 XP",
                              progress: 0.30,
                              onTap: () => _openQuiz(context),
                            ),
                            _QuestCard(
                              icon: "⚡",
                              title: "New topic\ntoday",
                              xp: "+15 XP",
                              progress: 0.60,
                              onTap: () => _openLearning(context),
                            ),
                            _QuestCard(
                              icon: "🔍",
                              title: "Use threat\nchecker",
                              xp: "+25 XP",
                              progress: 1.0,
                              onTap: () => _openThreatChecker(context),
                            ),
                          ],
                        ),
                        const SizedBox(height: 22),
                        _SectionHeader(
                          title: "RECOMMENDED FOR YOU",
                          actionText: "More",
                          onTap: () => _openLearning(context),
                        ),
                        const SizedBox(height: 8),
                        ...state.recommendedModules.map((module) {
                          final score = state.moduleScores[module] ?? 0;
                          final reason =
                              state.moduleReasons[module] ??
                              "Recommended based on your learning progress.";

                          return _RecommendedCard(
                            title: module,
                            score: score,
                            reason: reason,
                            onTap: () => _openLearning(context),
                          );
                        }),
                        const SizedBox(height: 18),
                        _NewsSectionHeader(
                          onAllNews: () => _openNews(context),
                          onRefresh: _refreshHomeNews,
                        ),
                        const SizedBox(height: 8),
                        FutureBuilder<List<Map<String, dynamic>>>(
                          future: _newsFuture,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return Container(
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: const Color(0xFFE2E8F0),
                                  ),
                                ),
                                child: const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }

                            if (snapshot.hasError) {
                              return Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: const Color(0xFFE2E8F0),
                                  ),
                                ),
                                child: Text(
                                  "News error: ${snapshot.error}",
                                  style: const TextStyle(color: Colors.red),
                                ),
                              );
                            }

                            final newsList = snapshot.data ?? [];

                            if (newsList.isEmpty) {
                              return Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: const Color(0xFFE2E8F0),
                                  ),
                                ),
                                child: const Text(
                                  "No relevant cybersecurity news found.",
                                ),
                              );
                            }

                            return Column(
                              children: newsList.take(3).map((news) {
                                return _NewsCard(
                                  icon: "📰",
                                  tag: "LIVE",
                                  title:
                                      news["title"]?.toString() ??
                                      "Cybersecurity news",
                                  source: _cleanSource(news["source"]),
                                  onTap: () => _openNewsUrl(
                                    context,
                                    news["url"]?.toString() ?? "",
                                  ),
                                );
                              }).toList(),
                            );
                          },
                        ),
                        const SizedBox(height: 90),
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

class _HomeHeader extends StatelessWidget {
  final HomeState state;

  const _HomeHeader({required this.state});

  String _getGreeting() {
    final hour = DateTime.now().hour;

    if (hour >= 5 && hour < 12) {
      return "Good morning,";
    } else if (hour >= 12 && hour < 18) {
      return "Good afternoon,";
    } else if (hour >= 18 && hour < 22) {
      return "Good evening,";
    } else {
      return "Good night,";
    }
  }

  String _getUserName() {
    final user = FirebaseAuth.instance.currentUser;

    if (user?.displayName != null && user!.displayName!.trim().isNotEmpty) {
      return user.displayName!.trim();
    }

    final email = user?.email ?? "User";

    if (email.contains("@")) {
      final name = email.split("@").first;
      if (name.isEmpty) return "User";
      return name[0].toUpperCase() + name.substring(1);
    }

    return "User";
  }

  void _showNotifications(BuildContext context) {
    context.read<HomeCubit>().markNotificationsAsRead();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFF1F5F9),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) {
        final notifications = state.notifications;

        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.62,
          minChildSize: 0.35,
          maxChildSize: 0.90,
          builder: (context, scrollController) {
            return ListView(
              controller: scrollController,
              padding: const EdgeInsets.all(18),
              children: [
                Container(
                  width: 46,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),

                const Text(
                  "Notifications 🔔",
                  style: TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),

                const SizedBox(height: 14),

                if (notifications.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const Text(
                      "No notifications yet.",
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                else
                  ...notifications.take(20).map((item) {
                    return Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Text(
                        item,
                        style: const TextStyle(
                          color: Color(0xFF0F172A),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    );
                  }),

                const SizedBox(height: 24),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final nextLevelXp = state.level * 100;
    final currentLevelStart = (state.level - 1) * 100;
    final currentProgress = state.xp - currentLevelStart;
    final neededProgress = nextLevelXp - currentLevelStart;
    final progressValue = neededProgress == 0
        ? 0.0
        : (currentProgress / neededProgress).clamp(0.0, 1.0);

    final userName = _getUserName();

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 30, 18, 28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0D1B3E), Color(0xFF1E3A8A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getGreeting(),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      "$userName 👋",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => _showNotifications(context),
                child: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Stack(
                    children: [
                      const Center(
                        child: Text("🔔", style: TextStyle(fontSize: 22)),
                      ),
                      if (state.hasUnreadNotifications)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF38BDF8).withOpacity(0.18),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF38BDF8).withOpacity(0.4),
                  ),
                ),
                child: Text(
                  "LV ${state.level} · THREAT SPOTTER",
                  style: const TextStyle(
                    color: Color(0xFF38BDF8),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.7,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                "${state.xp} / $nextLevelXp XP",
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progressValue,
            minHeight: 8,
            backgroundColor: Colors.white24,
            color: const Color(0xFF38BDF8),
            borderRadius: BorderRadius.circular(20),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _HeaderStatCard(value: "🔥 ${state.streak}", label: "Day Streak"),
              const SizedBox(width: 10),
              const _HeaderStatCard(value: "8", label: "Modules"),
              const SizedBox(width: 10),
              const _HeaderStatCard(value: "78%", label: "Avg Score"),
            ],
          ),
        ],
      ),
    );
  }
}

class _NewsSectionHeader extends StatelessWidget {
  final VoidCallback onAllNews;
  final Future<void> Function() onRefresh;

  const _NewsSectionHeader({required this.onAllNews, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text(
          "LIVE CYBER NEWS",
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 15,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.8,
          ),
        ),
        const Spacer(),
        IconButton(
          onPressed: onRefresh,
          icon: const Icon(Icons.refresh),
          color: const Color(0xFF2563EB),
          tooltip: "Refresh news",
        ),
        GestureDetector(
          onTap: onAllNews,
          child: const Text(
            "All news",
            style: TextStyle(
              color: Color(0xFF2563EB),
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

class _HeaderStatCard extends StatelessWidget {
  final String value;
  final String label;

  const _HeaderStatCard({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 74,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 21,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String actionText;
  final VoidCallback? onTap;

  const _SectionHeader({
    required this.title,
    required this.actionText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 15,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.8,
          ),
        ),
        const Spacer(),
        if (actionText.isNotEmpty)
          GestureDetector(
            onTap: onTap,
            child: Text(
              actionText,
              style: const TextStyle(
                color: Color(0xFF2563EB),
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }
}

class _WeeklyStreakRow extends StatelessWidget {
  final int streak;

  const _WeeklyStreakRow({required this.streak});

  @override
  Widget build(BuildContext context) {
    final days = ["M", "T", "W", "T", "F", "S", "S"];

    return Row(
      children: List.generate(days.length, (index) {
        final isDone = index < streak.clamp(0, 7);
        final isToday = index == DateTime.now().weekday - 1;

        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 3),
            height: 38,
            decoration: BoxDecoration(
              color: isToday
                  ? const Color(0xFF2563EB)
                  : isDone
                  ? const Color(0xFF0D1B3E)
                  : const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(10),
              boxShadow: isToday
                  ? [
                      BoxShadow(
                        color: const Color(0xFF2563EB).withOpacity(0.4),
                        blurRadius: 12,
                      ),
                    ]
                  : [],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  isDone || isToday ? "✓" : "○",
                  style: TextStyle(
                    color: isDone || isToday ? Colors.white : Colors.grey,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  days[index],
                  style: TextStyle(
                    color: isDone || isToday ? Colors.white70 : Colors.grey,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

class _QuestCard extends StatelessWidget {
  final String icon;
  final String title;
  final String xp;
  final double progress;
  final VoidCallback onTap;

  const _QuestCard({
    required this.icon,
    required this.title,
    required this.xp,
    required this.progress,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final completed = progress >= 1.0;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(icon, style: const TextStyle(fontSize: 18)),
                  ),
                ),
                const Spacer(),
                Text(
                  xp,
                  style: const TextStyle(
                    color: Color(0xFF10B981),
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.w900,
                fontSize: 13,
                height: 1.05,
              ),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress,
              minHeight: 5,
              backgroundColor: const Color(0xFFE2E8F0),
              color: completed
                  ? const Color(0xFF10B981)
                  : const Color(0xFF2563EB),
              borderRadius: BorderRadius.circular(20),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecommendedCard extends StatelessWidget {
  final String title;
  final double score;
  final String reason;
  final VoidCallback onTap;

  const _RecommendedCard({
    required this.title,
    required this.score,
    required this.reason,
    required this.onTap,
  });

  bool get isPassword => title.toLowerCase().contains("password");
  bool get isPhishing => title.toLowerCase().contains("phishing");

  @override
  Widget build(BuildContext context) {
    final tag = isPhishing
        ? "PHISHING"
        : isPassword
        ? "PASSWORD"
        : "CYBER";

    final icon = isPhishing
        ? "🎣"
        : isPassword
        ? "🔐"
        : "🛡️";

    final badge = score > 0.75 ? "RECOMMENDED" : "WEAK AREA";

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: isPhishing
                    ? const Color(0xFFFEF2F2)
                    : const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(icon, style: const TextStyle(fontSize: 24)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: isPhishing
                          ? const Color(0xFFFEF2F2)
                          : const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      tag,
                      style: TextStyle(
                        color: isPhishing
                            ? const Color(0xFFDC2626)
                            : const Color(0xFF059669),
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Similarity ${score.toStringAsFixed(2)} · $reason",
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 10,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFE0F2FE),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Text(
                badge,
                style: const TextStyle(
                  color: Color(0xFF38BDF8),
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NewsCard extends StatelessWidget {
  final String icon;
  final String tag;
  final String title;
  final String source;
  final VoidCallback onTap;

  const _NewsCard({
    required this.icon,
    required this.tag,
    required this.title,
    required this.source,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final sourceText = source.length > 35
        ? "${source.substring(0, 35)}..."
        : source;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(icon, style: const TextStyle(fontSize: 24)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tag,
                    style: const TextStyle(
                      color: Color(0xFFDC2626),
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          sourceText,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          "+5 XP reading",
                          style: TextStyle(
                            color: Color(0xFF10B981),
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
