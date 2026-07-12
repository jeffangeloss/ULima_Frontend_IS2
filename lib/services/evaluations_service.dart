import 'package:flutter/foundation.dart';
import '../models/evaluation_model.dart';
import 'api_client.dart';
import 'auth_service.dart';

class EvaluationSyllabusService {
  static EvaluationSyllabusService _defaultInstance = EvaluationSyllabusService._internal();

  static EvaluationSyllabusService get instance => _defaultInstance;

  factory EvaluationSyllabusService({ApiClient? apiClient}) {
    if (apiClient != null) {
      return EvaluationSyllabusService._internal(apiClient: apiClient);
    }
    return _defaultInstance;
  }

  static void setTestInstance(EvaluationSyllabusService instance) {
    _defaultInstance = instance;
  }

  final ApiClient apiClient;

  EvaluationSyllabusService._internal({ApiClient? apiClient})
    : apiClient = apiClient ?? ApiClient();

  List<CourseSyllabus> _syllabusData = [];
  final Map<String, String> _silaboUrlByCourseId = {};
  bool _isLoaded = false;
  String? _loadedForCode;

  Future<void> loadEvaluationData() async {
    try {
      final code = AuthService.to.currentUser?.code;
      if (_isLoaded && code == _loadedForCode) return;

      final jsonData = await apiClient.getJson(
        '/grades/me/courses${code == null ? '' : '?code=$code'}',
      );
      final List<dynamic> cursosList = jsonData['syllabi'] as List? ?? [];
      _syllabusData = cursosList
          .map((curso) {
            if (curso is Map) {
              return CourseSyllabus.fromJson(Map<String, dynamic>.from(curso));
            }
            return null;
          })
          .whereType<CourseSyllabus>()
          .toList();

      _silaboUrlByCourseId.clear();
      final cursosConUrl = jsonData['cursos'] as List<dynamic>? ?? [];
      for (final c in cursosConUrl) {
        final id = c['id']?.toString();
        final url = c['silaboUrl'] as String?;
        if (id != null && url != null) _silaboUrlByCourseId[id] = url;
      }

      _loadedForCode = code;
      _isLoaded = true;
      debugPrint('Datos de evaluaciones cargados: ${_syllabusData.length} cursos');
    } catch (e) {
      debugPrint('Error al cargar datos de evaluaciones: $e');
      clear();
    }
  }

  void clear() {
    _syllabusData = [];
    _silaboUrlByCourseId.clear();
    _isLoaded = false;
    _loadedForCode = null;
  }

  CourseSyllabus? getSyllabusByCourseId(String cursoId) {
    try {
      return _syllabusData.firstWhere(
        (syllabus) => syllabus.cursoId == cursoId,
      );
    } catch (e) {
      return null;
    }
  }

  List<EvaluationComponent> getEvaluationsByCourseId(String cursoId) {
    final syllabus = getSyllabusByCourseId(cursoId);
    return syllabus?.evaluaciones ?? [];
  }

  List<CourseSyllabus> get allSyllabuses => _syllabusData;

  String? getSilaboUrl(String courseId) => _silaboUrlByCourseId[courseId];

  bool get isLoaded => _isLoaded;
}
