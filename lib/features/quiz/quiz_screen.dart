import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vibration/vibration.dart';

import '../home/cubit/home_cubit.dart';
import 'cubit/quiz_cubit.dart';
import 'cubit/quiz_state.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  OverlayEntry? _xpOverlayEntry;

  @override
  void dispose() {
    _xpOverlayEntry?.remove();
    super.dispose();
  }

  void _showXpOverlay(int xp) {
    _xpOverlayEntry?.remove();

    _xpOverlayEntry = OverlayEntry(
      builder: (context) => _XpOverlayPopup(
        xp: xp,
        onDismiss: () {
          _xpOverlayEntry?.remove();
          _xpOverlayEntry = null;
        },
      ),
    );

    Overlay.of(context).insert(_xpOverlayEntry!);
  }

  void _showWrongOverlay() {
    _xpOverlayEntry?.remove();

    _xpOverlayEntry = OverlayEntry(
      builder: (context) => _WrongOverlayPopup(
        onDismiss: () {
          _xpOverlayEntry?.remove();
          _xpOverlayEntry = null;
        },
      ),
    );

    Overlay.of(context).insert(_xpOverlayEntry!);
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
    return BlocBuilder<QuizCubit, QuizState>(
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
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back),
                        color: Colors.white,
                        padding: EdgeInsets.zero,
                        alignment: Alignment.centerLeft,
                      ),

                      const SizedBox(height: 2),

                      Row(
                        children: [
                          ...List.generate(state.questions.length, (index) {
                            final active = index <= state.currentIndex;

                            return Expanded(
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 400),
                                curve: Curves.easeOut,
                                margin: const EdgeInsets.only(right: 5),
                                height: 6,
                                decoration: BoxDecoration(
                                  color: active
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

                      Text(
                        " ${_topic(state).toUpperCase()} · ${_difficulty(state).toUpperCase()}",
                        style: const TextStyle(
                          color: Color(0xFF38BDF8),
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.1,
                        ),
                      ),

                      const SizedBox(height: 10),

                      Text(
                        _question(state),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: ListView(
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
                              Row(
                                children: const [
                                  Text(
                                    "Cyber Alert 🚨",
                                    style: TextStyle(
                                      color: Color(0xFF1E40AF),
                                      fontWeight: FontWeight.w900,
                                      fontSize: 13,
                                    ),
                                  ),
                                  SizedBox(width: 6),
                                  Text("📩"),
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
                                  _showXpOverlay(_xp(state));
                                } else {
                                  _vibrateWrong();
                                  _showWrongOverlay();
                                }
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
                      child: Text(
                        state.isAnswered
                            ? state.currentIndex == state.questions.length - 1
                                  ? "Complete Mission 🎯"
                                  : "Next Challenge →"
                            : "Lock My Answer 🔐",
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
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

class _WrongOverlayPopup extends StatefulWidget {
  final VoidCallback onDismiss;

  const _WrongOverlayPopup({required this.onDismiss});

  @override
  State<_WrongOverlayPopup> createState() => _WrongOverlayPopupState();
}

class _WrongOverlayPopupState extends State<_WrongOverlayPopup> {
  double _opacity = 0.0;
  double _scale = 0.85;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _opacity = 1.0;
        _scale = 1.0;
      });

      Future.delayed(const Duration(milliseconds: 1100), () {
        if (!mounted) return;

        setState(() {
          _opacity = 0.0;
          _scale = 0.85;
        });

        Future.delayed(const Duration(milliseconds: 260), () {
          if (mounted) widget.onDismiss();
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 80,
      left: 0,
      right: 0,
      child: IgnorePointer(
        child: AnimatedOpacity(
          opacity: _opacity,
          duration: const Duration(milliseconds: 250),
          child: AnimatedScale(
            scale: _scale,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutBack,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(127, 29, 29, 0.94),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color.fromRGBO(255, 0, 0, 0.25),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('⚠️', style: TextStyle(fontSize: 22)),
                    SizedBox(width: 10),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Not quite!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Check the explanation below',
                          style: TextStyle(
                            color: Color(0xFFFECACA),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
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
                  Text(isTrue ? '✅' : '❌', style: const TextStyle(fontSize: 36)),
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
            isCorrect ? "✓ Correct answer!" : "✕ Not quite.",
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
                  isCorrect ? " Question answered correctly" : " Keep learning",
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
                "XP earned",
                style: TextStyle(color: Color(0xFF93C5FD), fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _XpOverlayPopup extends StatefulWidget {
  final int xp;
  final VoidCallback onDismiss;

  const _XpOverlayPopup({required this.xp, required this.onDismiss});

  @override
  State<_XpOverlayPopup> createState() => _XpOverlayPopupState();
}

class _XpOverlayPopupState extends State<_XpOverlayPopup> {
  double _opacity = 0.0;
  double _scale = 0.75;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _opacity = 1.0;
        _scale = 1.0;
      });
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (!mounted) return;
        setState(() {
          _opacity = 0.0;
          _scale = 0.75;
        });
        Future.delayed(const Duration(milliseconds: 260), () {
          if (mounted) widget.onDismiss();
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 80,
      left: 0,
      right: 0,
      child: IgnorePointer(
        child: AnimatedOpacity(
          opacity: _opacity,
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOut,
          child: AnimatedScale(
            scale: _scale,
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutBack,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(13, 27, 62, 0.92),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color.fromRGBO(0, 0, 0, 0.2),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🔥', style: TextStyle(fontSize: 22)),
                    const SizedBox(width: 10),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '+${widget.xp} XP',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Correct answer!',
                          style: TextStyle(
                            color: Color(0xFF93C5FD),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
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

class _QuizResultScreenState extends State<_QuizResultScreen> {
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    HapticFeedback.mediumImpact();
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

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              const Spacer(),

              Container(
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

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
