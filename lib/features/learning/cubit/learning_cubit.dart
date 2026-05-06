import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../data/services/local_data_service.dart';
import 'learning_state.dart';

class LearningCubit extends Cubit<LearningState> {
  LearningCubit() : super(const LearningState());

  final LocalDataService _dataService = LocalDataService();

  static const String _completedKey = 'completed_module_ids';

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  String _key(String name) {
    final uid = _uid;

    if (uid == null) return name;

    return '${uid}_$name';
  }

  Future<void> loadModules() async {
    emit(state.copyWith(isLoading: true));

    try {
      final prefs = await SharedPreferences.getInstance();

      final completedIds = _uid == null
          ? <String>[]
          : prefs.getStringList(_key(_completedKey)) ?? [];

      final data = await _dataService.loadModules();

      final modules = data.map((json) {
        final moduleId =
            json['module_id']?.toString() ?? json['id']?.toString() ?? '';

        return LearningModule(
          id: moduleId,
          title: json['title']?.toString() ?? 'Untitled Module',
          topic: json['topic']?.toString().toLowerCase() ?? 'general',
          difficulty: json['difficulty']?.toString() ?? 'Beginner',
          xpReward: int.tryParse(json['xp_reward'].toString()) ?? 20,
          content:
              json['short_description']?.toString() ??
              json['learning_objective']?.toString() ??
              json['content']?.toString() ??
              json['description']?.toString() ??
              '',
          completed: completedIds.contains(moduleId),
        );
      }).toList();

      emit(
        state.copyWith(
          modules: modules,
          completedModuleIds: completedIds,
          isLoading: false,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          modules: const [],
          completedModuleIds: const [],
          isLoading: false,
        ),
      );
    }
  }

  Future<void> completeModule(String moduleId) async {
    if (moduleId.isEmpty) return;

    final updatedCompletedIds = List<String>.from(state.completedModuleIds);

    if (!updatedCompletedIds.contains(moduleId)) {
      updatedCompletedIds.add(moduleId);
    }

    final updatedModules = state.modules.map((module) {
      if (module.id == moduleId) {
        return module.copyWith(completed: true);
      }

      return module;
    }).toList();

    emit(
      state.copyWith(
        modules: updatedModules,
        completedModuleIds: updatedCompletedIds,
      ),
    );

    final prefs = await SharedPreferences.getInstance();

    if (_uid != null) {
      await prefs.setStringList(_key(_completedKey), updatedCompletedIds);
    }
  }

  Future<void> resetLearningProgress() async {
    final prefs = await SharedPreferences.getInstance();

    if (_uid != null) {
      await prefs.remove(_key(_completedKey));
    }

    final resetModules = state.modules.map((module) {
      return module.copyWith(completed: false);
    }).toList();

    emit(state.copyWith(modules: resetModules, completedModuleIds: const []));
  }

  void clearSession() {
    emit(const LearningState());
  }

  LearningModule? getModuleById(String id) {
    try {
      return state.modules.firstWhere((module) => module.id == id);
    } catch (_) {
      return null;
    }
  }
}
