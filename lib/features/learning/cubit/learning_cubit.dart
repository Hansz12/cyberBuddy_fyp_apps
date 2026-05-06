import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/services/local_data_service.dart';
import 'learning_state.dart';

class LearningCubit extends Cubit<LearningState> {
  LearningCubit() : super(const LearningState());

  final LocalDataService _dataService = LocalDataService();

  Future<void> loadModules() async {
    try {
      final data = await _dataService.loadModules();

      final modules = data.map((json) {
        return LearningModule(
          id: json['id']?.toString() ?? '',
          title: json['title']?.toString() ?? 'Untitled Module',
          topic: json['topic']?.toString().toLowerCase() ?? 'general',
          difficulty: json['difficulty']?.toString() ?? 'Beginner',
          xpReward: int.tryParse(json['xpReward'].toString()) ?? 20,
          content:
              json['content']?.toString() ??
              json['description']?.toString() ??
              '',
          completed: false,
        );
      }).toList();

      emit(state.copyWith(modules: modules));
    } catch (e) {
      emit(state.copyWith(modules: const []));
    }
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

  LearningModule? getModuleById(String id) {
    try {
      return state.modules.firstWhere((module) => module.id == id);
    } catch (_) {
      return null;
    }
  }
}
