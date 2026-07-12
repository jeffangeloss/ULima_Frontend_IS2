import 'package:flutter/foundation.dart';
import 'auth_service.dart';
import 'api_client.dart';

class CoursesService {
  static CoursesService _defaultInstance = CoursesService._internal();

  static CoursesService get instance => _defaultInstance;

  factory CoursesService({ApiClient? apiClient}) {
    if (apiClient != null) {
      return CoursesService._internal(apiClient: apiClient);
    }
    return _defaultInstance;
  }

  static void setTestInstance(CoursesService instance) {
    _defaultInstance = instance;
  }

  final ApiClient apiClient;

  CoursesService._internal({ApiClient? apiClient})
    : apiClient = apiClient ?? ApiClient();

  List<Map<String, dynamic>> _coursesData = [];
  bool _isLoaded = false;
  String? _loadedForCode;

  Future<void> loadCoursesData() async {
    try {
      final code = AuthService.to.currentUser?.code;
      if (_isLoaded && code == _loadedForCode) return;

      final jsonData = await apiClient.getJson(
        '/grades/me/courses${code == null ? '' : '?code=$code'}',
      );
      final cursosList = jsonData['cursos'] as List<dynamic>? ?? [];

      _coursesData = List<Map<String, dynamic>>.from(cursosList);
      _loadedForCode = code;

      _isLoaded = true;
      debugPrint('Datos de cursos cargados: ${_coursesData.length} cursos');
    } catch (e) {
      debugPrint('Error al cargar datos de cursos: $e');
      clear();
    }
  }

  void clear() {
    _coursesData = [];
    _isLoaded = false;
    _loadedForCode = null;
  }

  List<Map<String, dynamic>> get allCourses => _coursesData;

  Map<String, dynamic>? getCourseById(String id) {
    try {
      return _coursesData.firstWhere((course) => course['id'] == id);
    } catch (e) {
      return null;
    }
  }

  bool get isLoaded => _isLoaded;
}
