import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/services/news_service.dart';
import '../learning/learning_screen.dart';
import '../leaderboard/leaderboard_screen.dart';
import '../news/news_screen.dart';
import '../quiz/cubit/quiz_cubit.dart';
import '../quiz/quiz_screen.dart';
import '../threat_checker/threat_checker_screen.dart';

import 'cubit/home_cubit.dart';
import 'cubit/home_state.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _openQuiz(BuildContext context) {
    final homeState = context.read<HomeCubit>().state;
    context.read<QuizCubit>().loadQuiz(homeState: homeState);

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

    if (uri == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Invalid news link.")));
      return;
    }

    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not open news link.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: SafeArea(
        child: BlocBuilder<HomeCubit, HomeState>(
          builder: (context, state) {
            return ListView(
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

                      _SectionHeader(
                        title: "LIVE CYBER NEWS",
                        actionText: "All news",
                        onTap: () => _openNews(context),
                      ),
                      const SizedBox(height: 8),

                      _LiveNewsSection(
                        onOpenNews: (url) => _openNewsUrl(context, url),
                      ),

                      const SizedBox(height: 90),
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

class _LiveNewsSection extends StatelessWidget {
  final void Function(String url) onOpenNews;

  const _LiveNewsSection({required this.onOpenNews});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: NewsService().fetchCyberNews(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE2E8F0)),
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
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Text("No relevant cybersecurity news found."),
          );
        }

        return Column(
          children: newsList.take(3).map((news) {
            return _NewsCard(
              icon: "📰",
              tag: "LIVE",
              title: news["title"]?.toString() ?? "Cybersecurity news",
              source: news["source"]?.toString() ?? "Online source",
              onTap: () => onOpenNews(news["url"]?.toString() ?? ""),
            );
          }).toList(),
        );
      },
    );
  }
}

class _HomeHeader extends StatelessWidget {
  final HomeState state;

  const _HomeHeader({required this.state});

  @override
  Widget build(BuildContext context) {
    final nextLevelXp = state.level * 100;
    final currentLevelStart = (state.level - 1) * 100;
    final currentProgress = state.xp - currentLevelStart;
    final neededProgress = nextLevelXp - currentLevelStart;
    final progressValue = neededProgress == 0
        ? 0.0
        : (currentProgress / neededProgress).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0D1B3E), Color(0xFF1E3A8A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
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
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Good morning,",
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    Text(
                      "Farhana 👋",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
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
        final isToday = index == 4;

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
                          source,
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
