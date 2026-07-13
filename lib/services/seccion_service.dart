import 'package:ulima_plus/models/seccion_model.dart';
import 'package:ulima_plus/services/api_client.dart';

class SeccionService {
  final ApiClient _api = ApiClient();

  // No atrapan el error: propagan la ApiException para que el caller distinga
  // "falló la carga" de "sin secciones" (ver docs/AUDITORIA_TECNICA.md §6.1).
  // Una sección inexistente llega como 200 con `section: null` (→ null), así
  // que sólo un error real (500/red) lanza; el "no encontrado" sigue siendo null.
  Future<List<Seccion>> fetchSecciones() async {
    final data = await _api.getJson('/course-detail/sections');
    final List<dynamic> sectionsRaw = data['secciones'] ?? [];

    return sectionsRaw
        .map((s) => Seccion.fromJson(s as Map<String, dynamic>))
        .toList();
  }

  Future<Seccion?> findSectionById(String id) async {
    final data = await _api.getJson('/course-detail/sections/$id');
    final section = data['section'];
    if (section == null) return null;
    return Seccion.fromJson(Map<String, dynamic>.from(section as Map));
  }
}
