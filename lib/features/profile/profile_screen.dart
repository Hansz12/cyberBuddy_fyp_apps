import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/services/profile_image_service.dart';
import '../auth/splash_screen.dart';
import '../home/cubit/home_cubit.dart';
import '../home/cubit/home_state.dart';
import '../learning/cubit/learning_cubit.dart';
import '../learning/cubit/learning_state.dart';
import '../learning/module_detail_screen.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const _blue = Color(0xFF2563EB);

  final ProfileImageService _profileImageService = ProfileImageService();
  User? _user;
  File? _profileImage;
  StreamSubscription<User?>? _userSubscription;
  String? _cachedName;
  String? _cachedEmail;

  static const _cachedNameKey = 'profile_cached_name';
  static const _cachedEmailKey = 'profile_cached_email';

  static const _achievementDetails = <String, _AchievementDetail>{
    'Rookie Badge': _AchievementDetail(
      category: 'Getting Started',
      description: 'Your first step into becoming a stronger cyber defender.',
      condition: 'Answer one quiz question or earn your first XP.',
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
      condition: 'Complete one quiz attempt.',
    ),
    'Quiz Master': _AchievementDetail(
      category: 'Quiz Mastery',
      description: 'You have built experience through repeated challenges.',
      condition: 'Complete five quiz attempts.',
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
      condition: 'Complete five threat checks.',
    ),
  };

  @override
  void initState() {
    super.initState();
    _userSubscription = FirebaseAuth.instance.userChanges().listen(
      _onUserChanged,
    );
    _loadUser();
  }

  Future<void> _loadUser() async {
    // Reload may fail while Firebase is restoring a saved session or when
    // the device is offline. Never let that erase an otherwise valid profile.
    final userBeforeReload = FirebaseAuth.instance.currentUser;
    try {
      await userBeforeReload?.reload();
    } catch (_) {}

    File? image;
    try {
      image = await _profileImageService.loadImage();
    } catch (_) {}

    final preferences = await SharedPreferences.getInstance();
    final currentUser = FirebaseAuth.instance.currentUser ?? userBeforeReload;
    if (currentUser != null) {
      await _cacheUserIdentity(currentUser, preferences: preferences);
    }

    if (!mounted) return;

    setState(() {
      // Firebase can temporarily report null during native session recovery.
      // Keep the visible user instead of flashing to Guest User.
      _user = currentUser ?? _user;
      _cachedName = preferences.getString(_cachedNameKey);
      _cachedEmail = preferences.getString(_cachedEmailKey);
      _profileImage = image ?? _profileImage;
    });
  }

  Future<void> _onUserChanged(User? user) async {
    if (user == null) return;

    await _cacheUserIdentity(user);
    File? image;
    try {
      image = await _profileImageService.loadImage();
    } catch (_) {}
    if (!mounted) return;

    setState(() {
      _user = user;
      _cachedName = _displayNameFor(user);
      _cachedEmail = user.email;
      _profileImage = image ?? _profileImage;
    });
  }

  String _displayNameFor(User user) {
    final displayName = user.displayName?.trim();
    if (displayName != null && displayName.isNotEmpty) return displayName;

    final email = user.email;
    if (email != null && email.contains('@')) return email.split('@').first;
    return 'CyberBuddy User';
  }

  Future<void> _cacheUserIdentity(
    User user, {
    SharedPreferences? preferences,
  }) async {
    final prefs = preferences ?? await SharedPreferences.getInstance();
    await prefs.setString(_cachedNameKey, _displayNameFor(user));
    if (user.email != null && user.email!.isNotEmpty) {
      await prefs.setString(_cachedEmailKey, user.email!);
    }
  }

  Future<void> _clearCachedIdentity() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_cachedNameKey);
    await preferences.remove(_cachedEmailKey);
  }

  String get _name {
    final displayName = _user?.displayName?.trim();
    if (displayName != null && displayName.isNotEmpty) return displayName;

    if (_cachedName != null && _cachedName!.isNotEmpty) return _cachedName!;

    final email = _user?.email;
    if (email != null && email.contains('@')) return email.split('@').first;
    if (_cachedEmail != null && _cachedEmail!.contains('@')) {
      return _cachedEmail!.split('@').first;
    }
    return _user == null ? 'Guest User' : 'CyberBuddy User';
  }

  String get _email => _user?.email ?? _cachedEmail ?? 'Not signed in';

  String get _initials {
    final words = _name.split(RegExp(r'\s+')).where((word) => word.isNotEmpty);
    return words.take(2).map((word) => word[0]).join().toUpperCase();
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  String _titleCase(String value) {
    if (value.isEmpty) return 'Not available';
    return value[0].toUpperCase() + value.substring(1);
  }

  IconData _badgeIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('phishing')) return Icons.mark_email_read_rounded;
    if (lower.contains('password')) return Icons.key_rounded;
    if (lower.contains('streak')) return Icons.local_fire_department_rounded;
    if (lower.contains('quiz')) return Icons.emoji_events_rounded;
    if (lower.contains('perfect')) return Icons.star_rounded;
    if (lower.contains('malware')) return Icons.bug_report_rounded;
    if (lower.contains('privacy')) return Icons.visibility_rounded;
    if (lower.contains('threat')) return Icons.radar_rounded;
    if (lower.contains('rookie')) return Icons.eco_rounded;
    if (lower.contains('champion')) return Icons.workspace_premium_rounded;
    if (lower.contains('defender')) return Icons.shield_rounded;
    return Icons.military_tech_rounded;
  }

  Color _badgeColor(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('phishing') || lower.contains('privacy')) {
      return const Color(0xFF7C3AED);
    }
    if (lower.contains('malware') || lower.contains('threat')) {
      return const Color(0xFFDC2626);
    }
    if (lower.contains('streak')) return const Color(0xFFEA580C);
    if (lower.contains('quiz') || lower.contains('perfect')) {
      return const Color(0xFFD97706);
    }
    return _blue;
  }

  String _badgeEmoji(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('phishing')) return '🛡️';
    if (lower.contains('password')) return '🔐';
    if (lower.contains('streak')) return '🔥';
    if (lower.contains('quiz')) return '🏆';
    if (lower.contains('perfect')) return '⭐';
    if (lower.contains('malware')) return '🦠';
    if (lower.contains('privacy')) return '👁️';
    if (lower.contains('threat')) return '🎯';
    if (lower.contains('rookie')) return '🌱';
    if (lower.contains('champion')) return '💎';
    if (lower.contains('defender')) return '🛡️';
    return '🏅';
  }

  String _strongestTopic(HomeState state) {
    final topics = state.topicAnswered.entries
        .where((entry) => entry.value > 0)
        .map((entry) => entry.key)
        .toList();
    if (topics.isEmpty) return 'Complete a quiz to unlock';
    topics.sort((a, b) => state.topicProgress(b).compareTo(state.topicProgress(a)));
    return _titleCase(topics.first);
  }

  String _weakestTopic(HomeState state) {
    final topics = state.topicAnswered.entries
        .where((entry) => entry.value > 0)
        .map((entry) => entry.key)
        .toList();
    if (topics.isEmpty) return 'No data yet';
    topics.sort((a, b) => state.topicProgress(a).compareTo(state.topicProgress(b)));
    return _titleCase(topics.first);
  }

  Future<void> _editProfile() async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const EditProfileScreen()),
    );
    if (!mounted) return;
    await _loadUser();
    if (updated == true) _showSnack('Profile updated successfully.');
  }

  Future<void> _changePassword() async {
    final email = FirebaseAuth.instance.currentUser?.email;
    if (email == null || email.isEmpty) {
      _showSnack('No email address is available for this account.');
      return;
    }

    await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
    if (mounted) _showSnack('Password reset email sent to $email.');
  }

  Future<void> _resetProgress() async {
    final shouldReset = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.restart_alt_rounded, color: Color(0xFFDC2626)),
        title: const Text('Reset progress?'),
        content: const Text(
          'Your XP, badges, streak, quiz scores and recommendations will be reset. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (shouldReset != true || !mounted) return;

    await Future.wait([
      context.read<HomeCubit>().resetProgress(),
      context.read<LearningCubit>().resetLearningProgress(),
    ]);
    if (mounted) _showSnack('Your progress has been reset.');
  }

  void _openNotifications() {
    context.read<HomeCubit>().markNotificationsAsRead();
    final notifications = context.read<HomeCubit>().state.notifications;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      showDragHandle: true,
      builder: (sheetContext) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.72,
        minChildSize: 0.42,
        maxChildSize: 0.92,
        builder: (context, scrollController) => SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Notifications',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: notifications.isEmpty
                      ? const Center(
                          child: _EmptyState(
                            icon: Icons.notifications_none_rounded,
                            text: 'No notifications yet.',
                          ),
                        )
                      : ListView.separated(
                          controller: scrollController,
                          itemCount: notifications.length,
                          separatorBuilder: (_, __) =>
                              const Divider(height: 1),
                          itemBuilder: (_, index) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const CircleAvatar(
                              backgroundColor: Color(0xFFEFF6FF),
                              child: Icon(
                                Icons.notifications_rounded,
                                color: _blue,
                              ),
                            ),
                            title: Text(notifications[index]),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openHelp() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.support_agent_rounded, color: _blue),
        title: const Text('Help & Support'),
        content: const Text(
          'CyberBuddy helps you practise cybersecurity awareness through learning modules, quizzes, threat checks and personalised recommendations.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showBadgeInfo(String badge, {required bool isUnlocked}) {
    final detail = _achievementDetails[badge] ??
        const _AchievementDetail(
          category: 'CyberBuddy Achievement',
          description: 'A milestone earned through your CyberBuddy learning journey.',
          condition: 'Keep completing learning activities and quizzes.',
        );
    final color = _badgeColor(badge);

    showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _BadgeGlyph(icon: _badgeIcon(badge), color: color, size: 72),
              const SizedBox(height: 18),
              Text(
                badge,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                detail.category,
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              _Tag(
                label: isUnlocked ? 'UNLOCKED' : 'NEXT MILESTONE',
                color: isUnlocked ? const Color(0xFF16A34A) : const Color(0xFFEA580C),
              ),
              const SizedBox(height: 16),
              Text(detail.description, style: const TextStyle(height: 1.45)),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isUnlocked ? 'HOW YOU EARNED IT' : 'HOW TO UNLOCK',
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(detail.condition, style: const TextStyle(fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Done'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAllBadges(HomeState state) {
    final locked = _achievementDetails.keys
        .where((badge) => !state.badges.contains(badge))
        .toList();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      showDragHandle: true,
      builder: (sheetContext) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.78,
        minChildSize: 0.5,
        maxChildSize: 0.92,
        builder: (_, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
          children: [
            const Text('All achievements', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text('${state.badges.length} unlocked', style: const TextStyle(color: Color(0xFF64748B))),
            const SizedBox(height: 20),
            _BadgeSection(
              title: 'Unlocked',
              color: const Color(0xFF16A34A),
              badges: state.badges,
              isUnlocked: true,
              onTap: _showBadgeInfo,
            ),
            if (locked.isNotEmpty) ...[
              const SizedBox(height: 22),
              _BadgeSection(
                title: 'Next milestones',
                color: const Color(0xFFEA580C),
                badges: locked,
                isUnlocked: false,
                onTap: _showBadgeInfo,
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _openRecommendedModule(HomeState homeState) {
    final learningState = context.read<LearningCubit>().state;
    final moduleId = homeState.recommendedModuleIds.isEmpty
        ? null
        : homeState.recommendedModuleIds.first;
    if (moduleId == null || learningState.modules.isEmpty) return;

    final module = learningState.modules.firstWhere(
      (item) => item.id == moduleId,
      orElse: () => learningState.modules.first,
    );
    Navigator.push(context, MaterialPageRoute(builder: (_) => ModuleDetailScreen(module: module)));
  }

  Future<void> _logout() async {
    context.read<HomeCubit>().clearSession();
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {}
    await FirebaseAuth.instance.signOut();
    await _clearCachedIdentity();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const SplashScreen()),
      (_) => false,
    );
  }

  @override
  void dispose() {
    _userSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final homeState = context.watch<HomeCubit>().state;
    final learningState = context.watch<LearningCubit>().state;
    return _buildClassicProfile(context, homeState, learningState);
  }

  Widget _buildClassicProfile(
    BuildContext context,
    HomeState homeState,
    LearningState learningState,
  ) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: SafeArea(
        child: RefreshIndicator(
          color: const Color(0xFF2563EB),
          onRefresh: _loadUser,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
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
                      radius: 46,
                      backgroundColor: Colors.white,
                      backgroundImage: _profileImage == null
                          ? null
                          : FileImage(_profileImage!),
                      child: _profileImage == null
                          ? Text(
                              _initials,
                              style: const TextStyle(
                                color: Color(0xFF0D1B3E),
                                fontSize: 35,
                                fontWeight: FontWeight.w900,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _email,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70, fontSize: 15),
                    ),
                    const SizedBox(height: 14),
                    FilledButton.icon(
                      onPressed: _editProfile,
                      icon: const Icon(Icons.edit_outlined, size: 17),
                      label: const Text('Edit Profile'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.14),
                        foregroundColor: const Color(0xFF67E8F9),
                        textStyle: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _ClassicHeaderBadge(
                          icon: Icons.shield_outlined,
                          text: 'LV ${homeState.level} • Threat Spotter',
                        ),
                        _ClassicHeaderBadge(
                          icon: Icons.local_fire_department_rounded,
                          text: '${homeState.streak}-day streak',
                          green: true,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Transform.translate(
                offset: const Offset(0, -20),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    children: [
                      _ClassicStatCard(title: 'XP', value: '${homeState.xp}'),
                      _ClassicStatCard(title: 'Modules', value: '${learningState.modules.length}'),
                      _ClassicStatCard(title: 'Score', value: '${homeState.avgScore}%'),
                      _ClassicStatCard(title: 'Badges', value: '${homeState.badges.length}'),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    _ClassicRecommendationProfileCard(
                      state: homeState,
                      onTap: homeState.recommendedModuleIds.isEmpty
                          ? null
                          : () => _openRecommendedModule(homeState),
                    ),
                    _ClassicSectionCard(
                      title: 'Progress Snapshot',
                      icon: Icons.insights_rounded,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Based on your latest quiz performance',
                            style: TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          _ClassicInfoRow(label: 'Strongest Topic', value: _strongestTopic(homeState), color: Colors.green),
                          _ClassicInfoRow(label: 'Focus Area', value: _weakestTopic(homeState), color: Colors.red),
                          _ClassicInfoRow(label: 'Quiz Accuracy', value: '${homeState.avgScore}%', color: Colors.blue),
                        ],
                      ),
                    ),
                    _ClassicSectionCard(
                      title: 'Achievements',
                      icon: Icons.workspace_premium_rounded,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _ClassicBadgeLabel(
                            label: 'UNLOCKED',
                            count: homeState.badges.length,
                            color: const Color(0xFF16A34A),
                          ),
                          const SizedBox(height: 12),
                          if (homeState.badges.isEmpty)
                            const _ClassicEmptyBadges()
                          else
                            _ClassicBadgeGrid(
                              badges: homeState.badges.take(4).toList(),
                              unlocked: true,
                              emojiForBadge: _badgeEmoji,
                              onTap: _showBadgeInfo,
                            ),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () => _showAllBadges(homeState),
                              icon: const Icon(Icons.workspace_premium_outlined),
                              label: const Text('View All Achievements'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF2563EB),
                                side: const BorderSide(color: Color(0xFFBFDBFE)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    _ClassicSectionCard(
                      title: 'Account',
                      icon: Icons.settings_rounded,
                      child: Column(
                        children: [
                          _CompactActionTile(icon: Icons.lock_outline, title: 'Change Password', onTap: _changePassword),
                          _CompactActionTile(icon: Icons.notifications_none, title: 'Notifications', onTap: _openNotifications),
                          _CompactActionTile(icon: Icons.help_outline, title: 'Help & Support', onTap: _openHelp),
                        ],
                      ),
                    ),
                    _ClassicSectionCard(
                      title: 'Danger Zone',
                      icon: Icons.warning_amber_rounded,
                      child: Column(
                        children: [
                          _CompactActionTile(icon: Icons.restart_alt, title: 'Reset Progress', color: Colors.orange, onTap: _resetProgress),
                          _CompactActionTile(icon: Icons.logout, title: 'Logout', color: Colors.red, onTap: _logout),
                        ],
                      ),
                    ),
                    const SizedBox(height: 110),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Kept temporarily while the original visual layout above is the active one.
  // ignore: unused_element
  Widget _buildModernProfile(BuildContext context) {
    final homeState = context.watch<HomeCubit>().state;
    final completedModules = homeState.completedModules.length;
    final hasRecommendation = homeState.recommendedModules.isNotEmpty;
    final previewBadges = homeState.badges.take(6).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      body: SafeArea(
        child: RefreshIndicator(
          color: _blue,
          onRefresh: _loadUser,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              _ProfileHero(
                name: _name,
                email: _email,
                initials: _initials,
                image: _profileImage,
                level: homeState.level,
                streak: homeState.streak,
                onEdit: _editProfile,
              ),
              const SizedBox(height: 20),
              _SectionHeading(title: 'Your progress'),
              const SizedBox(height: 10),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 2.2,
                children: [
                  _MetricCard(icon: Icons.bolt_rounded, color: const Color(0xFF7C3AED), value: '${homeState.xp}', label: 'Total XP'),
                  _MetricCard(icon: Icons.menu_book_rounded, color: _blue, value: '$completedModules', label: 'Modules completed'),
                  _MetricCard(icon: Icons.insights_rounded, color: const Color(0xFF16A34A), value: '${homeState.avgScore}%', label: 'Average score'),
                  _MetricCard(icon: Icons.workspace_premium_rounded, color: const Color(0xFFD97706), value: '${homeState.badges.length}', label: 'Badges earned'),
                ],
              ),
              const SizedBox(height: 24),
              _Panel(
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.workspace_premium_outlined, color: _blue),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text('Achievements', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                        ),
                        TextButton(
                          onPressed: () => _showAllBadges(homeState),
                          child: const Text('View all'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (previewBadges.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: _EmptyState(
                          icon: Icons.emoji_events_outlined,
                          text: 'Complete a quiz or module to earn your first badge.',
                        ),
                      )
                    else
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: previewBadges.length,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: 0.9,
                        ),
                        itemBuilder: (_, index) {
                          final badge = previewBadges[index];
                          return _BadgePreview(
                            title: badge,
                            icon: _badgeIcon(badge),
                            color: _badgeColor(badge),
                            onTap: () => _showBadgeInfo(badge, isUnlocked: true),
                          );
                        },
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _Panel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SectionHeading(title: 'Learning snapshot'),
                    const SizedBox(height: 12),
                    _InsightRow(icon: Icons.emoji_events_outlined, label: 'Strongest topic', value: _strongestTopic(homeState), color: const Color(0xFF16A34A)),
                    _InsightRow(icon: Icons.flag_outlined, label: 'Focus next', value: _weakestTopic(homeState), color: const Color(0xFFEA580C)),
                    _InsightRow(icon: Icons.fact_check_outlined, label: 'Questions answered', value: '${homeState.totalQuestionsAnswered}', color: _blue),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (hasRecommendation)
                _RecommendationCard(
                  title: homeState.recommendedModules.first,
                  onTap: () => _openRecommendedModule(homeState),
                )
              else
                const _RecommendationEmptyCard(),
              const SizedBox(height: 24),
              const _SectionHeading(title: 'Account'),
              const SizedBox(height: 10),
              _Panel(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _AccountAction(icon: Icons.person_outline_rounded, label: 'Edit profile', onTap: _editProfile),
                    _AccountAction(icon: Icons.lock_outline_rounded, label: 'Change password', onTap: _changePassword),
                    _AccountAction(icon: Icons.notifications_none_rounded, label: 'Notifications', onTap: _openNotifications),
                    _AccountAction(icon: Icons.support_agent_rounded, label: 'Help & support', onTap: _openHelp),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _Panel(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _AccountAction(icon: Icons.restart_alt_rounded, label: 'Reset progress', color: const Color(0xFFEA580C), onTap: _resetProgress),
                    _AccountAction(icon: Icons.logout_rounded, label: 'Log out', color: const Color(0xFFDC2626), onTap: _logout),
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

class _ClassicHeaderBadge extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool green;

  const _ClassicHeaderBadge({
    required this.icon,
    required this.text,
    this.green = false,
  });

  @override
  Widget build(BuildContext context) {
    final accent = green ? const Color(0xFF6EE7B7) : const Color(0xFF67E8F9);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: accent, size: 20),
          const SizedBox(width: 9),
          Text(
            text,
            style: TextStyle(color: accent, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _ClassicStatCard extends StatelessWidget {
  final String title;
  final String value;

  const _ClassicStatCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 3),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF111827),
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClassicSectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _ClassicSectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF2563EB), size: 25),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF111827),
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

class _ClassicBadgeLabel extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _ClassicBadgeLabel({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 9),
        Text(
          '$label ($count)',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w900,
            fontSize: 13,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

class _ClassicBadgeGrid extends StatelessWidget {
  final List<String> badges;
  final bool unlocked;
  final String Function(String) emojiForBadge;
  final void Function(String, {required bool isUnlocked}) onTap;

  const _ClassicBadgeGrid({
    required this.badges,
    required this.unlocked,
    required this.emojiForBadge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: badges.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 12,
        crossAxisSpacing: 8,
        childAspectRatio: 0.72,
      ),
      itemBuilder: (_, index) {
        final badge = badges[index];
        return Opacity(
          opacity: unlocked ? 1 : 0.52,
          child: InkWell(
            onTap: () => onTap(badge, isUnlocked: unlocked),
            borderRadius: BorderRadius.circular(15),
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      height: 58,
                      width: 58,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        emojiForBadge(badge),
                        style: const TextStyle(fontSize: 27),
                      ),
                    ),
                    if (!unlocked)
                      const CircleAvatar(
                        radius: 13,
                        backgroundColor: Color(0xFF475569),
                        child: Icon(Icons.lock_rounded, color: Colors.white, size: 14),
                      ),
                  ],
                ),
                const SizedBox(height: 7),
                Text(
                  badge.replaceAll(' ', '\n'),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF273244),
                    height: 1.28,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ClassicEmptyBadges extends StatelessWidget {
  const _ClassicEmptyBadges();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Text(
        'Your first achievement is waiting—complete a module or answer a quiz question to begin.',
        style: TextStyle(color: Color(0xFF64748B), height: 1.4),
      ),
    );
  }
}

class _ClassicInfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _ClassicInfoRow({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.w700))),
          const SizedBox(width: 12),
          Flexible(child: Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.right, style: TextStyle(color: color, fontWeight: FontWeight.w800))),
        ],
      ),
    );
  }
}

class _CompactActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _CompactActionTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.color = const Color(0xFF334155),
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      minVerticalPadding: 4,
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: TextStyle(color: color, fontWeight: FontWeight.w800),
      ),
      trailing: Icon(Icons.chevron_right, color: color),
      onTap: onTap,
    );
  }
}

class _ClassicAccountTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _ClassicAccountTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.color = const Color(0xFF334155),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 14),
                Expanded(child: Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w800))),
                Icon(Icons.chevron_right, color: color),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ClassicTopicProgressCard extends StatelessWidget {
  final HomeState state;

  const _ClassicTopicProgressCard({required this.state});

  static const _topics = [
    ('phishing', 'Phishing', Color(0xFFFF9800)),
    ('password', 'Password', Color(0xFF4CAF50)),
    ('social', 'Social', Color(0xFF3F51B5)),
    ('malware', 'Malware', Color(0xFFF44336)),
    ('privacy', 'Privacy', Color(0xFF9C27B0)),
    ('network', 'Network', Color(0xFF00ACC1)),
    ('ethics', 'Ethics', Color(0xFF673AB7)),
  ];

  @override
  Widget build(BuildContext context) {
    return _ClassicSectionCard(
      title: 'Topic Progress',
      icon: Icons.bar_chart_rounded,
      child: Column(
        children: [
          for (final topic in _topics)
            _ClassicTopicProgressRow(
              label: topic.$2,
              value: state.topicProgress(topic.$1),
              color: topic.$3,
            ),
        ],
      ),
    );
  }
}

class _ClassicTopicProgressRow extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _ClassicTopicProgressRow({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final progress = value.clamp(0.0, 1.0).toDouble();
    final percentage = (progress * 100).round();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 82,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 9,
                color: color,
                backgroundColor: const Color(0xFFE5E7EB),
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 36,
            child: Text(
              '$percentage%',
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _ClassicRecommendationProfileCard extends StatelessWidget {
  final HomeState state;
  final VoidCallback? onTap;

  const _ClassicRecommendationProfileCard({
    required this.state,
    required this.onTap,
  });

  String _titleCase(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }

  String get _focusArea {
    final attemptedTopics = state.topicAnswered.entries
        .where((entry) => entry.value > 0)
        .map((entry) => entry.key)
        .toList()
      ..sort(
        (a, b) => state.topicProgress(a).compareTo(state.topicProgress(b)),
      );

    return attemptedTopics.isEmpty
        ? 'Unexplored topics'
        : _titleCase(attemptedTopics.first);
  }

  String get _confidence {
    if (state.totalQuestionsAnswered >= 15) return 'High';
    if (state.totalQuestionsAnswered >= 5) return 'Medium';
    return 'Low';
  }

  @override
  Widget build(BuildContext context) {
    final recommendedModule = state.recommendedModules.isEmpty
        ? 'Complete a quiz to unlock your next module'
        : state.recommendedModules.first;
    final recommendedId = state.recommendedModuleIds.isEmpty
        ? null
        : state.recommendedModuleIds.first;
    final matchScore = recommendedId == null
        ? null
        : state.recommendationScores[recommendedId];
    final recommendationReason = state.recommendedModules.isEmpty
        ? 'Complete a quiz so CyberBuddy can personalise this recommendation.'
        : state.moduleReasons[recommendedModule] ??
            'Selected from your current learning progress and incomplete modules.';
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFBFDBFE)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.auto_awesome_rounded, color: Color(0xFF2563EB)),
                SizedBox(width: 8),
                Text(
                  'Recommended Next',
                  style: TextStyle(
                    color: Color(0xFF1D4ED8),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              recommendedModule,
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 19,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              recommendationReason,
              style: const TextStyle(color: Color(0xFF475569), height: 1.4),
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 10),
            _ClassicInfoRow(
              label: 'Confidence',
              value: _confidence,
              color: Colors.green,
            ),
            _ClassicInfoRow(
              label: 'Match Score',
              value: matchScore == null ? 'Not available' : '${matchScore.round()}%',
              color: Colors.orange,
            ),
            _ClassicInfoRow(
              label: 'Method',
              value: 'Hybrid Content Matching',
              color: Colors.deepPurple,
            ),
            _ClassicInfoRow(
              label: 'Focus Area',
              value: _focusArea,
              color: Colors.red,
            ),
            const SizedBox(height: 15),
            FilledButton.icon(
              onPressed: onTap,
              icon: const Icon(Icons.play_arrow_rounded),
              label: Text(onTap == null ? 'Complete a Quiz First' : 'Start Module'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileHero extends StatelessWidget {
  final String name;
  final String email;
  final String initials;
  final File? image;
  final int level;
  final int streak;
  final VoidCallback onEdit;

  const _ProfileHero({
    required this.name,
    required this.email,
    required this.initials,
    required this.image,
    required this.level,
    required this.streak,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1F3A),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 35,
                backgroundColor: Colors.white,
                backgroundImage: image == null ? null : FileImage(image!),
                child: image == null
                    ? Text(initials, style: const TextStyle(color: Color(0xFF0B1F3A), fontSize: 24, fontWeight: FontWeight.w800))
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text(email, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFFB9C7DF), fontSize: 13)),
                  ],
                ),
              ),
              IconButton(
                onPressed: onEdit,
                tooltip: 'Edit profile',
                style: IconButton.styleFrom(backgroundColor: Colors.white.withValues(alpha: 0.12)),
                icon: const Icon(Icons.edit_outlined, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _HeroPill(icon: Icons.shield_outlined, text: 'Level $level')),
              const SizedBox(width: 10),
              Expanded(child: _HeroPill(icon: Icons.local_fire_department_outlined, text: '$streak day streak')),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  final IconData icon;
  final String text;

  const _HeroPill({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 17, color: const Color(0xFF7DD3FC)),
          const SizedBox(width: 7),
          Flexible(child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12))),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String label;

  const _MetricCard({required this.icon, required this.color, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return _Panel(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Container(
            height: 36,
            width: 36,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(11)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _Panel({required this.child, this.padding = const EdgeInsets.all(16)});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8EDF5)),
      ),
      child: child,
    );
  }
}

class _SectionHeading extends StatelessWidget {
  final String title;

  const _SectionHeading({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(title, style: const TextStyle(color: Color(0xFF0F172A), fontSize: 18, fontWeight: FontWeight.w800));
  }
}

class _BadgeGlyph extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;

  const _BadgeGlyph({required this.icon, required this.color, this.size = 48});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
      child: Icon(icon, color: color, size: size * 0.52),
    );
  }
}

class _BadgePreview extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _BadgePreview({required this.title, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
        decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _BadgeGlyph(icon: icon, color: color, size: 44),
            const SizedBox(height: 7),
            Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, height: 1.2, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class _BadgeSection extends StatelessWidget {
  final String title;
  final Color color;
  final List<String> badges;
  final bool isUnlocked;
  final void Function(String, {required bool isUnlocked}) onTap;

  const _BadgeSection({required this.title, required this.color, required this.badges, required this.isUnlocked, required this.onTap});

  @override
  Widget build(BuildContext context) {
    if (badges.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Tag(label: '$title (${badges.length})', color: color),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: badges.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 0.92),
          itemBuilder: (_, index) {
            final badge = badges[index];
            return _AchievementTile(
              title: badge,
              icon: _iconForBadge(badge),
              color: _colorForBadge(badge),
              locked: !isUnlocked,
              onTap: () => onTap(badge, isUnlocked: isUnlocked),
            );
          },
        ),
      ],
    );
  }

  IconData _iconForBadge(String badge) {
    final lower = badge.toLowerCase();
    if (lower.contains('phishing')) return Icons.mark_email_read_rounded;
    if (lower.contains('password')) return Icons.key_rounded;
    if (lower.contains('streak')) return Icons.local_fire_department_rounded;
    if (lower.contains('quiz')) return Icons.emoji_events_rounded;
    if (lower.contains('perfect')) return Icons.star_rounded;
    if (lower.contains('malware')) return Icons.bug_report_rounded;
    if (lower.contains('privacy')) return Icons.visibility_rounded;
    if (lower.contains('threat')) return Icons.radar_rounded;
    if (lower.contains('rookie')) return Icons.eco_rounded;
    if (lower.contains('champion')) return Icons.workspace_premium_rounded;
    if (lower.contains('defender')) return Icons.shield_rounded;
    return Icons.military_tech_rounded;
  }

  Color _colorForBadge(String badge) {
    final lower = badge.toLowerCase();
    if (lower.contains('phishing') || lower.contains('privacy')) return const Color(0xFF7C3AED);
    if (lower.contains('malware') || lower.contains('threat')) return const Color(0xFFDC2626);
    if (lower.contains('streak')) return const Color(0xFFEA580C);
    if (lower.contains('quiz') || lower.contains('perfect')) return const Color(0xFFD97706);
    return const Color(0xFF2563EB);
  }
}

class _AchievementTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final bool locked;
  final VoidCallback onTap;

  const _AchievementTile({required this.title, required this.icon, required this.color, required this.locked, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: locked ? 0.52 : 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
          decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(16)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  _BadgeGlyph(icon: icon, color: color, size: 44),
                  if (locked) const Icon(Icons.lock_rounded, size: 16, color: Color(0xFF334155)),
                ],
              ),
              const SizedBox(height: 7),
              Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, height: 1.2, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color color;

  const _Tag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(99)),
      child: Text(label.toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
    );
  }
}

