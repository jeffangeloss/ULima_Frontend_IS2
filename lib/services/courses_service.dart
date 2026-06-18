import 'package:flutter/foundation.dart';
import 'auth_service.dart';
import 'api_client.dart';

/// Servicio para cargar y gestionar los datos de cursos
class CoursesService {
  static final CoursesService _instance = CoursesService._internal();

  factory CoursesService() {
    return _instance;
  }

  CoursesService._internal();

  final ApiClient _api = ApiClient();
  late List<Map<String, dynamic>> _coursesData;
  bool _isLoaded = false;

  /// Carga el archivo JSON con los datos de cursos
  Future<void> loadCoursesData() async {
    if (_isLoaded) return;

    try {
      final code = AuthService.to.currentUser?.code;
      final jsonData = await _api.getJson(
        '/grades/me/courses${code == null ? '' : '?code=$code'}',
      );
      final cursosList = jsonData['cursos'] as List<dynamic>? ?? [];

      _coursesData = List<Map<String, dynamic>>.from(cursosList);

      _isLoaded = true;
      debugPrint('✓ Datos de cursos cargados: ${_coursesData.length} cursos');
    } catch (e) {
      // No bloquear el arranque de la app: si falla (p. ej. 401 sin sesión
      // iniciada, por las rutas protegidas), se inicializa vacío y se
      // reintentará tras el login (_isLoaded permanece en false).
      debugPrint('✗ Error al cargar datos de cursos: $e');
      _coursesData = [];
    }
  }

  /// Obtiene todos los cursos cargados
  List<Map<String, dynamic>> get allCourses => _coursesData;

  /// Obtiene un curso específico por su ID
  Map<String, dynamic>? getCourseById(String id) {
    try {
      return _coursesData.firstWhere((course) => course['id'] == id);
    } catch (e) {
      return null;
    }
  }

  /// Verifica si los datos ya están cargados
  bool get isLoaded => _isLoaded;
}
