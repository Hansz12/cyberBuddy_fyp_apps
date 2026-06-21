import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../home/cubit/home_cubit.dart';
import '../quiz/cubit/quiz_cubit.dart';
import '../quiz/quiz_screen.dart';
import 'cubit/learning_cubit.dart';
import 'cubit/learning_state.dart';

class ModuleVideo {
  final String moduleId;
  final String videoCategory;
  final String videoTitle;
  final String videoUrl;
  final String videoSource;
  final String videoDuration;

  const ModuleVideo({
    required this.moduleId,
    required this.videoCategory,
    required this.videoTitle,
    required this.videoUrl,
    required this.videoSource,
    required this.videoDuration,
  });

  factory ModuleVideo.fromJson(Map<String, dynamic> json) {
    return ModuleVideo(
      moduleId: json["module_id"]?.toString() ?? "",
      videoCategory: json["video_category"]?.toString() ?? "",
      videoTitle: json["video_title"]?.toString() ?? "Quick Cyber Guide",
      videoUrl: json["video_url"]?.toString() ?? "",
      videoSource: json["video_source"]?.toString() ?? "YouTube",
      videoDuration: json["video_duration"]?.toString() ?? "3-5 mins",
    );
  }

  String get thumbnailUrl {
    final uri = Uri.tryParse(videoUrl);
    final videoId = uri?.queryParameters["v"];

    if (videoId == null || videoId.isEmpty) return "";

    return "https://img.youtube.com/vi/$videoId/hqdefault.jpg";
  }
}

class ModuleDetailScreen extends StatelessWidget {
  final LearningModule module;

  const ModuleDetailScreen({super.key, required this.module});

  Color _topicColor(String topic) {
    switch (topic.toLowerCase()) {
      case "phishing":
        return const Color(0xFFEF4444);
      case "password":
        return const Color(0xFF10B981);
      case "social":
        return const Color(0xFF7C3AED);
      case "malware":
        return const Color(0xFFF59E0B);
      case "privacy":
        return const Color(0xFFD946EF);
      case "scam":
        return const Color(0xFF2563EB);
      case "mobile":
        return const Color(0xFF38BDF8);
      case "network":
        return const Color(0xFF0EA5E9);
      case "ethics":
        return const Color(0xFF8B5CF6);
      case "banking":
        return const Color(0xFF0284C7);
      default:
        return const Color(0xFF2563EB);
    }
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
      case "ethics":
        return Icons.groups;
      case "banking":
        return Icons.account_balance;
      default:
        return Icons.security;
    }
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

  List<String> _contentPoints(String content, String title) {
    final cleaned = content.trim();

    if (cleaned.isEmpty) {
      return [
        "Understand the main cybersecurity risk related to $title.",
        "Identify warning signs before taking any action.",
        "Apply safe digital behaviour in real-life situations.",
      ];
    }

    final points = cleaned
        .split(".")
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    if (points.isEmpty) {
      return [
        "Understand the main cybersecurity risk related to $title.",
        "Identify warning signs before taking any action.",
        "Apply safe digital behaviour in real-life situations.",
      ];
    }

    return points;
  }

  List<String> _actionPoints(String topic) {
    switch (topic.toLowerCase()) {
      case "phishing":
        return [
          "Check sender address and URL before clicking any link.",
          "Open official websites manually instead of using suspicious links.",
          "Report phishing emails or messages when possible.",
        ];
      case "password":
        return [
          "Use strong and unique passwords for each account.",
          "Avoid using birthdays, names, or repeated passwords.",
          "Enable multi-factor authentication whenever possible.",
        ];
      case "malware":
        return [
          "Avoid downloading cracked apps or unknown APK files.",
          "Install apps only from trusted stores or official websites.",
          "Keep your operating system and apps updated.",
        ];
      case "privacy":
        return [
          "Review app permissions before allowing access.",
          "Avoid sharing personal information publicly online.",
          "Use privacy settings to limit who can view your data.",
        ];
      case "banking":
        return [
          "Never share OTP, TAC, PIN, or banking password.",
          "Verify banking links through the official app or website.",
          "Contact the bank using official customer service numbers.",
        ];
      default:
        return [
          "Verify suspicious messages through official channels.",
          "Avoid sharing passwords, OTP, banking details, or private information.",
          "Report suspicious links, messages, or files when possible.",
        ];
    }
  }

