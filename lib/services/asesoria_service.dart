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

  // HU17: confirma la asistencia del alumno a una asesoría.
  // Devuelve el conteo autoritativo y el estado tras la operación.
  Future<RsvpResult> confirmarAsistencia(String sessionId) async {
    final data = await _api.postJson(
      '/course-detail/advising/$sessionId/rsvp',
      body: const {},
    );
    return RsvpResult.fromJson(data);
  }

  // HU17: cancela la asistencia del alumno a una asesoría.
  Future<RsvpResult> cancelarAsistencia(String sessionId) async {
    final data = await _api.deleteJson('/course-detail/advising/$sessionId/rsvp');
    return RsvpResult.fromJson(data);
  }
}

/// HU17: respuesta de confirmar/cancelar asistencia (`{ id, asistentes, myRsvp }`).
class RsvpResult {
  final int asistentes;
  final bool myRsvp;

  const RsvpResult({required this.asistentes, required this.myRsvp});

  factory RsvpResult.fromJson(Map<String, dynamic> json) {
    return RsvpResult(
      asistentes: json['asistentes'] is int
          ? json['asistentes'] as int
          : int.tryParse(json['asistentes']?.toString() ?? '') ?? 0,
      myRsvp: json['myRsvp'] == true,
    );
  }
}
