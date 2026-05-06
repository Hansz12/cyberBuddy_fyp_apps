import 'dart:convert';
import 'package:flutter/services.dart';

class LocalDataService {
  Future<List<dynamic>> loadModules() async {
    final jsonString =
        await rootBundle.loadString('assets/data/modules.json');

    return jsonDecode(jsonString);
  }

  Future<List<dynamic>> loadQuizQuestions() async {
    final jsonString =
        await rootBundle.loadString('assets/data/quiz_questions.json');

    return jsonDecode(jsonString);
  }
}