  List<Map<String, String>> _quickTips(String topic) {
    switch (topic.toLowerCase()) {
      case "phishing":
        return [
          {
            "title": "Check Sender",
            "desc":
                "Always verify the sender email address before clicking links.",
          },
          {
            "title": "Avoid Urgency",
            "desc": "Phishing messages often pressure you to act quickly.",
          },
          {
            "title": "Use Official Site",
            "desc":
                "Open the official website manually instead of using links.",
          },
        ];
      case "password":
        return [
          {
            "title": "Use MFA",
            "desc":
                "Multi-factor authentication adds another layer of protection.",
          },
          {
            "title": "Unique Password",
            "desc": "Never reuse the same password for different accounts.",
          },
          {
            "title": "Avoid Personal Info",
            "desc":
                "Do not use birthdays, names, or phone numbers as passwords.",
          },
        ];
      case "malware":
        return [
          {
            "title": "Avoid Unknown Apps",
            "desc":
                "Do not install APK files or cracked software from unknown sources.",
          },
          {
            "title": "Update Device",
            "desc": "Security updates help protect against malware attacks.",
          },
          {
            "title": "Scan Files",
            "desc":
                "Be careful with files from emails, USB drives, or unknown links.",
          },
        ];
      default:
        return [
          {
            "title": "Verify First",
            "desc":
                "Always verify suspicious messages through official channels.",
          },
          {
            "title": "Protect Data",
            "desc":
                "Do not share passwords, OTP, banking details, or private data.",
          },
          {
            "title": "Report Issues",
            "desc":
                "Report suspicious links, messages, or files when possible.",
          },
        ];
    }
  }

