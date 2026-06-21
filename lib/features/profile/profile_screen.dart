import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../auth/splash_screen.dart';
import '../home/cubit/home_cubit.dart';
import '../home/cubit/home_state.dart';
import '../learning/cubit/learning_cubit.dart';
import '../learning/module_detail_screen.dart';
import '../../data/services/profile_image_service.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? user;
  final ProfileImageService _profileImageService = ProfileImageService();
  File? _profileImage;

  static const _achievementDetails = <String, _AchievementDetail>{
    'Rookie Badge': _AchievementDetail(
      category: 'Getting Started',
      description: 'Your first step into becoming a stronger cyber defender.',
      condition: 'Answer at least one quiz question or earn your first XP.',
    ),
    'Beginner Defender': _AchievementDetail(
      category: 'Progress',
      description: 'You are building a solid foundation in cyber safety.',
      condition: 'Reach 100 total XP.',
    ),
    'Intermediate Defender': _AchievementDetail(
      category: 'Progress',
      description: 'You have shown steady growth across CyberBuddy challenges.',
      condition: 'Reach 300 total XP.',
    ),
    'Cyber Hero': _AchievementDetail(
      category: 'Progress',
      description: 'A strong milestone for an active cyber learner.',
      condition: 'Reach 500 total XP.',
    ),
    'Cyber Champion': _AchievementDetail(
      category: 'Progress',
      description: 'You have reached champion-level commitment to cyber safety.',
      condition: 'Reach 1,000 total XP.',
    ),
    'Consistent Learner': _AchievementDetail(
      category: 'Engagement',
      description: 'You keep showing up and building safer habits.',
      condition: 'Maintain a 3-day activity streak.',
    ),
    '7-Day Streak': _AchievementDetail(
      category: 'Engagement',
      description: 'One full week of consistent cybersecurity learning.',
      condition: 'Maintain a 7-day activity streak.',
    ),
    'Quiz Starter': _AchievementDetail(
      category: 'Quiz Mastery',
      description: 'You have completed your first CyberBuddy quiz.',
      condition: 'Complete 1 quiz attempt.',
    ),
    'Quiz Master': _AchievementDetail(
      category: 'Quiz Mastery',
      description: 'You have built experience through repeated challenges.',
      condition: 'Complete 5 quiz attempts.',
    ),
    'Perfect Score': _AchievementDetail(
      category: 'Quiz Mastery',
      description: 'A flawless run—every answer was the safest move.',
      condition: 'Get 100% on any quiz attempt.',
    ),
    'Phishing Shield': _AchievementDetail(
      category: 'Phishing Awareness',
      description: 'You can spot phishing signals and choose safer actions.',
      condition: 'Reach 70% progress in the phishing topic.',
    ),
    'Password Pro': _AchievementDetail(
      category: 'Account Security',
      description: 'You understand strong passwords and safer account habits.',
      condition: 'Reach 80% progress in the password topic.',
    ),
    'Malware Hunter': _AchievementDetail(
      category: 'Device Safety',
      description: 'You can recognise malware risks and safe installation habits.',
      condition: 'Reach 70% progress in the malware topic.',
    ),
    'Privacy Guardian': _AchievementDetail(
      category: 'Privacy',
      description: 'You know how to protect personal data and manage sharing.',
      condition: 'Reach 70% progress in the privacy topic.',
    ),
    'Threat Spotter': _AchievementDetail(
      category: 'Threat Checking',
      description: 'You actively practise identifying suspicious cyber threats.',
      condition: 'Complete 5 threat checks.',
    ),
  };

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    await FirebaseAuth.instance.currentUser?.reload();
    final profileImage = await _profileImageService.loadImage();

    if (!mounted) return;

    setState(() {
      user = FirebaseAuth.instance.currentUser;
      _profileImage = profileImage;
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

    attempted.sort((a, b) => b.value.compareTo(a.value));

    return attempted.take(3).map((e) => _titleCase(e.key)).join(" • ");
  }

  String _difficultyPreference(HomeState state) {
    if (state.level >= 8) return "Advanced";
    if (state.level >= 4) return "Intermediate";
    return "Beginner";
  }

  String _recommendationReason(HomeState state) {
    if (state.recommendedModules.isEmpty) {
      return "Complete quizzes first so CyberBuddy can generate a personalised recommendation.";
    }

    final weakest = _getWeakestTopic(state);

    return "Recommended based on your current weakest area, $weakest. This module helps improve your cybersecurity awareness through related learning content.";
  }

  String _confidenceLevel(HomeState state) {
    if (state.totalQuestionsAnswered == 0) return "Not available";
    if (state.totalQuestionsAnswered < 5) return "Low";
    if (state.totalQuestionsAnswered < 15) return "Medium";
    return "High";
  }

  String _matchScore(HomeState state) {
    if (state.recommendedModules.isEmpty) {
      return "0%";
    }

    final answered = state.totalQuestionsAnswered;

    if (answered < 5) {
      return "78%";
    }

    if (answered < 15) {
      return "86%";
    }

    return "92%";
  }

  Future<void> _editProfile() async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const EditProfileScreen()),
    );

    if (!mounted) return;

    await _loadUser();

    if (!mounted || updated != true) return;
    _showSnack("Profile updated successfully.");
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
      builder: (dialogContext) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 50,
                  width: 50,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFE4E6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.restart_alt_rounded,
                    color: Color(0xFFDC2626),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Reset Progress?',
                  style: TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'This will reset your XP, level, streak, badges, topic progress, quiz scores, recommendations and notifications. This action cannot be undone.',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () =>
                            Navigator.of(dialogContext).pop(false),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          foregroundColor: const Color(0xFF475569),
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () =>
                            Navigator.of(dialogContext).pop(true),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          backgroundColor: const Color(0xFFDC2626),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Reset'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (confirm != true) return;
    if (!mounted) return;

    final homeCubit = context.read<HomeCubit>();
    await homeCubit.resetProgress();

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

  void _showBadgeInfo(String title, {required bool isUnlocked}) {
    final detail = _achievementDetails[title] ??
        const _AchievementDetail(
          category: 'CyberBuddy Achievement',
          description: 'A milestone earned through your CyberBuddy learning journey.',
          condition: 'Keep completing learning activities and quizzes.',
        );

    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    height: 76,
                    width: 76,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEFF6FF),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      _badgeEmoji(title),
                      style: const TextStyle(fontSize: 38),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _AchievementChip(
                      label: isUnlocked ? 'UNLOCKED' : 'NEXT ACHIEVEMENT',
                      color: isUnlocked
                          ? const Color(0xFF16A34A)
                          : const Color(0xFFF97316),
                    ),
                    _AchievementChip(
                      label: detail.category,
                      color: const Color(0xFF0369A1),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  detail.description,
                  style: const TextStyle(
                    color: Color(0xFF475569),
                    fontSize: 15,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isUnlocked ? 'HOW YOU UNLOCKED IT' : 'HOW TO UNLOCK IT',
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.7,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        detail.condition,
                        style: const TextStyle(
                          color: Color(0xFF0F172A),
                          fontWeight: FontWeight.w800,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3A8A),
                      foregroundColor: Colors.white,
                    ),
                    child: Text(isUnlocked ? 'Awesome!' : 'I’ll get it!'),
                  ),
                ),
              ],
            ),
          ),
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
    final recommendedModuleId = homeState.recommendedModuleIds.isNotEmpty
        ? homeState.recommendedModuleIds.first
        : "";

    final module = learningState.modules.firstWhere(
      (m) {
        final matchesId =
            recommendedModuleId.trim().isNotEmpty &&
            m.id.toLowerCase().trim() ==
                recommendedModuleId.toLowerCase().trim();
        final matchesTitle =
            m.title.toLowerCase().trim() ==
            recommendedTitle.toLowerCase().trim();

        return matchesId || matchesTitle;
      },
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
    final lockedBadges = _achievementDetails.keys
        .where((badge) => !homeState.badges.contains(badge))
        .toList();

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
                      backgroundImage: _profileImage == null
                          ? null
                          : FileImage(_profileImage!),
                      child: _profileImage == null
                          ? Text(
                              getInitials(),
                              style: const TextStyle(
                                fontSize: 34,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF0D1B3E),
                              ),
                            )
                          : null,
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!hasBadges)
                            const Text(
                              'Your first achievement is waiting—complete a module or answer a quiz question to begin.',
                              style: TextStyle(
                                color: Colors.grey,
                                fontWeight: FontWeight.w600,
                                height: 1.4,
                              ),
                            )
                          else ...[
                            _BadgeGroupLabel(
                              label: 'UNLOCKED',
                              count: homeState.badges.length,
                              color: const Color(0xFF16A34A),
                            ),
                            const SizedBox(height: 10),
                            GridView.count(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisCount: 4,
                              childAspectRatio: 0.82,
                              children: homeState.badges.map((badge) {
                                return _BadgeItem(
                                  _badgeEmoji(badge),
                                  badge.replaceAll(' ', '\n'),
                                  onTap: () =>
                                      _showBadgeInfo(badge, isUnlocked: true),
                                );
                              }).toList(),
                            ),
                          ],
                          if (lockedBadges.isNotEmpty) ...[
                            const SizedBox(height: 18),
                            _BadgeGroupLabel(
                              label: 'NEXT ACHIEVEMENTS',
                              count: lockedBadges.length,
                              color: const Color(0xFFF97316),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Tap any locked badge to see your next target.',
                              style: TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 10),
                            GridView.count(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisCount: 4,
                              childAspectRatio: 0.82,
                              children: lockedBadges.map((badge) {
                                return _LockedBadgeItem(
                                  emoji: _badgeEmoji(badge),
                                  title: badge.replaceAll(' ', '\n'),
                                  onTap: () => _showBadgeInfo(
                                    badge,
                                    isUnlocked: false,
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _SectionCard(
                      title: "📊 Cybersecurity Analytics",
                      child: Column(
                        children: [
                          _InfoRow(
                            label: "🏆 Strongest Topic",
                            value: _getStrongestTopic(homeState),
                            valueColor: Colors.green,
                          ),
                          _InfoRow(
                            label: "⚠ Weakest Topic",
                            value: _getWeakestTopic(homeState),
                            valueColor: Colors.red,
                          ),
                          _InfoRow(
                            label: "📈 Recent Quiz Accuracy",
                            value: "${homeState.avgScore}%",
                            valueColor: Colors.blue,
                          ),
                          _InfoRow(
                            label: "🎯 Recommendation",
                            value: homeState.recommendedModules.isNotEmpty
                                ? homeState.recommendedModules.first
                                : "Not available",
                            valueColor: Colors.deepPurple,
                          ),
                          _InfoRow(
                            label: "🧠 Preferred Topics",
                            value: _preferredTopics(homeState),
                          ),
                          _InfoRow(
                            label: "📚 Learning Level",
                            value: _difficultyPreference(homeState),
                          ),
                        ],
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
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEFF6FF),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Text(
                                      "CONTENT-BASED RECOMMENDATION",
                                      style: TextStyle(
                                        color: Color(0xFF2563EB),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 16),

                                  _InfoRow(
                                    label: "🎯 Recommended Module",
                                    value: homeState.recommendedModules.first,
                                    valueColor: Colors.blue,
                                  ),

                                  _InfoRow(
                                    label: "📝 Reason",
                                    value: _recommendationReason(homeState),
                                  ),

                                  _InfoRow(
                                    label: "📊 Confidence",
                                    value: _confidenceLevel(homeState),
                                    valueColor: Colors.green,
                                  ),

                                  _InfoRow(
                                    label: "🎯 Match Score",
                                    value: _matchScore(homeState),
                                    valueColor: Colors.orange,
                                  ),

                                  _InfoRow(
                                    label: "🧠 Method",
                                    value: "Topic-based content matching",
                                    valueColor: Colors.deepPurple,
                                  ),

                                  _InfoRow(
                                    label: "🔄 Last Updated",
                                    value: "Today",
                                  ),

                                  const SizedBox(height: 12),

                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(13),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: const Color(0xFFE2E8F0),
                                      ),
                                    ),
                                    child: const Text(
                                      "Tap this card to open the recommended module.",
                                      style: TextStyle(
                                        color: Color(0xFF64748B),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
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

class _AchievementDetail {
  final String category;
  final String description;
  final String condition;

  const _AchievementDetail({
    required this.category,
    required this.description,
    required this.condition,
  });
}

class _AchievementChip extends StatelessWidget {
  final String label;
  final Color color;

  const _AchievementChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w900,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _BadgeGroupLabel extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _BadgeGroupLabel({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          height: 8,
          width: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 7),
        Text(
          '$label ($count)',
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.7,
          ),
        ),
      ],
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

class _LockedBadgeItem extends StatelessWidget {
  final String emoji;
  final String title;
  final VoidCallback onTap;

  const _LockedBadgeItem({
    required this.emoji,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Opacity(
        opacity: 0.72,
        child: Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  height: 54,
                  width: 54,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Opacity(
                    opacity: 0.28,
                    child: Text(emoji, style: const TextStyle(fontSize: 24)),
                  ),
                ),
                Container(
                  height: 26,
                  width: 26,
                  decoration: const BoxDecoration(
                    color: Color(0xFF475569),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.lock_rounded, size: 15, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ignore: unused_element
class _ProgressRow extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _ProgressRow({
    required this.label,
    required this.value,
    required this.color,
  });

  String _status(double value) {
    final percent = (value * 100).round();

    if (percent < 50) return "Weak";
    if (percent < 70) return "Improving";
    if (percent < 85) return "Good";
    return "Excellent";
  }

  Color _statusColor(double value) {
    final percent = (value * 100).round();

    if (percent < 50) return const Color(0xFFEF4444);
    if (percent < 70) return const Color(0xFFF59E0B);
    if (percent < 85) return const Color(0xFF2563EB);
    return const Color(0xFF10B981);
  }

  @override
  Widget build(BuildContext context) {
    final safeValue = value.clamp(0.0, 1.0);
    final percent = (safeValue * 100).round();
    final status = _status(safeValue);
    final statusColor = _statusColor(safeValue);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(Icons.insights, color: statusColor, size: 22),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 7),
                LinearProgressIndicator(
                  value: safeValue,
                  minHeight: 7,
                  backgroundColor: const Color(0xFFE2E8F0),
                  color: statusColor,
                  borderRadius: BorderRadius.circular(20),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "$percent%",
                style: TextStyle(
                  color: statusColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                status,
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
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
