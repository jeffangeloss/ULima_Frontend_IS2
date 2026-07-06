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
  List<CourseSyllabus> _syllabusData = [];
  final Map<String, String> _silaboUrlByCourseId = {};
  bool _isLoaded = false;
  // Código del alumno cuyos datos están en caché. Si el usuario actual es
  // otro (TT06: cambio de cuenta sin pasar por logout, p. ej. sesión
  // expirada por 401), la caché se considera inválida y se recarga.
  String? _loadedForCode;

  /// Reemplaza la petición HTTP en tests (el ApiClient no es inyectable).
  @visibleForTesting
  Future<Map<String, dynamic>> Function(String path)? fetchJsonOverride;

  /// Carga el archivo JSON con los datos de evaluaciones
  Future<void> loadEvaluationData() async {
    try {
      final code = AuthService.to.currentUser?.code;
      if (_isLoaded && code == _loadedForCode) return;

      final fetch = fetchJsonOverride ?? _api.getJson;
      final jsonData = await fetch(
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
      debugPrint('✓ Datos de evaluaciones cargados: ${_syllabusData.length} cursos');
    } catch (e) {
      // No bloquear el arranque: si falla (p. ej. 401 sin sesión), se limpia
      // y se reintentará tras el login (_isLoaded queda en false). Si falló
      // la recarga para un usuario nuevo, esto además descarta los datos del
      // usuario anterior.
      debugPrint('✗ Error al cargar datos de evaluaciones: $e');
      clear();
    }
  }

  /// Olvida los datos en caché (llamar al cerrar sesión — TT06).
  void clear() {
    _syllabusData = [];
    _silaboUrlByCourseId.clear();
    _isLoaded = false;
    _loadedForCode = null;
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