  void _showTip(BuildContext context, String title, String desc) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title),
        content: Text(desc),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Got it"),
          ),
        ],
      ),
    );
  }

  void _startQuiz(BuildContext context, LearningModule currentModule) {
    if (currentModule.id.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Module ID not found.")));
      return;
    }

    context.read<QuizCubit>().loadQuiz(currentModule.id);

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const QuizScreen()),
    );
  }

  Future<void> _confirmCompleteModule(
    BuildContext context,
    LearningModule currentModule,
  ) async {
    if (currentModule.completed) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Complete Module?"),
        content: Text(
          "Mark this module as completed and earn +${currentModule.xpReward} XP?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Complete"),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      await _completeModule(context, currentModule);
    }
  }

  Future<void> _completeModule(
    BuildContext context,
    LearningModule currentModule,
  ) async {
    await context.read<LearningCubit>().completeModule(currentModule.id);
    await context.read<HomeCubit>().recordModuleCompleted(currentModule.id);
    await context.read<HomeCubit>().gainXP(currentModule.xpReward);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "🎉 Module completed! +${currentModule.xpReward} XP earned.",
          ),
        ),
      );

      Navigator.pop(context);
    }
  }

  LearningModule _getLatestModule(BuildContext context) {
    final modules = context.watch<LearningCubit>().state.modules;

    try {
      return modules.firstWhere((m) => m.id == module.id);
    } catch (_) {
      return module;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentModule = _getLatestModule(context);
    final color = _topicColor(currentModule.topic);

    final overviewText = currentModule.content.trim().isEmpty
        ? "This module helps you learn important cybersecurity practices related to ${currentModule.title.toLowerCase()}."
        : currentModule.content;

    final points = _contentPoints(
      currentModule.content,
      currentModule.title.toLowerCase(),
    );

    final actions = _actionPoints(currentModule.topic);
    final tips = _quickTips(currentModule.topic);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
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
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                    color: Colors.white,
                    padding: EdgeInsets.zero,
                    alignment: Alignment.centerLeft,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 62,
                    height: 62,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: color.withOpacity(0.4)),
                    ),
                    child: Icon(
                      _topicIcon(currentModule.topic),
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    currentModule.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _HeaderChip(
                        text: currentModule.difficulty,
                        icon: Icons.bar_chart,
                      ),
                      _HeaderChip(
                        text: "+${currentModule.xpReward} XP",
                        icon: Icons.bolt,
                      ),
                      _HeaderChip(
                        text: _estimatedTime(currentModule.difficulty),
                        icon: Icons.timer,
                      ),
                      if (currentModule.completed)
                        const _HeaderChip(
                          text: "Completed",
                          icon: Icons.check_circle,
                        ),
                    ],
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
                children: [
                  _VideoPreviewCard(
                    moduleId: currentModule.id,
                    topic: currentModule.topic,
                  ),
                  const SizedBox(height: 14),

                  _InfoCard(
                    title: "Module Overview",
                    child: Text(
                      overviewText,
                      style: const TextStyle(
                        color: Color(0xFF475569),
                        fontSize: 14,
                        height: 1.45,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  _StatsGrid(
                    level: currentModule.difficulty,
                    topic: currentModule.topic,
                    xp: currentModule.xpReward,
                    time: _estimatedTime(currentModule.difficulty),
                  ),

                  const SizedBox(height: 14),

                  _InfoCard(
                    title: "Quick Tips",
                    child: SizedBox(
                      height: 92,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: tips.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (context, index) {
                          final tip = tips[index];

                          return _QuickTipCard(
                            title: tip["title"] ?? "",
                            onTap: () => _showTip(
                              context,
                              tip["title"] ?? "",
                              tip["desc"] ?? "",
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  _InfoCard(
                    title: "Key Learning Points",
                    child: Column(
                      children: points.take(5).map((point) {
                        return _LearningPoint(text: point);
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 14),

                  _InfoCard(
                    title: "What You Should Do",
                    child: Column(
                      children: actions.map((point) {
                        return _LearningPoint(text: point);
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),

            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _startQuiz(context, currentModule),
                      icon: const Icon(Icons.quiz),
                      label: const Text("Start Module Quiz"),
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
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: currentModule.completed
                          ? null
                          : () =>
                                _confirmCompleteModule(context, currentModule),
                      icon: Icon(
                        currentModule.completed
                            ? Icons.check_circle
                            : Icons.check_circle_outline,
                      ),
                      label: Text(
                        currentModule.completed
                            ? "Module Completed"
                            : "Mark as Completed",
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: currentModule.completed
                            ? const Color(0xFF10B981)
                            : const Color(0xFF0D1B3E),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(
                          color: currentModule.completed
                              ? const Color(0xFF10B981)
                              : const Color(0xFF0D1B3E),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
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

class _VideoPreviewCard extends StatefulWidget {
  final String moduleId;
  final String topic;

  const _VideoPreviewCard({required this.moduleId, required this.topic});

  @override
  State<_VideoPreviewCard> createState() => _VideoPreviewCardState();
}

class _VideoPreviewCardState extends State<_VideoPreviewCard> {
  late Future<ModuleVideo?> _videoFuture;

  @override
  void initState() {
    super.initState();
    _videoFuture = _loadModuleVideo(widget.moduleId);
  }

  @override
  void didUpdateWidget(covariant _VideoPreviewCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.moduleId != widget.moduleId) {
      _videoFuture = _loadModuleVideo(widget.moduleId);
    }
  }

  Future<ModuleVideo?> _loadModuleVideo(String moduleId) async {
    try {
      final jsonString = await rootBundle.loadString(
        "assets/data/module_videos.json",
      );

      final decoded = jsonDecode(jsonString);

      if (decoded is! List) return null;

      for (final item in decoded) {
        if (item is Map<String, dynamic> &&
            item["module_id"]?.toString() == moduleId) {
          return ModuleVideo.fromJson(item);
        }
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _openVideo(BuildContext context, ModuleVideo? video) async {
    if (video == null || video.videoUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Video is not available for this module."),
        ),
      );
      return;
    }

    final uri = Uri.parse(video.videoUrl);

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Unable to open video link.")),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Unable to open video link.")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ModuleVideo?>(
      future: _videoFuture,
      builder: (context, snapshot) {
        final video = snapshot.data;

        return InkWell(
          onTap: () => _openVideo(context, video),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            height: 175,
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F172A).withOpacity(0.18),
                  blurRadius: 14,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                children: [
                  if (video != null && video.thumbnailUrl.isNotEmpty)
                    Positioned.fill(
                      child: Image.network(
                        video.thumbnailUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) {
                          return Container(color: const Color(0xFF1E293B));
                        },
                      ),
                    ),
                  Positioned.fill(
                    child: Container(
                      color: const Color(0xFF0F172A).withOpacity(0.45),
                    ),
                  ),
                  const Center(
                    child: Icon(
                      Icons.play_circle_fill_rounded,
                      color: Colors.white,
                      size: 64,
                    ),
                  ),
                  Positioned(
                    right: 16,
                    top: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.14),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Text(
                        video?.videoDuration ?? "3-5 mins",
                        style: const TextStyle(
                          color: Color(0xFFBFDBFE),
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 16,
                    bottom: 14,
                    right: 16,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.video_library,
                        color: Color(0xFF93C5FD),
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Quick Visual Guide · ${widget.topic.toUpperCase()}",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFFBFDBFE),
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              video?.videoTitle ?? "Tap to watch on YouTube",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF93C5FD),
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final String level;
  final String topic;
  final int xp;
  final String time;

  const _StatsGrid({
    required this.level,
    required this.topic,
    required this.xp,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatBox(icon: Icons.bar_chart, label: "Level", value: level),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatBox(icon: Icons.topic, label: "Topic", value: topic),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatBox(icon: Icons.bolt, label: "Reward", value: "+$xp XP"),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatBox(icon: Icons.timer, label: "Time", value: time),
        ),
      ],
    );
  }
}

class _StatBox extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatBox({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 96,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF2563EB), size: 20),
          const Spacer(),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 10,
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
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickTipCard extends StatelessWidget {
  final String title;
  final VoidCallback onTap;

  const _QuickTipCard({required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 135,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.lightbulb, color: Color(0xFFF59E0B)),
            const Spacer(),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderChip extends StatelessWidget {
  final String text;
  final IconData icon;

  const _HeaderChip({required this.text, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.13),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFF38BDF8), size: 15),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _InfoCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 13,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.7,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _LearningPoint extends StatelessWidget {
  final String text;

  const _LearningPoint({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 18),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFF475569),
                fontSize: 13,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
