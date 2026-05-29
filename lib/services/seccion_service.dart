import 'package:flutter/foundation.dart';
import 'package:ulima_plus/models/seccion_model.dart';
import 'package:ulima_plus/services/api_client.dart';

class SeccionService {
  final ApiClient _api = ApiClient();

  Future<List<Seccion>> fetchSecciones() async {
    try {
      final data = await _api.getJson('/course-detail/sections');
      final List<dynamic> sectionsRaw = data['secciones'] ?? [];

      return sectionsRaw
          .map((s) => Seccion.fromJson(s as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error cargando secciones: $e');
      return [];
    }
  }

  Future<Seccion?> findSectionById(String id) async {
    try {
      final data = await _api.getJson('/course-detail/sections/$id');
      final section = data['section'];
      if (section == null) return null;
      return Seccion.fromJson(Map<String, dynamic>.from(section as Map));
    } catch (e) {
      debugPrint('No existe seccion con id $id');
      return null;
    }
  }
}
