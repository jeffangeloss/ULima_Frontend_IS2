import 'package:flutter/foundation.dart';
import '../models/section_representative_model.dart';
import 'api_client.dart';
import 'enrollment_service.dart';

class SectionRepresentativeService {
  final ApiClient _api = ApiClient();
  final EnrollmentService _enrollmentService = EnrollmentService();

  Future<List<SectionRepresentative>> fetchRepresentatives() async {
    try {
      final data = await _api.getJson('/section-management/representatives');
      final List<dynamic> raw = data['sectionRepresentatives'] ?? [];
      return raw.map((r) => SectionRepresentative.fromJson(r)).toList();
    } catch (e) {
      debugPrint('Error cargando representantes: $e');
      return [];
    }
  }

  Future<String> getRoleInSection(String idSeccion, String studentCode) async {
    final representatives = await fetchRepresentatives();

    for (final rep in representatives) {
      final enrollment = await _enrollmentService.findById(rep.enrollmentId);

      if (enrollment != null &&
          enrollment.idSeccion == idSeccion &&
          enrollment.studentCode == studentCode) {
        return rep.role;
      }
    }

    return 'estudiante';
  }

  Future<bool> isRepresentativeInAnySection(String studentCode) async {
    final representatives = await fetchRepresentatives();

    for (final rep in representatives) {
      final enrollment = await _enrollmentService.findById(rep.enrollmentId);

      if (enrollment != null &&
          enrollment.studentCode == studentCode &&
          (rep.role == 'delegado' || rep.role == 'subdelegado')) {
        return true;
      }
    }

    return false;
  }
}
