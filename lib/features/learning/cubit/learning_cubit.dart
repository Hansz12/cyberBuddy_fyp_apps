import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../data/services/local_data_service.dart';
import 'learning_state.dart';

class LearningCubit extends Cubit<LearningState> {
  LearningCubit() : super(const LearningState());

  final LocalDataService _dataService = LocalDataService();

  static const String _completedKey = 'completed_module_ids';

  Future<void> loadModules() async {
    emit(state.copyWith(isLoading: true));

    try {
      final prefs = await SharedPreferences.getInstance();
      final completedIds = prefs.getStringList(_completedKey) ?? [];

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
    } catch (e) {
      emit(state.copyWith(modules: const [], isLoading: false));
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
    await prefs.setStringList(_completedKey, updatedCompletedIds);
  }

  LearningModule? getModuleById(String id) {
    try {
      return state.modules.firstWhere((module) => module.id == id);
    } catch (_) {
      return null;
    }
  }
}