class _InsightRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InsightRow({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 19),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: const TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.w600))),
          const SizedBox(width: 12),
          Flexible(child: Text(value, textAlign: TextAlign.right, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w800))),
        ],
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  final String title;
  final VoidCallback onTap;

  const _RecommendationCard({required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(20)),
        child: Row(
          children: [
            const CircleAvatar(backgroundColor: Color(0xFF2563EB), child: Icon(Icons.auto_awesome_rounded, color: Colors.white)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Recommended for you', style: TextStyle(color: Color(0xFF1D4ED8), fontSize: 12, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 3),
                  Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF0F172A), fontSize: 16, fontWeight: FontWeight.w800)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_rounded, color: Color(0xFF2563EB)),
          ],
        ),
      ),
    );
  }
}

class _RecommendationEmptyCard extends StatelessWidget {
  const _RecommendationEmptyCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(20)),
      child: const Row(
        children: [
          Icon(Icons.auto_awesome_outlined, color: Color(0xFF64748B)),
          SizedBox(width: 12),
          Expanded(child: Text('Complete a quiz to receive your personalised learning recommendation.', style: TextStyle(color: Color(0xFF475569), height: 1.35, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}

class _AccountAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _AccountAction({required this.icon, required this.label, required this.onTap, this.color = const Color(0xFF334155)});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        child: Row(
          children: [
            Icon(icon, color: color, size: 21),
            const SizedBox(width: 14),
            Expanded(child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700))),
            Icon(Icons.chevron_right_rounded, color: color.withValues(alpha: 0.65)),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String text;

  const _EmptyState({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF94A3B8), size: 28),
        const SizedBox(height: 8),
        Text(text, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF64748B), height: 1.35, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _AchievementDetail {
  final String category;
  final String description;
  final String condition;

  const _AchievementDetail({required this.category, required this.description, required this.condition});
}
