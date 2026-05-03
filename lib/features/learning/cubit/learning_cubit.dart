import 'package:flutter_bloc/flutter_bloc.dart';
import 'learning_state.dart';

class LearningCubit extends Cubit<LearningState> {
  LearningCubit() : super(const LearningState());

  void loadModules() {
    const modules = [
      LearningModule(
        title: "Phishing Awareness",
        topic: "phishing",
        difficulty: "Beginner",
        xpReward: 25,
        content:
            "Phishing is a cyberattack where attackers trick users into giving sensitive information such as passwords, banking details, or login codes. Always check the sender, URL spelling, and avoid clicking suspicious links.",
      ),
      LearningModule(
        title: "Password Security",
        topic: "password",
        difficulty: "Beginner",
        xpReward: 25,
        content:
            "A strong password uses uppercase letters, lowercase letters, numbers, and symbols. Avoid using birthdays, names, or repeated passwords. Use multi-factor authentication whenever possible.",
      ),
      LearningModule(
        title: "Social Engineering",
        topic: "social",
        difficulty: "Intermediate",
        xpReward: 30,
        content:
            "Social engineering manipulates users into making unsafe actions. Attackers may create urgency, fear, fake authority, or rewards to trick victims. Always verify through official channels.",
      ),
      LearningModule(
        title: "Malware & Safe Downloads",
        topic: "malware",
        difficulty: "Intermediate",
        xpReward: 30,
        content:
            "Malware includes viruses, spyware, ransomware, and trojans. Avoid downloading files from unknown websites and always update your device and applications.",
      ),
      LearningModule(
        title: "Privacy Protection",
        topic: "privacy",
        difficulty: "Beginner",
        xpReward: 20,
        content:
            "Protect your privacy by limiting what you share online, reviewing app permissions, using privacy settings, and avoiding oversharing personal information on social media.",
      ),
    ];

    emit(state.copyWith(modules: modules));
  }

  void completeModule(String title) {
    final updatedModules = state.modules.map((module) {
      if (module.title == title) {
        return module.copyWith(completed: true);
      }
      return module;
    }).toList();

    emit(state.copyWith(modules: updatedModules));
  }
}
