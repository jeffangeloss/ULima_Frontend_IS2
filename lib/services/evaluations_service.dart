import 'package:flutter/foundation.dart';
import '../models/evaluation_model.dart';
import 'api_client.dart';
import 'auth_service.dart';

/// Servicio para cargar y gestionar los datos de evaluaciones del sílabo
class EvaluationSyllabusService {
  static final EvaluationSyllabusService _instance =
      EvaluationSyllabusService._internal();

  factory EvaluationSyllabusService() {
    return _instance;
  }

  EvaluationSyllabusService._internal();

  final ApiClient _api = ApiClient();
  late List<CourseSyllabus> _syllabusData;
  final Map<String, String> _silaboUrlByCourseId = {};
  bool _isLoaded = false;

  /// Carga el archivo JSON con los datos de evaluaciones
  Future<void> loadEvaluationData() async {
    if (_isLoaded) return;

    try {
      final code = AuthService.to.currentUser?.code;
      final jsonData = await _api.getJson(
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

      final cursosConUrl = jsonData['cursos'] as List<dynamic>? ?? [];
      for (final c in cursosConUrl) {
        final id = c['id']?.toString();
        final url = c['silaboUrl'] as String?;
        if (id != null && url != null) _silaboUrlByCourseId[id] = url;
      }

      _isLoaded = true;
      debugPrint('✓ Datos de evaluaciones cargados: ${_syllabusData.length} cursos');
    } catch (e) {
      // No bloquear el arranque: si falla (p. ej. 401 sin sesión), se
      // inicializa vacío y se reintentará tras el login (_isLoaded sigue false).
      debugPrint('✗ Error al cargar datos de evaluaciones: $e');
      _syllabusData = [];
    }
  }

  /// Obtiene el sílabo de un curso específico por su ID
  CourseSyllabus? getSyllabusByCourseId(String cursoId) {
    try {
      return _syllabusData.firstWhere(
        (syllabus) => syllabus.cursoId == cursoId,
      );
    } catch (e) {
      return null;
    }
  }

  /// Obtiene las evaluaciones de un curso específico
  List<EvaluationComponent> getEvaluationsByCourseId(String cursoId) {
    final syllabus = getSyllabusByCourseId(cursoId);
    return syllabus?.evaluaciones ?? [];
  }

  /// Obtiene todos los sílabos cargados
  List<CourseSyllabus> get allSyllabuses => _syllabusData;

  /// Obtiene la URL del sílabo de un curso por su curriculum_course_id
  String? getSilaboUrl(String courseId) => _silaboUrlByCourseId[courseId];

  /// Verifica si los datos ya están cargados
  bool get isLoaded => _isLoaded;
}
