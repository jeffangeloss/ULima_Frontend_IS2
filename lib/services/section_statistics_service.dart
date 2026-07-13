import '../models/estadisticas_seccion_model.dart';
import 'api_client.dart';

/// Estadísticas REALES del salón (HU11), calculadas por el backend desde las
/// notas oficiales (`student_score`). Ya NO devuelve un mock: si falla, propaga
/// la ApiException para que el controller muestre un estado de error.
class SectionStatisticsService {
  final ApiClient _api = ApiClient();

  Future<EstadisticasSeccion> fetchSectionStatistics(String sectionId) async {
    final data = await _api.getJson(
      '/section-management/sections/$sectionId/statistics',
    );
    final payload = data['data'] is Map ? data['data'] : data;
    return EstadisticasSeccion.fromJson(Map<String, dynamic>.from(payload as Map));
  }
}
