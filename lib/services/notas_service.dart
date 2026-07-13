import '../models/user_model.dart';
import 'api_client.dart';
import 'auth_service.dart';
import 'courses_service.dart';

class NotasService {
  final ApiClient _api = ApiClient();

  Future<String?> obtenerIdEstudianteActual() async {
    final user = AuthService.to.currentUser;
    if (user == null) return null;
    return user.code;
  }

  Future<List<Map<String, dynamic>>> cargarNotas(String studentId) async {
    final currentUser = AuthService.to.currentUser;
    if (currentUser == null || currentUser.code != studentId) {
      return const [];
    }

    final coursesService = CoursesService();
    await coursesService.loadCoursesData();

    final notesResponse = await _api.getJson('/grades/me/notes');
    final coursesWithNotes = (notesResponse['cursos'] as List?) ?? const [];

    final notesBySection = <String, List<Map<String, dynamic>>>{};
    for (final course in coursesWithNotes) {
      final courseMap = Map<String, dynamic>.from(course as Map);
      final sectionId = courseMap['sectionId']?.toString() ?? '';
      final notes = (courseMap['notas'] as List?) ?? const [];
      notesBySection[sectionId] = notes
          .map((note) => Map<String, dynamic>.from(note as Map))
          .toList();
    }

    final result = <Map<String, dynamic>>[];
    for (final course in coursesService.allCourses) {
      final sectionId = course['id']?.toString() ?? '';
      final notes = notesBySection[sectionId] ?? const [];
      if (notes.isEmpty) continue;

      result.add({
        'id': sectionId,
        'nombre': course['nombre']?.toString() ?? course['name']?.toString() ?? '',
        'notas': notes.map((note) {
          return {
            'titulo': note['titulo']?.toString() ?? '',
            'peso': _asInt(note['peso']),
            'valor': _asDouble(note['valor']),
          };
        }).toList(),
      });
    }

    return result;
  }

  int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}