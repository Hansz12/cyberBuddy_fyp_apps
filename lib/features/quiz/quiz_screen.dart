import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vibration/vibration.dart';

import '../../data/services/quiz_audio_service.dart';
import '../home/cubit/home_cubit.dart';
import 'cubit/quiz_cubit.dart';
import 'cubit/quiz_state.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  OverlayEntry? _feedbackOverlayEntry;
  late final QuizAudioService _quizAudio;
  bool _isAudioReady = false;
  bool _isAudioMuted = false;

  @override
  void initState() {
    super.initState();
    _quizAudio = QuizAudioService();
    _setupQuizAudio();
  }

  @override
  void dispose() {
    _feedbackOverlayEntry?.remove();
    _quizAudio.dispose();
    super.dispose();
  }

  Future<void> _setupQuizAudio() async {
    await _quizAudio.loadPreference();
    if (!mounted) return;

    setState(() {
      _isAudioReady = true;
      _isAudioMuted = _quizAudio.isMuted;
    });
    _startQuizAudioIfReady();
  }

  void _startQuizAudioIfReady() {
    final state = context.read<QuizCubit>().state;
    if (!_isAudioReady || state.questions.isEmpty || state.isFinished) return;

    _quizAudio.start();
  }

  Future<void> _toggleQuizAudio() async {
    if (!_isAudioReady) return;

    final muted = !_isAudioMuted;
    await _quizAudio.setMuted(muted);
    if (!mounted) return;

    setState(() => _isAudioMuted = muted);
  }

  void _showAnswerFeedback({required bool isCorrect, required int xp}) {
    _feedbackOverlayEntry?.remove();

    _feedbackOverlayEntry = OverlayEntry(
      builder: (_) => _QuizFeedbackOverlay(
        isCorrect: isCorrect,
        xp: xp,
        onDismiss: () {
          _feedbackOverlayEntry?.remove();
          _feedbackOverlayEntry = null;
        },
      ),
    );

    Overlay.of(context, rootOverlay: true).insert(_feedbackOverlayEntry!);
  }
  Future _vibrateCorrect() async {
    final hasVibrator = await Vibration.hasVibrator();
    if (hasVibrator != true) return;

    Vibration.vibrate(duration: 80, amplitude: 120);
  }

  Future _vibrateWrong() async {
    final hasVibrator = await Vibration.hasVibrator();
    if (hasVibrator != true) return;

    Vibration.vibrate(pattern: [0, 80, 80, 120], intensities: [150, 220]);
  }

  Map<String, dynamic> _q(QuizState state) => state.currentQuestion;

  int _correctIndex(QuizState state) => _q(state)['correctIndex'] ?? 0;

  List<dynamic> _options(QuizState state) => _q(state)['options'] ?? [];

  String _question(QuizState state) => _q(state)['question'] ?? '';

  String _scenario(QuizState state) => _q(state)['scenario'] ?? '';

  String _explanation(QuizState state) => _q(state)['explanation'] ?? '';

  String _topic(QuizState state) => _q(state)['topic'] ?? 'cyber';

  String _difficulty(QuizState state) => _q(state)['difficulty'] ?? 'beginner';

  int _xp(QuizState state) {
    final value = _q(state)['xpReward'];
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<QuizCubit, QuizState>(
      listener: (context, state) {
        if (state.isFinished) {
          _quizAudio.stop();
        } else {
          _startQuizAudioIfReady();
        }
      },
      child: BlocBuilder<QuizCubit, QuizState>(
        builder: (context, state) {
        if (state.isLoading) {
          return const Scaffold(
            backgroundColor: Color(0xFFF1F5F9),
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (state.questions.isEmpty) {
          return Scaffold(
            backgroundColor: const Color(0xFFF1F5F9),
            body: SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("📭", style: TextStyle(fontSize: 46)),
                      const SizedBox(height: 12),
                      const Text(
                        "No quiz questions found",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF0F172A),
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "This module may not have active questions yet.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 18),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Back"),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        if (state.isFinished) {
          return _QuizResultScreen(state: state);
        }

        final correctIndex = _correctIndex(state);
        final options = _options(state);
        final selectedIndex = state.selectedIndex;
        final isCorrect = selectedIndex == correctIndex;
        final actionLabel = state.isAnswered
            ? state.currentIndex == state.questions.length - 1
                  ? 'Complete Mission 🎯'
                  : 'Start Next Round 🚀'
            : selectedIndex == null
            ? 'Pick Your Move 👆'
            : 'Lock It In ⚡';
        final actionIcon = state.isAnswered
            ? state.currentIndex == state.questions.length - 1
                  ? Icons.emoji_events_rounded
                  : Icons.arrow_forward_rounded
            : selectedIndex == null
            ? Icons.touch_app_outlined
            : Icons.lock_rounded;

        return Scaffold(
          backgroundColor: const Color(0xFFF1F5F9),
          body: SafeArea(
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.arrow_back),
                            color: Colors.white,
                            padding: EdgeInsets.zero,
                            alignment: Alignment.centerLeft,
                          ),
                          IconButton(
                            tooltip: _isAudioMuted
                                ? 'Turn on quiz ambience'
                                : 'Mute quiz ambience',
                            onPressed: _isAudioReady
                                ? _toggleQuizAudio
                                : null,
                            icon: Icon(
                              _isAudioMuted
                                  ? Icons.volume_off_rounded
                                  : Icons.volume_up_rounded,
                            ),
                            color: Colors.white,
                          ),
                        ],
                      ),

                      const SizedBox(height: 2),

                      Row(
                        children: [
                          ...List.generate(state.questions.length, (index) {
                            final isCompleted = index < state.currentIndex;
                            final isCurrent = index == state.currentIndex;

                            return Expanded(
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 450),
                                curve: Curves.easeOutCubic,
                                margin: const EdgeInsets.only(right: 5),
                                height: isCurrent ? 8 : 6,
                                decoration: BoxDecoration(
                                  color: isCompleted
                                      ? const Color(0xFF34D399)
                                      : isCurrent
                                      ? const Color(0xFF38BDF8)
                                      : Colors.white24,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            );
                          }),

                          const SizedBox(width: 8),

                          Text(
                            "${state.currentIndex + 1}/${state.questions.length}",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Text(
                          '${_topic(state).toUpperCase()} · ${_difficulty(state).toUpperCase()}',
                          style: const TextStyle(
                            color: Color(0xFF7DD3FC),
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 350),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        transitionBuilder: (child, animation) {
                          final slide = Tween<Offset>(
                            begin: const Offset(0.08, 0),
                            end: Offset.zero,
                          ).animate(animation);

                          return FadeTransition(
                            opacity: animation,
                            child: SlideTransition(position: slide, child: child),
                          );
                        },
                        child: Text(
                          _question(state),
                          key: ValueKey('question-${state.currentIndex}'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            height: 1.25,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 420),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, animation) {
                      final slide = Tween<Offset>(
                        begin: const Offset(0.12, 0),
                        end: Offset.zero,
                      ).animate(animation);

                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(position: slide, child: child),
                      );
                    },
                    child: ListView(
                      key: ValueKey('challenge-${state.currentIndex}'),
                      padding: const EdgeInsets.fromLTRB(18, 16, 18, 100),
                      children: [
                      if (_scenario(state).trim().isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: const Color(0xFFBFDBFE)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(
                                    Icons.shield_outlined,
                                    size: 18,
                                    color: Color(0xFF1E40AF),
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Incoming Intel',
                                    style: TextStyle(
                                      color: Color(0xFF1E40AF),
                                      fontWeight: FontWeight.w900,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Text(
                                  '"${_scenario(state)}"',
                                  style: const TextStyle(
                                    color: Color(0xFF0F172A),
                                    fontSize: 14,
                                    height: 1.35,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                      ],

                      _ChallengePrompt(
                        questionType:
                            _q(state)['questionType']?.toString() ?? 'MCQ',
                        hasSelection: selectedIndex != null,
                        isAnswered: state.isAnswered,
                      ),
                      const SizedBox(height: 12),

                      _QuestionTypeRenderer(
                        questionType:
                            _q(state)['questionType']?.toString() ?? 'MCQ',
                        options: options,
                        selectedIndex: selectedIndex,
                        correctIndex: correctIndex,
                        isAnswered: state.isAnswered,
                        onSelect: (index) {
                          context.read<QuizCubit>().selectAnswer(index);
                        },
                      ),

                      if (state.isAnswered) ...[
                        const SizedBox(height: 14),
                        _ExplanationBox(
                          isCorrect: isCorrect,
                          explanation: _explanation(state),
                        ),
                        const SizedBox(height: 14),
                        _XpBox(isCorrect: isCorrect, xp: _xp(state)),
                      ],
                      ],
                    ),
                  ),
                ),

                Container(
                  padding: const EdgeInsets.fromLTRB(18, 10, 18, 16),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: state.selectedIndex == null
                          ? null
                          : () {
                              final isCorrect =
                                  state.selectedIndex == correctIndex;

                              if (!state.isAnswered) {
                                if (isCorrect) {
                                  _vibrateCorrect();
                                } else {
                                  _vibrateWrong();
                                }
                                _showAnswerFeedback(
                                  isCorrect: isCorrect,
                                  xp: _xp(state),
                                );
                                context.read<QuizCubit>().submitAnswer();
                              } else {
                                context.read<QuizCubit>().nextQuestion();
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: const Color(0xFFE2E8F0),
                        disabledForegroundColor: Colors.grey,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(actionIcon, size: 20),
                          const SizedBox(width: 8),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 180),
                            child: Text(
                              actionLabel,
                              key: ValueKey(actionLabel),
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
        },
      ),
    );
  }
}

class _QuizFeedbackOverlay extends StatefulWidget {
  final bool isCorrect;
  final int xp;
  final VoidCallback onDismiss;

  const _QuizFeedbackOverlay({
    required this.isCorrect,
    required this.xp,
    required this.onDismiss,
  });

  @override
  State<_QuizFeedbackOverlay> createState() => _QuizFeedbackOverlayState();
}

class _QuizFeedbackOverlayState extends State<_QuizFeedbackOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1900),
    )..forward();

    Future.delayed(const Duration(milliseconds: 1900), () {
      if (mounted) widget.onDismiss();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final progress = _controller.value;
            final entryScale = Curves.elasticOut.transform(
              (progress * 1.45).clamp(0.0, 1.0),
            );
            final fadeOut = progress < 0.78
                ? 1.0
                : (1 - ((progress - 0.78) / 0.22)).clamp(0.0, 1.0);
            final shake = widget.isCorrect
                ? 0.0
                : math.sin(progress * math.pi * 10) * (1 - progress) * 12;

            return Opacity(
              opacity: fadeOut,
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 98),
                      child: Transform.translate(
                        offset: Offset(shake, 0),
                        child: Transform.scale(
                          scale: 0.9 + (entryScale * 0.1),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 270),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: widget.isCorrect
                                      ? const Color(0xFF22C55E)
                                      : const Color(0xFFFB7185),
                                  width: 1.5,
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color.fromRGBO(15, 23, 42, 0.14),
                                    blurRadius: 14,
                                    offset: Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    widget.isCorrect
                                        ? Icons.check_circle_rounded
                                        : Icons.tips_and_updates_rounded,
                                    color: widget.isCorrect
                                        ? const Color(0xFF16A34A)
                                        : const Color(0xFFE11D48),
                                    size: 22,
                                  ),
                                  const SizedBox(width: 7),
                                  Flexible(
                                    child: Text(
                                      widget.isCorrect
                                          ? '+${widget.xp} XP added'
                                          : 'Review the clue below',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textScaler: TextScaler.noScaling,
                                      style: const TextStyle(
                                        color: Color(0xFF0F172A),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
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

class _ConfettiPainter extends CustomPainter {
  final double progress;
  final double centerYFactor;

  const _ConfettiPainter({required this.progress, this.centerYFactor = 0.47});

  @override
  void paint(Canvas canvas, Size size) {
    const colors = [
      Color(0xFF38BDF8),
      Color(0xFF34D399),
      Color(0xFFFBBF24),
      Color(0xFFF472B6),
      Color(0xFFA78BFA),
    ];
    final center = Offset(size.width / 2, size.height * centerYFactor);
    final opacity = (1 - progress).clamp(0.0, 1.0);

    for (var index = 0; index < 34; index++) {
      final angle = (index * 0.74) + (index.isEven ? -0.4 : 0.25);
      final distance = 70 + ((index * 23) % 155).toDouble();
      final start = center + Offset(math.cos(angle), math.sin(angle)) * 26;
      final end = center +
          Offset(math.cos(angle), math.sin(angle)) * distance +
          Offset(0, 180 * progress * progress);
      final position = Offset.lerp(start, end, Curves.easeOut.transform(progress))!;
      final paint = Paint()
        ..color = colors[index % colors.length].withValues(alpha: opacity)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(position.dx, position.dy);
      canvas.rotate(angle + (progress * math.pi * 2));
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: 8, height: 13),
          const Radius.circular(2),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.centerYFactor != centerYFactor;
  }
}

class _OptionCard extends StatefulWidget {
  final String letter;
  final String text;
  final int index;
  final int? selectedIndex;
  final int correctIndex;
  final bool isAnswered;
  final VoidCallback onTap;

  const _OptionCard({
    required this.letter,
    required this.text,
    required this.index,
    required this.selectedIndex,
    required this.correctIndex,
    required this.isAnswered,
    required this.onTap,
  });

  @override
  State<_OptionCard> createState() => _OptionCardState();
}

class _OptionCardState extends State<_OptionCard> {
  Color get _borderColor {
    if (!widget.isAnswered) {
      return widget.selectedIndex == widget.index
          ? const Color(0xFF2563EB)
          : const Color(0xFFE2E8F0);
    }

    if (widget.index == widget.correctIndex) return const Color(0xFF10B981);
    if (widget.index == widget.selectedIndex) return const Color(0xFFEF4444);

    return const Color(0xFFE2E8F0);
  }

  Color get _backgroundColor {
    if (!widget.isAnswered) {
      return widget.selectedIndex == widget.index
          ? const Color(0xFFEFF6FF)
          : Colors.white;
    }

    if (widget.index == widget.correctIndex) return const Color(0xFFECFDF5);
    if (widget.index == widget.selectedIndex) return const Color(0xFFFEF2F2);

    return Colors.white;
  }

  Color get _letterBgColor {
    if (!widget.isAnswered) {
      return widget.selectedIndex == widget.index
          ? const Color(0xFF2563EB)
          : const Color(0xFFEFF6FF);
    }

    if (widget.index == widget.correctIndex) return const Color(0xFF10B981);
    if (widget.index == widget.selectedIndex) return const Color(0xFFEF4444);

    return const Color(0xFFEFF6FF);
  }

  Color get _letterTextColor {
    if (!widget.isAnswered) {
      return widget.selectedIndex == widget.index
          ? Colors.white
          : const Color(0xFF2563EB);
    }

    if (widget.index == widget.correctIndex ||
        widget.index == widget.selectedIndex) {
      return Colors.white;
    }

    return const Color(0xFF64748B);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: widget.selectedIndex == widget.index ? 1.03 : 1.0,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      child: InkWell(
        onTap: widget.isAnswered ? null : widget.onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _backgroundColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _borderColor, width: 1.4),
            boxShadow: widget.index == widget.correctIndex && widget.isAnswered
                ? [
                    BoxShadow(
                      color: const Color.fromRGBO(16, 185, 129, 0.25),
                      blurRadius: 15,
                      spreadRadius: 1,
                    ),
                  ]
                : [],
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: _letterBgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    widget.letter,
                    style: TextStyle(
                      color: _letterTextColor,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Text(
                  widget.text,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    height: 1.25,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChallengePrompt extends StatelessWidget {
  final String questionType;
  final bool hasSelection;
  final bool isAnswered;

  const _ChallengePrompt({
    required this.questionType,
    required this.hasSelection,
    required this.isAnswered,
  });

  @override
  Widget build(BuildContext context) {
    final type = questionType.toLowerCase();
    final prompt = type.contains('chat')
        ? 'Pick the reply you would actually send.'
        : type.contains('would')
        ? 'Would you take the bait? Make your call.'
        : type.contains('password')
        ? 'Choose the strongest defense.'
        : type.contains('qr')
        ? 'Scan the clues before you make a move.'
        : type.contains('true')
        ? 'Trust your cyber instincts—true or false?'
        : 'Choose your next move.';
    final status = isAnswered
        ? 'Move locked • Check your result below'
        : hasSelection
        ? 'Move selected • Ready when you are'
        : 'Tap one card to begin';
    final accent = isAnswered
        ? const Color(0xFF10B981)
        : hasSelection
        ? const Color(0xFF2563EB)
        : const Color(0xFF7C3AED);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.24)),
      ),
      child: Row(
        children: [
          Container(
            height: 38,
            width: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isAnswered
                  ? Icons.verified_rounded
                  : hasSelection
                  ? Icons.bolt_rounded
                  : Icons.videogame_asset_rounded,
              color: accent,
              size: 21,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'YOUR MISSION',
                  style: TextStyle(
                    color: accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  isAnswered ? status : prompt,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                  ),
                ),
                if (!isAnswered) ...[
                  const SizedBox(height: 3),
                  Text(
                    status,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestionTypeRenderer extends StatelessWidget {
  final String questionType;
  final List<dynamic> options;
  final int? selectedIndex;
  final int correctIndex;
  final bool isAnswered;
  final ValueChanged<int> onSelect;

  const _QuestionTypeRenderer({
    required this.questionType,
    required this.options,
    required this.selectedIndex,
    required this.correctIndex,
    required this.isAnswered,
    required this.onSelect,
  });

  bool _isSelected(int index) => selectedIndex == index;

  Color _borderColor(int index) {
    if (!isAnswered) {
      return _isSelected(index)
          ? const Color(0xFF2563EB)
          : const Color(0xFFE2E8F0);
    }
    if (index == correctIndex) return const Color(0xFF10B981);
    if (_isSelected(index)) return const Color(0xFFEF4444);
    return const Color(0xFFE2E8F0);
  }

  Color _backgroundColor(int index) {
    if (!isAnswered) {
      return _isSelected(index) ? const Color(0xFFEFF6FF) : Colors.white;
    }
    if (index == correctIndex) return const Color(0xFFECFDF5);
    if (_isSelected(index)) return const Color(0xFFFEF2F2);
    return Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    final type = questionType.toLowerCase();

    if (type.contains('would')) return _buildWouldYouClick();
    if (type.contains('chat')) return _buildChatSimulation();
    if (type.contains('password')) return _buildPasswordBattle();
    if (type.contains('qr')) return _buildQrDetective();
    if (type.contains('incident')) return _buildMissionAction();
    if (type.contains('true')) return _buildTrueFalse();

    return _buildDefaultMcq();
  }

  Widget _buildWouldYouClick() {
    return Row(
      children: List.generate(options.length, (index) {
        final isYes = options[index].toString().toLowerCase().contains('yes');

        return Expanded(
          child: GestureDetector(
            onTap: isAnswered ? null : () => onSelect(index),
            child: Container(
              margin: EdgeInsets.only(right: index == 0 ? 10 : 0),
              padding: const EdgeInsets.symmetric(vertical: 24),
              decoration: BoxDecoration(
                color: _backgroundColor(index),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: _borderColor(index), width: 2),
              ),
              child: Column(
                children: [
                  Text(isYes ? '👆' : '🚫', style: const TextStyle(fontSize: 36)),
                  const SizedBox(height: 8),
                  Text(
                    options[index].toString().toUpperCase(),
                    style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildChatSimulation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Choose your reply 💬',
          style: TextStyle(
            color: Color(0xFF475569),
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 12),
        ...List.generate(options.length, (index) {
          final selected = _isSelected(index);
          return Align(
            alignment: index.isEven
                ? Alignment.centerLeft
                : Alignment.centerRight,
            child: GestureDetector(
              onTap: isAnswered ? null : () => onSelect(index),
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: selected && !isAnswered
                      ? const Color(0xFF2563EB)
                      : _backgroundColor(index),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: _borderColor(index), width: 1.8),
                ),
                child: Text(
                  '💬 ${options[index]}',
                  style: TextStyle(
                    color: selected && !isAnswered
                        ? Colors.white
                        : const Color(0xFF0F172A),
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    height: 1.3,
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildPasswordBattle() {
    return Column(
      children: List.generate(options.length, (index) {
        return GestureDetector(
          onTap: isAnswered ? null : () => onSelect(index),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: _backgroundColor(index),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _borderColor(index), width: 1.8),
            ),
            child: Row(
              children: [
                const Text('🔐', style: TextStyle(fontSize: 26)),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    options[index].toString(),
                    style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildQrDetective() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFBEB),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFF59E0B)),
          ),
          child: const Column(
            children: [
              Text('▦', style: TextStyle(fontSize: 54)),
              SizedBox(height: 6),
              Text(
                'QR Detective Mode',
                style: TextStyle(
                  color: Color(0xFF92400E),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
        ..._buildIconOptionTiles('🔎'),
      ],
    );
  }

  Widget _buildMissionAction() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFEEF2FF),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF818CF8)),
          ),
          child: const Text(
            '🎯 Mission: Pick the safest next action',
            style: TextStyle(
              color: Color(0xFF3730A3),
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        ..._buildIconOptionTiles('🛡️'),
      ],
    );
  }

  Widget _buildTrueFalse() {
    return Row(
      children: List.generate(options.length, (index) {
        final isTrue =
            options[index].toString().toLowerCase().contains('true');
        final isCorrectAnswer = isAnswered && index == correctIndex;

        return Expanded(
          child: GestureDetector(
            onTap: isAnswered ? null : () => onSelect(index),
            child: Container(
              margin: EdgeInsets.only(right: index == 0 ? 10 : 0),
              padding: const EdgeInsets.symmetric(vertical: 24),
              decoration: BoxDecoration(
                color: _backgroundColor(index),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: _borderColor(index), width: 2),
              ),
              child: Column(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 58,
                        height: 58,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isTrue
                              ? const Color(0xFFE0F2FE)
                              : const Color(0xFFF1F5F9),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          isTrue ? 'T' : 'F',
                          style: const TextStyle(
                            color: Color(0xFF0F172A),
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      if (isCorrectAnswer)
                        const Positioned(
                          right: -5,
                          bottom: -5,
                          child: Icon(
                            Icons.check_circle,
                            color: Color(0xFF10B981),
                            size: 24,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    options[index].toString().toUpperCase(),
                    style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildDefaultMcq() {
    return Column(
      children: List.generate(options.length, (index) {
        return _OptionCard(
          letter: String.fromCharCode(65 + index),
          text: options[index].toString(),
          index: index,
          selectedIndex: selectedIndex,
          correctIndex: correctIndex,
          isAnswered: isAnswered,
          onTap: () => onSelect(index),
        );
      }),
    );
  }

  List<Widget> _buildIconOptionTiles(String icon) {
    return List.generate(options.length, (index) {
      return GestureDetector(
          onTap: isAnswered ? null : () => onSelect(index),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _backgroundColor(index),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _borderColor(index), width: 1.8),
            ),
            child: Row(
              children: [
                Text(icon, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    options[index].toString(),
                    style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
      );
    });
  }
}

class _ExplanationBox extends StatelessWidget {
  final bool isCorrect;
  final String explanation;

  const _ExplanationBox({required this.isCorrect, required this.explanation});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isCorrect ? 'Nice move! You got it.' : 'Close one—learn the safer move.',
            style: TextStyle(
              color: isCorrect
                  ? const Color(0xFF10B981)
                  : const Color(0xFFEF4444),
              fontWeight: FontWeight.w900,
              fontSize: 14,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            explanation.isEmpty
                ? "Review the scenario carefully and choose the safest cybersecurity action."
                : explanation,
            style: const TextStyle(
              color: Color(0xFF475569),
              fontSize: 13,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _XpBox extends StatelessWidget {
  final bool isCorrect;
  final int xp;

  const _XpBox({required this.isCorrect, required this.xp});

  @override
  Widget build(BuildContext context) {
    final badgeLabel = isCorrect
        ? xp >= 30
              ? '🔥 Streak x3'
              : '🏆 Cyber Defender'
        : 'Keep learning';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E3A8A),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isCorrect ? 'Mission XP secured' : 'Training mode active',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  badgeLabel,
                  style: const TextStyle(
                    color: Color(0xFF93C5FD),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                isCorrect ? "+$xp XP" : "+0 XP",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF38BDF8),
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                "mission reward",
                style: TextStyle(color: Color(0xFF93C5FD), fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuizResultScreen extends StatefulWidget {
  final QuizState state;

  const _QuizResultScreen({required this.state});

  @override
  State<_QuizResultScreen> createState() => _QuizResultScreenState();
}

class _QuizResultScreenState extends State<_QuizResultScreen>
    with SingleTickerProviderStateMixin {
  bool _isSaving = false;
  late final AnimationController _celebrationController;
  late final Animation<double> _resultCardScale;

  @override
  void initState() {
    super.initState();
    _celebrationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..forward();
    _resultCardScale = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _celebrationController, curve: Curves.elasticOut),
    );
    HapticFeedback.mediumImpact();
  }

  @override
  void dispose() {
    _celebrationController.dispose();
    super.dispose();
  }

  Future<void> _backToLearning(BuildContext context) async {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    final state = widget.state;
    final quizCubit = context.read<QuizCubit>();
    final navigator = Navigator.of(context);

    await context.read<HomeCubit>().recordFullQuizResult(
      earnedXp: state.earnedXp,
      questions: state.questions,
      answerResults: state.answerResults,
      totalQuestions: state.questions.length,
      correctAnswers: state.score,
    );

    if (!mounted) return;

    quizCubit.resetQuiz();

    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final percentage = ((state.score / state.questions.length) * 100).round();
    final earnedXp = state.earnedXp;
    final missedIndexes = List.generate(state.questions.length, (index) => index)
        .where(
          (index) =>
              index >= state.answerResults.length ||
              !state.answerResults[index],
        )
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Stack(
        children: [
          SafeArea(
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                18,
                missedIndexes.isEmpty
                    ? MediaQuery.sizeOf(context).height * 0.2
                    : 18,
                18,
                18,
              ),
              children: [
              ScaleTransition(
                scale: _resultCardScale,
                child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0D1B3E), Color(0xFF2563EB)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  children: [
                    const Text("🎉", style: TextStyle(fontSize: 52)),

                    const SizedBox(height: 12),

                    const Text(
                      "Quiz Completed",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      "Score: ${state.score}/${state.questions.length} · $percentage%",
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 10),

                    Text(
                      "+$earnedXp XP earned",
                      style: const TextStyle(
                        color: Color(0xFF38BDF8),
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),

                    const SizedBox(height: 16),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: const Column(
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.auto_awesome,
                                color: Color(0xFF38BDF8),
                                size: 18,
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  "Recommendation Updated",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Text(
                            "Your quiz result will update the Next Training Path based on your topic performance.",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                ),
              ),

              if (missedIndexes.isNotEmpty) ...[
                const SizedBox(height: 20),
                _WrongAnswerReview(
                  questions: state.questions,
                  missedIndexes: missedIndexes,
                ),
              ],

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : () => _backToLearning(context),
                  child: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text("Save Progress & Back"),
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                "Your XP, accuracy, and recommendation will be saved.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              ],
            ),
          ),
          if (percentage >= 80)
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _celebrationController,
                  builder: (context, child) => CustomPaint(
                    painter: _ConfettiPainter(
                      progress: _celebrationController.value,
                      centerYFactor: missedIndexes.isEmpty ? 0.5 : 0.3,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _WrongAnswerReview extends StatelessWidget {
  final List<Map<String, dynamic>> questions;
  final List<int> missedIndexes;

  const _WrongAnswerReview({
    required this.questions,
    required this.missedIndexes,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFFED7AA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.replay_circle_filled_outlined, color: Color(0xFFF97316)),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Review Mistakes',
                  style: TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'A quick refresher for the concepts to revisit next.',
            style: TextStyle(color: Color(0xFF64748B), height: 1.35),
          ),
          const SizedBox(height: 14),
          ...missedIndexes.map((index) {
            final question = questions[index];
            final options = question['options'] as List? ?? const [];
            final correctIndex = question['correctIndex'] as int? ?? 0;
            final correctAnswer =
                correctIndex >= 0 && correctIndex < options.length
                ? options[correctIndex].toString()
                : 'Review the safe action in the explanation.';
            final explanation = question['explanation']?.toString() ?? '';

            return Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Question ${index + 1}',
                    style: const TextStyle(
                      color: Color(0xFFF97316),
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    question['question']?.toString() ?? 'Cybersecurity challenge',
                    style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontWeight: FontWeight.w900,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Safest answer: $correctAnswer',
                    style: const TextStyle(
                      color: Color(0xFF166534),
                      fontWeight: FontWeight.w800,
                      height: 1.3,
                    ),
                  ),
                  if (explanation.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      explanation,
                      style: const TextStyle(
                        color: Color(0xFF475569),
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
