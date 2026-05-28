import 'package:flutter/foundation.dart';
import '../models/asesoria_model.dart';
import '../models/docente_model.dart';
import 'api_client.dart';

class AsesoriaService {
  final ApiClient _api = ApiClient();

  Future<List<Asesoria>> fetchAsesorias(String idSeccion) async {
    try {
      final data = await _api.getJson(
        '/course-detail/sections/$idSeccion/advising',
      );
      final List<dynamic> asesoriasRaw = data['asesorias'] ?? [];

      return asesoriasRaw.map((a) {
        final json = Map<String, dynamic>.from(a as Map);
        final docenteJson = Map<String, dynamic>.from(json['docente'] as Map);
        return Asesoria.fromJson(json, docente: Docente.fromJson(docenteJson));
      }).toList();
    } catch (e) {
      debugPrint('Error cargando asesorias: $e');
      return [];
    }
  }
}
