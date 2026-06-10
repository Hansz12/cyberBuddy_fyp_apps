import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'cubit/learning_cubit.dart';
import 'cubit/learning_state.dart';
import 'module_detail_screen.dart';

class LearningScreen extends StatefulWidget {
  const LearningScreen({super.key});

  @override
  State<LearningScreen> createState() => _LearningScreenState();
}

class _LearningScreenState extends State<LearningScreen> {
  String selectedFilter = "All topics";
  String searchQuery = "";

  final TextEditingController _searchController = TextEditingController();

  final List<String> filters = const [
    "All topics",
    "Phishing",
    "Password",
    "Malware",
    "Privacy",
    "Scam",
    "Mobile",
    "Social",
    "Network",
    "Banking",
    "Ethics",
  ];

  @override
  void initState() {
    super.initState();
    context.read<LearningCubit>().loadModules();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  IconData _topicIcon(String topic) {
    switch (topic.toLowerCase()) {
      case "phishing":
        return Icons.phishing;
      case "password":
        return Icons.lock;
      case "social":
        return Icons.psychology;
      case "malware":
        return Icons.bug_report;
      case "privacy":
        return Icons.visibility;
      case "scam":
        return Icons.attach_money;
      case "mobile":
        return Icons.phone_android;
      case "network":
        return Icons.wifi;
      case "banking":
        return Icons.account_balance;
      case "ethics":
        return Icons.groups;
      default:
        return Icons.security;
    }
  }

  Color _topicColor(String topic) {
    switch (topic.toLowerCase()) {
      case "phishing":
        return const Color(0xFFFFE4E6);
      case "password":
        return const Color(0xFFEFF6FF);
      case "social":
        return const Color(0xFFF3E8FF);
      case "malware":
        return const Color(0xFFFEF3C7);
      case "privacy":
        return const Color(0xFFFCE7F3);
      case "scam":
        return const Color(0xFFECFDF5);
      case "mobile":
        return const Color(0xFFE0F2FE);
      case "network":
        return const Color(0xFFE0F7FA);
      case "banking":
        return const Color(0xFFDBEAFE);
      case "ethics":
        return const Color(0xFFF1F5F9);
      default:
        return const Color(0xFFF1F5F9);
    }
  }

  Color _progressColor(String topic) {
    switch (topic.toLowerCase()) {
      case "phishing":
        return const Color(0xFFEF4444);
      case "password":
        return const Color(0xFF10B981);
      case "social":
        return const Color(0xFF8B5CF6);
      case "malware":
        return const Color(0xFFF59E0B);
      case "privacy":
        return const Color(0xFFD946EF);
      case "scam":
        return const Color(0xFF10B981);
      case "mobile":
        return const Color(0xFF38BDF8);
      case "network":
        return const Color(0xFF06B6D4);
      case "banking":
        return const Color(0xFF2563EB);
      case "ethics":
        return const Color(0xFF64748B);
      default:
        return const Color(0xFF2563EB);
    }
  }

  Color _difficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case "beginner":
        return const Color(0xFF10B981);
      case "intermediate":
        return const Color(0xFF2563EB);
      case "advanced":
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF64748B);
    }
  }

  double _moduleProgress(LearningModule module) {
    return module.completed ? 1.0 : 0.0;
  }

  String _progressText(LearningModule module) {
    if (module.completed) return "Completed ✓";
    return "Not started";
  }

  String _estimatedTime(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case "beginner":
        return "5 mins";
      case "intermediate":
        return "8 mins";
      case "advanced":
        return "12 mins";
      default:
        return "6 mins";
    }
  }

  String _difficultyBadge(LearningModule module) {
    if (module.completed) return "✓ Done";

    switch (module.difficulty.toLowerCase()) {
      case "beginner":
        return "Beginner";
      case "intermediate":
        return "Intermediate";
      case "advanced":
        return "Advanced";
      default:
        return "New";
    }
  }

  List<LearningModule> _filteredModules(List<LearningModule> modules) {
    final query = searchQuery.trim().toLowerCase();

    final sortedModules = [...modules];
    sortedModules.sort((a, b) {
      const levelOrder = {'Beginner': 0, 'Intermediate': 1, 'Advanced': 2};

      final levelA = levelOrder[a.difficulty] ?? 99;
      final levelB = levelOrder[b.difficulty] ?? 99;

      if (levelA != levelB) return levelA.compareTo(levelB);
      if (a.completed == b.completed) return a.title.compareTo(b.title);
      return a.completed ? 1 : -1;
    });

    return sortedModules.where((module) {
      final topic = module.topic.toLowerCase();
      final title = module.title.toLowerCase();
      final content = module.content.toLowerCase();
      final difficulty = module.difficulty.toLowerCase();

      final matchesFilter = selectedFilter == "All topics"
          ? true
          : topic == selectedFilter.toLowerCase() ||
                title.contains(selectedFilter.toLowerCase());

      final matchesSearch = query.isEmpty
          ? true
          : title.contains(query) ||
                topic.contains(query) ||
                content.contains(query) ||
                difficulty.contains(query);

      return matchesFilter && matchesSearch;
    }).toList();
  }

  List<LearningModule> _modulesByDifficulty(
    List<LearningModule> modules,
    String difficulty,
  ) {
    return modules
        .where((m) => m.difficulty.toLowerCase() == difficulty.toLowerCase())
        .toList();
  }

  LearningModule? _continueModule(List<LearningModule> modules) {
    final notCompleted = modules.where((module) => !module.completed).toList();
    if (notCompleted.isNotEmpty) return notCompleted.first;
    return null;
  }

  int _topicCount(List<LearningModule> modules) {
    return modules.map((module) => module.topic.toLowerCase()).toSet().length;
  }

  int _completedCount(List<LearningModule> modules) {
    return modules.where((module) => module.completed).length;
  }

  void _openModule(BuildContext context, LearningModule module) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ModuleDetailScreen(module: module)),
    );
  }

  void _showModulePreview(BuildContext context, LearningModule module) {
    final color = _difficultyColor(module.difficulty);
    final icon = _topicIcon(module.topic);
    final description = module.content.isEmpty
        ? "Cybersecurity learning module"
        : module.content.split(".").first;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return Container(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
          decoration: const BoxDecoration(
            color: Color(0xFFF8FAFC),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 46,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                const SizedBox(height: 18),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0D1B3E), Color(0xFF1E3A8A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.14),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Icon(icon, color: Colors.white, size: 30),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              module.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 19,
                                fontWeight: FontWeight.w900,
                                height: 1.15,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "${module.topic.toUpperCase()} · ${module.difficulty.toUpperCase()}",
                              style: const TextStyle(
                                color: Color(0xFF93C5FD),
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: _PreviewInfoBox(
                        icon: Icons.signal_cellular_alt,
                        title: "Level",
                        value: module.difficulty,
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _PreviewInfoBox(
                        icon: Icons.topic,
                        title: "Topic",
                        value: module.topic,
                        color: const Color(0xFF2563EB),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(
                      child: _PreviewInfoBox(
                        icon: Icons.timer,
                        title: "Time",
                        value: _estimatedTime(module.difficulty),
                        color: const Color(0xFF0EA5E9),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _PreviewInfoBox(
                        icon: Icons.bolt,
                        title: "Reward",
                        value: module.completed
                            ? "Done"
                            : "+${module.xpReward} XP",
                        color: const Color(0xFFF59E0B),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Text(
                    description,
                    style: const TextStyle(
                      color: Color(0xFF475569),
                      fontSize: 14,
                      height: 1.45,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _openModule(context, module);
                    },
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text("Start Learning"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  "Tip: Long press a module card to preview it.",
                  style: TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLearningCard(BuildContext context, LearningModule module) {
    return _LearningCard(
      module: module,
      icon: _topicIcon(module.topic),
      iconColor: _topicColor(module.topic),
      progressColor: _progressColor(module.topic),
      difficultyColor: _difficultyColor(module.difficulty),
      progress: _moduleProgress(module),
      progressText: _progressText(module),
      badge: _difficultyBadge(module),
      onTap: () => _openModule(context, module),
      onLongPress: () => _showModulePreview(context, module),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: SafeArea(
        child: BlocBuilder<LearningCubit, LearningState>(
          builder: (context, state) {
            if (state.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state.modules.isEmpty) {
              return const Center(
                child: Text(
                  "No learning modules found.",
                  style: TextStyle(color: Colors.grey),
                ),
              );
            }

            final filteredModules = _filteredModules(state.modules);
            final continueModule = _continueModule(state.modules);
            final completedCount = _completedCount(state.modules);

            final beginnerModules = _modulesByDifficulty(
              filteredModules,
              "Beginner",
            );
            final intermediateModules = _modulesByDifficulty(
              filteredModules,
              "Intermediate",
            );
            final advancedModules = _modulesByDifficulty(
              filteredModules,
              "Advanced",
            );

            return Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(18, 28, 18, 22),
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
                      const Text(
                        "Learning Hub",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        "${state.modules.length} modules · ${_topicCount(state.modules)} cybersecurity topics · $completedCount completed",
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 18),
                      TextField(
                        controller: _searchController,
                        onChanged: (value) {
                          setState(() => searchQuery = value);
                        },
                        style: const TextStyle(color: Colors.white),
                        cursorColor: const Color(0xFF38BDF8),
                        decoration: InputDecoration(
                          hintText: "Search modules, topics, difficulty...",
                          hintStyle: const TextStyle(
                            color: Colors.white54,
                            fontSize: 14,
                          ),
                          prefixIcon: const Icon(
                            Icons.search,
                            color: Color(0xFF38BDF8),
                          ),
                          suffixIcon: searchQuery.isEmpty
                              ? null
                              : IconButton(
                                  icon: const Icon(
                                    Icons.close,
                                    color: Colors.white70,
                                  ),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {
                                      searchQuery = "";
                                    });
                                  },
                                ),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.12),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 14,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: const BorderSide(color: Colors.white24),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: const BorderSide(
                              color: Color(0xFF38BDF8),
                              width: 1.4,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(
                  height: 58,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    scrollDirection: Axis.horizontal,
                    itemBuilder: (context, index) {
                      final filter = filters[index];
                      final selected = selectedFilter == filter;

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedFilter = filter;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: selected
                                ? const Color(0xFF0D1B3E)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: selected
                                  ? const Color(0xFF0D1B3E)
                                  : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Text(
                            filter,
                            style: TextStyle(
                              color: selected
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      );
                    },
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemCount: filters.length,
                  ),
                ),

                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 95),
                    children: [
                      if (continueModule != null &&
                          selectedFilter == "All topics" &&
                          searchQuery.trim().isEmpty) ...[
                        const _LearningSectionTitle("CONTINUE LEARNING"),
                        const SizedBox(height: 10),
                        _buildLearningCard(context, continueModule),
                        const SizedBox(height: 18),
                      ],

                      if (filteredModules.isEmpty) const _EmptyLearningCard(),

                      if (beginnerModules.isNotEmpty) ...[
                        const _LearningLevelHeader(
                          title: "BEGINNER",
                          icon: Icons.school,
                          color: Color(0xFF10B981),
                        ),
                        const SizedBox(height: 10),
                        ...beginnerModules.map(
                          (module) => _buildLearningCard(context, module),
                        ),
                        const SizedBox(height: 18),
                      ],

                      if (intermediateModules.isNotEmpty) ...[
                        const _LearningLevelHeader(
                          title: "INTERMEDIATE",
                          icon: Icons.trending_up,
                          color: Color(0xFF2563EB),
                        ),
                        const SizedBox(height: 10),
                        ...intermediateModules.map(
                          (module) => _buildLearningCard(context, module),
                        ),
                        const SizedBox(height: 18),
                      ],

                      if (advancedModules.isNotEmpty) ...[
                        const _LearningLevelHeader(
                          title: "ADVANCED",
                          icon: Icons.workspace_premium,
                          color: Color(0xFFEF4444),
                        ),
                        const SizedBox(height: 10),
                        ...advancedModules.map(
                          (module) => _buildLearningCard(context, module),
                        ),
                      ],
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

class _PreviewInfoBox extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _PreviewInfoBox({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });


  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _LearningLevelHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;

  const _LearningLevelHeader({
    required this.title,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Text(
            title,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}

class _LearningSectionTitle extends StatelessWidget {
  final String title;

  const _LearningSectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: Color(0xFF0F172A),
        fontSize: 15,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.8,
      ),
    );
  }
}

class _LearningCard extends StatelessWidget {
  final LearningModule module;
  final IconData icon;
  final Color iconColor;
  final Color progressColor;
  final Color difficultyColor;
  final double progress;
  final String progressText;
  final String badge;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _LearningCard({
    required this.module,
    required this.icon,
    required this.iconColor,
    required this.progressColor,
    required this.difficultyColor,
    required this.progress,
    required this.progressText,
    required this.badge,
    required this.onTap,
    required this.onLongPress,
  });

  String _estimateTime(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case "beginner":
        return "5 mins";
      case "intermediate":
        return "8 mins";
      case "advanced":
        return "12 mins";
      default:
        return "6 mins";
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDone = module.completed;
    final safeProgress = progress.clamp(0.0, 1.0);

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDone ? const Color(0xFFBBF7D0) : const Color(0xFFE2E8F0),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: iconColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: const Color(0xFF0D1B3E), size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    module.title,
                    style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    module.content.isEmpty
                        ? "Cybersecurity learning module"
                        : module.content.split(".").first,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 12,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  LinearProgressIndicator(
                    value: safeProgress,
                    minHeight: 6,
                    color: isDone ? const Color(0xFF10B981) : progressColor,
                    backgroundColor: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              progressText,
                              style: const TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "+${module.xpReward} XP · ${_estimateTime(module.difficulty)}",
                              style: const TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: isDone
                              ? const Color(0xFFDCFCE7)
                              : difficultyColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          badge,
                          style: TextStyle(
                            color: isDone
                                ? const Color(0xFF059669)
                                : difficultyColor,
                            fontSize: 11,
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

class _EmptyLearningCard extends StatelessWidget {
  const _EmptyLearningCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: const Column(
        children: [
          Icon(Icons.search_off, size: 38, color: Colors.grey),
          SizedBox(height: 10),
          Text(
            "No module found",
            style: TextStyle(
              color: Color(0xFF0F172A),
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
          SizedBox(height: 6),
          Text(
            "Try another keyword or topic filter.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
