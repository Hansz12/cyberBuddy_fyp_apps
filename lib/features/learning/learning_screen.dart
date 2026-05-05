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
    "Malware",
    "Password",
    "Privacy",
    "Scam",
    "Mobile",
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
    switch (topic) {
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
      default:
        return Icons.security;
    }
  }

  Color _topicColor(String topic) {
    switch (topic) {
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
      default:
        return const Color(0xFFF1F5F9);
    }
  }

  Color _progressColor(String topic) {
    switch (topic) {
      case "phishing":
        return const Color(0xFFEF4444);
      case "password":
        return const Color(0xFF10B981);
      case "malware":
        return const Color(0xFFF59E0B);
      case "privacy":
        return const Color(0xFFD946EF);
      case "scam":
        return const Color(0xFF10B981);
      case "mobile":
        return const Color(0xFF38BDF8);
      default:
        return const Color(0xFF2563EB);
    }
  }

  double _moduleProgress(LearningModule module) {
    if (module.completed) return 1.0;

    switch (module.topic) {
      case "phishing":
        return 0.75;
      case "malware":
        return 0.50;
      case "privacy":
        return 0.25;
      default:
        return 0.0;
    }
  }

  String _progressText(LearningModule module) {
    final progress = _moduleProgress(module);
    final percent = (progress * 100).round();

    if (module.completed) return "4/4 modules · Complete ✓";
    if (percent == 0) return "0/4 modules · Not started";

    final done = (progress * 4).round();
    return "$done/4 modules · $percent%";
  }

  String _difficultyBadge(LearningModule module) {
    if (module.completed) return "✓ Done";
    if (module.topic == "phishing") return "Advanced next";
    if (module.topic == "malware") return "Intermediate";
    if (module.topic == "privacy") return "Beginner";
    return "New";
  }

  List<LearningModule> _filteredModules(List<LearningModule> modules) {
    final query = searchQuery.trim().toLowerCase();

    return modules.where((module) {
      final matchesFilter = selectedFilter == "All topics"
          ? true
          : module.topic.toLowerCase() == selectedFilter.toLowerCase() ||
                module.title.toLowerCase().contains(
                  selectedFilter.toLowerCase(),
                );

      final matchesSearch = query.isEmpty
          ? true
          : module.title.toLowerCase().contains(query) ||
                module.topic.toLowerCase().contains(query) ||
                module.content.toLowerCase().contains(query);

      return matchesFilter && matchesSearch;
    }).toList();
  }

  LearningModule? _continueModule(List<LearningModule> modules) {
    final inProgress = modules.where((module) {
      final progress = _moduleProgress(module);
      return progress > 0 && progress < 1.0;
    }).toList();

    if (inProgress.isNotEmpty) return inProgress.first;
    if (modules.isNotEmpty) return modules.first;

    return null;
  }

  int _topicCount(List<LearningModule> modules) {
    return modules.map((module) => module.topic).toSet().length;
  }

  void _openModule(BuildContext context, LearningModule module) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ModuleDetailScreen(module: module)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: SafeArea(
        child: BlocBuilder<LearningCubit, LearningState>(
          builder: (context, state) {
            if (state.modules.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            final filteredModules = _filteredModules(state.modules);
            final continueModule = _continueModule(state.modules);

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
                        "${state.modules.length} modules · ${_topicCount(state.modules)} cybersecurity topics",
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
                          hintText: "Search modules, topics...",
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
                                    setState(() => searchQuery = "");
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
                          setState(() => selectedFilter = filter);
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
                      if (continueModule != null) ...[
                        const _LearningSectionTitle("CONTINUE LEARNING"),
                        const SizedBox(height: 10),
                        _LearningCard(
                          module: continueModule,
                          icon: _topicIcon(continueModule.topic),
                          iconColor: _topicColor(continueModule.topic),
                          progressColor: _progressColor(continueModule.topic),
                          progress: _moduleProgress(continueModule),
                          progressText: _progressText(continueModule),
                          badge: _difficultyBadge(continueModule),
                          onTap: () => _openModule(context, continueModule),
                        ),
                        const SizedBox(height: 18),
                      ],

                      const _LearningSectionTitle("ALL TOPICS"),
                      const SizedBox(height: 10),

                      if (filteredModules.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: const Text(
                            "No module found. Try another keyword or filter.",
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      else
                        ...filteredModules.map((module) {
                          return _LearningCard(
                            module: module,
                            icon: _topicIcon(module.topic),
                            iconColor: _topicColor(module.topic),
                            progressColor: _progressColor(module.topic),
                            progress: _moduleProgress(module),
                            progressText: _progressText(module),
                            badge: _difficultyBadge(module),
                            onTap: () => _openModule(context, module),
                          );
                        }),
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
  final double progress;
  final String progressText;
  final String badge;
  final VoidCallback onTap;

  const _LearningCard({
    required this.module,
    required this.icon,
    required this.iconColor,
    required this.progressColor,
    required this.progress,
    required this.progressText,
    required this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDone = module.completed;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE2E8F0)),
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
                    module.content.split(".").first,
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
                    value: progress,
                    minHeight: 6,
                    color: isDone ? const Color(0xFF10B981) : progressColor,
                    backgroundColor: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          progressText,
                          style: const TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
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
                              : progressColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          badge,
                          style: TextStyle(
                            color: isDone
                                ? const Color(0xFF059669)
                                : progressColor,
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
