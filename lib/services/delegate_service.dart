import 'package:flutter/foundation.dart';

import '../models/curso_delegado_model.dart';
import 'api_client.dart';
import 'auth_service.dart';
import 'courses_service.dart';

class DelegateService {
  final ApiClient _api = ApiClient();

  Future<List<CursoDelegado>> fetchDelegateSections() async {
    try {
      final data = await _api.getJson('/section-management/representatives');
      final raw = _unwrapList(data);
      return raw
          .map(
            (item) => CursoDelegado.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList();
    } catch (e) {
      if (!_canUseMockFallback(e)) rethrow;
      debugPrint('Usando cursos delegado mock temporal: $e');
      return _mockDelegateSections();
    }
  }

  List<dynamic> _unwrapList(Map<String, dynamic> data) {
    final payload = data['data'];
    if (payload is List) return payload;
    if (payload is Map && payload['sections'] is List) {
      return payload['sections'] as List;
    }
    if (payload is Map && payload['sectionRepresentatives'] is List) {
      return payload['sectionRepresentatives'] as List;
    }
    if (data['sections'] is List) return data['sections'] as List;
    if (data['sectionRepresentatives'] is List) {
      return data['sectionRepresentatives'] as List;
    }
    return const [];
  }

  bool _canUseMockFallback(Object error) {
    if (error is! ApiException) return true;
    return error.statusCode == 404 && error.code == 'HTTP_ERROR';
  }

  List<CursoDelegado> _mockDelegateSections() {
    final user = AuthService.to.currentUser;
    if (user?.isDelegate != true) return const [];

    final role = user!.role == 'subdelegate' ? 'subdelegado' : user.role;
    final courses = CoursesService().allCourses;

    if (courses.isEmpty) {
      return [
        CursoDelegado(
          idCurso: 'mock-course',
          nombreCurso: 'Curso asignado',
          idSeccion: 'mock-section',
          codigoSeccion: 'MOCK-001',
          rol: role == 'student' ? 'delegado' : role,
          alumnosMatriculados: 32,
        ),
      ];
    }

    return courses.take(3).map((course) {
      final id =
          course['id']?.toString() ?? course['idCurso']?.toString() ?? '';
      final section =
          course['seccion']?.toString() ??
          course['codigoSeccion']?.toString() ??
          'SEC-${id.isEmpty ? '001' : id}';

      return CursoDelegado(
        idCurso: id,
        nombreCurso:
            course['nombre']?.toString() ??
            course['curso']?.toString() ??
            course['courseName']?.toString() ??
            'Curso asignado',
        idSeccion: course['idSeccion']?.toString() ?? section,
        codigoSeccion: section,
        rol: role == 'student' ? 'delegado' : role,
        alumnosMatriculados:
            (course['alumnosMatriculados'] as num?)?.toInt() ??
            (course['students'] as num?)?.toInt() ??
            32,
      );
    }).toList();
  }
}
