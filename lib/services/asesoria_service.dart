import '../models/asesoria_model.dart';
import '../models/docente_model.dart';
import 'api_client.dart';

class AsesoriaService {
  final ApiClient _api = ApiClient();

  // No atrapa el error: si la petición falla, propaga la ApiException para que
  // el controller la distinga de "sin asesorías" y muestre un estado de error
  // con reintentar (antes un fallo se veía como lista vacía). El caller la
  // maneja por-pestaña sin tumbar el resto del detalle.
  Future<List<Asesoria>> fetchAsesorias(String idSeccion) async {
    final data = await _api.getJson(
      '/advising/section/$idSeccion',
    );
    final List<dynamic> asesoriasRaw = data['asesorias'] ?? [];

    return asesoriasRaw.map((a) {
      final json = Map<String, dynamic>.from(a as Map);
      final docenteJson = Map<String, dynamic>.from(json['docente'] as Map);
      return Asesoria.fromJson(json, docente: Docente.fromJson(docenteJson));
    }).toList();
  }

  // HU17: confirma la asistencia del alumno a una asesoría.
  // Devuelve el conteo autoritativo y el estado tras la operación.
  Future<RsvpResult> confirmarAsistencia(String sessionId) async {
    final data = await _api.postJson(
      '/advising/$sessionId/rsvp',
      body: const {},
    );
    return RsvpResult.fromJson(data);
  }

  // HU17: cancela la asistencia del alumno a una asesoría.
  Future<RsvpResult> cancelarAsistencia(String sessionId) async {
    final data = await _api.deleteJson('/advising/$sessionId/rsvp');
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
