import 'package:flutter/foundation.dart';

import '../models/estadisticas_seccion_model.dart';
import 'api_client.dart';

class SectionStatisticsService {
  final ApiClient _api = ApiClient();

  Future<EstadisticasSeccion?> fetchSectionStatistics(String sectionId) async {
    try {
      final data = await _api.getJson('/api/v1/sections/$sectionId/statistics');
      final payload = data['data'] is Map ? data['data'] : data;
      return EstadisticasSeccion.fromJson(
        Map<String, dynamic>.from(payload as Map),
      );
    } catch (e) {
      debugPrint('Usando estadisticas mock temporal: $e');
      await Future<void>.delayed(const Duration(milliseconds: 250));
      return const EstadisticasSeccion(
        promedioGeneral: 14.2,
        porcentajeAprobados: 78,
        rango0_10: 4,
        rango11_13: 7,
        rango14_16: 15,
        rango17_20: 6,
      );
    }
  }
}
