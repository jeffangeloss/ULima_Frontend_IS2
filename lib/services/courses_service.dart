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
  List<Map<String, dynamic>> _coursesData = [];
  bool _isLoaded = false;
  // Código del alumno cuyos datos están en caché. Si el usuario actual es
  // otro (TT06: cambio de cuenta sin pasar por logout, p. ej. sesión
  // expirada por 401), la caché se considera inválida y se recarga.
  String? _loadedForCode;

  /// Reemplaza la petición HTTP en tests (el ApiClient no es inyectable).
  @visibleForTesting
  Future<Map<String, dynamic>> Function(String path)? fetchJsonOverride;

  /// Carga el archivo JSON con los datos de cursos
  Future<void> loadCoursesData() async {
    try {
      final code = AuthService.to.currentUser?.code;
      if (_isLoaded && code == _loadedForCode) return;

      final fetch = fetchJsonOverride ?? _api.getJson;
      final jsonData = await fetch(
        '/grades/me/courses${code == null ? '' : '?code=$code'}',
      );
      final cursosList = jsonData['cursos'] as List<dynamic>? ?? [];

      _coursesData = List<Map<String, dynamic>>.from(cursosList);
      _loadedForCode = code;

      _isLoaded = true;
      debugPrint('✓ Datos de cursos cargados: ${_coursesData.length} cursos');
    } catch (e) {
      // No bloquear el arranque de la app: si falla (p. ej. 401 sin sesión
      // iniciada, por las rutas protegidas), se limpia y se reintentará tras
      // el login (_isLoaded queda en false). Si falló la recarga para un
      // usuario nuevo, esto además descarta los datos del usuario anterior.
      debugPrint('✗ Error al cargar datos de cursos: $e');
      clear();
    }
  }

  /// Olvida los datos en caché (llamar al cerrar sesión — TT06).
  void clear() {
    _coursesData = [];
    _isLoaded = false;
    _loadedForCode = null;
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
