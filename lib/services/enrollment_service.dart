import 'package:flutter/foundation.dart';
import '../models/enrollment_model.dart';
import 'api_client.dart';

class EnrollmentService {
  final ApiClient _api = ApiClient();

  Future<List<Enrollment>> fetchEnrollments() async {
    try {
      final data = await _api.getJson('/course-detail/enrollments');
      final List<dynamic> raw = data['enrollments'] ?? [];
      return raw.map((e) => Enrollment.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Error cargando enrollments: $e');
      return [];
    }
  }

  Future<List<Enrollment>> fetchBySection(String idSeccion) async {
    final enrollments = await fetchEnrollments();
    return enrollments.where((e) => e.idSeccion == idSeccion).toList();
  }

  Future<Enrollment?> findById(String id) async {
    final enrollments = await fetchEnrollments();
    try {
      return enrollments.firstWhere((e) => e.id == id);
    } catch (e) {
      return null;
    }
  }
}
