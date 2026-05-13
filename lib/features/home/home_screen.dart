import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/services/news_service.dart';
import '../learning/cubit/learning_cubit.dart';
import '../learning/learning_screen.dart';
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

    final notCompleted = learningState.modules.where((m) => !m.completed);
    final module = notCompleted.isNotEmpty
        ? notCompleted.first
        : learningState.modules.first;

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

    if (uri == null || url.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Invalid news link.")));
      return;
    }

    final rewarded = await context.read<HomeCubit>().rewardNewsRead(url);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          rewarded
              ? "+5 XP earned for reading cybersecurity news"
              : "You already earned XP for this news.",
        ),
      ),
    );

    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  String _cleanSource(dynamic source) {
    if (source == null) return "Online source";

    if (source is Map) {
      return source["name"]?.toString() ?? "Online source";
    }

    return source.toString();
  }

  double _safeProgress(double value) {
    return value.clamp(0.0, 1.0);
  }

  double _completeModuleQuest(HomeState state) {
    return _safeProgress(state.dailyModulesCompleted / 1);
  }

  double _score80Quest(HomeState state) {
    if (state.dailyQuizAttempts == 0) return 0.0;

    return _safeProgress(state.dailyBestQuizScore / 80);
  }

  double _newTopicQuest(HomeState state) {
    return _safeProgress(state.dailyTopicsTried / 1);
  }

  double _threatCheckerQuest(HomeState state) {
    return _safeProgress(state.dailyThreatChecks / 1);
  }

  String _questStatus(double progress) {
    return progress >= 1.0 ? "DONE" : "IN PROGRESS";
  }

  Future<void> _claimQuest(
    BuildContext context, {
    required String questId,
    required int xpReward,
  }) async {
    await context.read<HomeCubit>().claimDailyQuest(
      questId: questId,
      xpReward: xpReward,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Daily quest claimed: +$xpReward XP")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: SafeArea(
        child: BlocBuilder<HomeCubit, HomeState>(
          builder: (context, state) {
            final totalModules = context
                .watch<LearningCubit>()
                .state
                .modules
                .length;

            final completeModuleProgress = _completeModuleQuest(state);
            final score80Progress = _score80Quest(state);
            final newTopicProgress = _newTopicQuest(state);
            final threatProgress = _threatCheckerQuest(state);

            return RefreshIndicator(
              onRefresh: _refreshHomeNews,
              child: ListView(
                children: [
                  _HomeHeader(state: state, totalModules: totalModules),

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
                          childAspectRatio: 1.25,
                          children: [
                            _QuestCard(
                              icon: "📘",
                              title: "Complete 1\nmodule",
                              xp: "+10 XP",
                              status: _questStatus(completeModuleProgress),
                              progress: completeModuleProgress,
                              progressText:
                                  "${state.dailyModulesCompleted}/1 completed",
                              claimed: state.claimedDailyQuests.contains(
                                "complete_module",
                              ),
                              onClaim: () => _claimQuest(
                                context,
                                questId: "complete_module",
                                xpReward: 10,
                              ),
                              onTap: () => _openLearning(context),
                            ),

                            _QuestCard(
                              icon: "🎯",
                              title: "Score 80%+\nquiz",
                              xp: "+20 XP",
                              status: _questStatus(score80Progress),
                              progress: score80Progress,
                              progressText: state.dailyQuizAttempts == 0
                                  ? "No quiz today"
                                  : "${state.dailyBestQuizScore}% / 80%",
                              claimed: state.claimedDailyQuests.contains(
                                "score_80_quiz",
                              ),
                              onClaim: () => _claimQuest(
                                context,
                                questId: "score_80_quiz",
                                xpReward: 20,
                              ),
                              onTap: () => _openQuiz(context),
                            ),

                            _QuestCard(
                              icon: "⚡",
                              title: "Try 1 new\ntopic",
                              xp: "+15 XP",
                              status: _questStatus(newTopicProgress),
                              progress: newTopicProgress,
                              progressText:
                                  "${state.dailyTopicsTried}/1 topic today",
                              claimed: state.claimedDailyQuests.contains(
                                "try_new_topic",
                              ),
                              onClaim: () => _claimQuest(
                                context,
                                questId: "try_new_topic",
                                xpReward: 15,
                              ),
                              onTap: () => _openLearning(context),
                            ),

                            _QuestCard(
                              icon: "🛡️",
                              title: "Use threat\nchecker",
                              xp: "+25 XP",
                              status: _questStatus(threatProgress),
                              progress: threatProgress,
                              progressText:
                                  "${state.dailyThreatChecks}/1 checked today",
                              claimed: state.claimedDailyQuests.contains(
                                "threat_checker",
                              ),
                              onClaim: () => _claimQuest(
                                context,
                                questId: "threat_checker",
                                xpReward: 25,
                              ),
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

                        if (state.recommendedModules.isEmpty)
                          _EmptyCard(
                            text:
                                "Complete quizzes first to get personalised module recommendations.",
                            onTap: () => _openQuiz(context),
                          )
                        else
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
                              return const _LoadingCard();
                            }

                            if (snapshot.hasError) {
                              return _ErrorCard(
                                text: "News error: ${snapshot.error}",
                              );
                            }

                            final newsList = snapshot.data ?? [];

                            if (newsList.isEmpty) {
                              return const _EmptyCard(
                                text: "No relevant cybersecurity news found.",
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
  final int totalModules;

  const _HomeHeader({required this.state, required this.totalModules});

  String _getGreeting() {
    final hour = DateTime.now().hour;

    if (hour >= 5 && hour < 12) return "Good morning,";
    if (hour >= 12 && hour < 18) return "Good afternoon,";
    if (hour >= 18 && hour < 22) return "Good evening,";

    return "Good night,";
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
                  const _EmptyCard(text: "No notifications yet.")
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
              _HeaderStatCard(value: "$totalModules", label: "Modules"),
              const SizedBox(width: 10),
              _HeaderStatCard(value: "${state.avgScore}%", label: "Avg Score"),
            ],
          ),
        ],
      ),
    );
  }
}

class _WeeklyStreakRow extends StatelessWidget {
  final int streak;

  const _WeeklyStreakRow({required this.streak});

  @override
  Widget build(BuildContext context) {
    final days = ["M", "T", "W", "T", "F", "S", "S"];
    final todayIndex = DateTime.now().weekday - 1;
    final safeStreak = streak.clamp(0, 7);

    bool isStreakDay(int index) {
      if (safeStreak == 0) return false;

      for (int i = 0; i < safeStreak; i++) {
        final streakIndex = (todayIndex - i) % 7;

        if (index == streakIndex) return true;
      }

      return false;
    }

    return Row(
      children: List.generate(days.length, (index) {
        final isToday = index == todayIndex;
        final isDone = isStreakDay(index);

        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 3),
            height: 42,
            decoration: BoxDecoration(
              color: isToday
                  ? const Color(0xFF2563EB)
                  : isDone
                  ? const Color(0xFF0D1B3E)
                  : const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  isDone ? "✓" : "○",
                  style: TextStyle(
                    color: isDone || isToday ? Colors.white : Colors.grey,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  days[index],
                  style: TextStyle(
                    color: isDone || isToday ? Colors.white70 : Colors.grey,
                    fontSize: 10,
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
  final String status;
  final double progress;
  final String progressText;
  final bool claimed;
  final VoidCallback onClaim;
  final VoidCallback onTap;

  const _QuestCard({
    required this.icon,
    required this.title,
    required this.xp,
    required this.status,
    required this.progress,
    required this.progressText,
    required this.claimed,
    required this.onClaim,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final safeProgress = progress.clamp(0.0, 1.0);
    final completed = safeProgress >= 1.0;
    final canClaim = completed && !claimed;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: canClaim ? onClaim : onTap,
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: claimed
                ? const Color(0xFFE2E8F0)
                : completed
                ? const Color(0xFFBBF7D0)
                : const Color(0xFFE2E8F0),
            width: canClaim ? 1.5 : 1,
          ),
          boxShadow: canClaim
              ? [
                  BoxShadow(
                    color: const Color(0xFF10B981).withOpacity(0.12),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [],
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
                    color: canClaim
                        ? const Color(0xFFDCFCE7)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(icon, style: const TextStyle(fontSize: 18)),
                  ),
                ),

                const Spacer(),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: claimed
                        ? const Color(0xFFF1F5F9)
                        : canClaim
                        ? const Color(0xFFDCFCE7)
                        : const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    claimed
                        ? "CLAIMED"
                        : canClaim
                        ? "CLAIM"
                        : xp,
                    style: TextStyle(
                      color: claimed
                          ? const Color(0xFF64748B)
                          : canClaim
                          ? const Color(0xFF10B981)
                          : const Color(0xFF2563EB),
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                    ),
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

            const SizedBox(height: 4),

            Text(
              claimed ? "Reward claimed" : progressText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 8),

            LinearProgressIndicator(
              value: safeProgress,
              minHeight: 5,
              backgroundColor: const Color(0xFFE2E8F0),
              color: claimed
                  ? const Color(0xFF94A3B8)
                  : completed
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

  @override
  Widget build(BuildContext context) {
    return _SimpleCard(
      onTap: onTap,
      child: Row(
        children: [
          const _IconBox(icon: "🧠", bg: Color(0xFFECFDF5)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "$title\nreason · $reason",
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
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
    return _SimpleCard(
      onTap: onTap,
      child: Row(
        children: [
          _IconBox(icon: icon, bg: const Color(0xFFFEF2F2)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "$tag · $title\n$source · +5 XP reading",
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.w800,
              ),
            ),
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
          ),
        ),

        const Spacer(),

        IconButton(
          onPressed: onRefresh,
          icon: const Icon(Icons.refresh),
          color: const Color(0xFF2563EB),
        ),

        GestureDetector(
          onTap: onAllNews,
          child: const Text(
            "All news",
            style: TextStyle(
              color: Color(0xFF2563EB),
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
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }
}

class _SimpleCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _SimpleCard({required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    final card = Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: child,
    );

    if (onTap == null) return card;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: card,
    );
  }
}

class _IconBox extends StatelessWidget {
  final String icon;
  final Color bg;

  const _IconBox({required this.icon, required this.bg});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Center(child: Text(icon, style: const TextStyle(fontSize: 24))),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return const _SimpleCard(child: Center(child: CircularProgressIndicator()));
  }
}

class _ErrorCard extends StatelessWidget {
  final String text;

  const _ErrorCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return _SimpleCard(
      child: Text(text, style: const TextStyle(color: Colors.red)),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;

  const _EmptyCard({required this.text, this.onTap});

  @override
  Widget build(BuildContext context) {
    return _SimpleCard(
      onTap: onTap,
      child: Text(
        text,
        style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w600),
      ),
    );
  }
}
