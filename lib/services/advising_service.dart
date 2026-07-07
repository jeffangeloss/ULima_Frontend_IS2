// lib/services/advising_service.dart
// API del lado docente para HU18. Sin caché singleton (lección de TT06): cada
// pantalla pide datos frescos; el token lo resuelve el ApiClient.

import '../models/advising_models.dart';
import 'api_client.dart';

class AttendeesResult {
  final int total;
  final List<Attendee> asistentes;
  AttendeesResult({required this.total, required this.asistentes});
}

class AdvisingService {
  final ApiClient _api = ApiClient();

  /// Asesorías del docente autenticado (recurrentes + extras).
  Future<List<AdvisingSession>> fetchSessions() async {
    final data = await _api.getJson('/advising/me/sessions');
    final raw = (data['sesiones'] as List?) ?? const [];
    return raw
        .whereType<Map>()
        .map((s) => AdvisingSession.fromJson(Map<String, dynamic>.from(s)))
        .toList();
  }

  /// Secciones donde el docente dicta (para el formulario de creación).
  Future<List<TeacherSectionOption>> fetchSections() async {
    final data = await _api.getJson('/advising/me/sections');
    final raw = (data['secciones'] as List?) ?? const [];
    return raw
        .whereType<Map>()
        .map((s) => TeacherSectionOption.fromJson(Map<String, dynamic>.from(s)))
        .toList();
  }

  /// Crea una asesoría extra. Lanza [ApiException] con el mensaje del backend
  /// ante una validación fallida (solape, fecha fuera de período, etc.).
  Future<AdvisingSession> createSession({
    required int sectionId,
    required String sessionDate, // 'YYYY-MM-DD'
    required String startTime, // 'HH:MM'
    required String endTime,
    required String modality,
    String? classroom,
    String? meetingUrl,
    String? note,
    int? capacity,
  }) async {
    final body = <String, dynamic>{
      'sectionId': sectionId,
      'sessionDate': sessionDate,
      'startTime': startTime,
      'endTime': endTime,
      'modality': modality,
      if (classroom != null && classroom.isNotEmpty) 'classroom': classroom,
      if (meetingUrl != null && meetingUrl.isNotEmpty) 'meetingUrl': meetingUrl,
      if (note != null && note.isNotEmpty) 'note': note,
      'capacity': ?capacity,
    };
    final data = await _api.postJson('/advising/me/sessions', body: body);
    return AdvisingSession.fromJson(Map<String, dynamic>.from(data['sesion'] as Map));
  }

  Future<void> deleteSession(int id) async {
    await _api.deleteJson('/advising/me/sessions/$id');
  }

  Future<AttendeesResult> fetchAttendees(int id) async {
    final data = await _api.getJson('/advising/me/sessions/$id/attendees');
    final raw = (data['asistentes'] as List?) ?? const [];
    final asistentes = raw
        .whereType<Map>()
        .map((a) => Attendee.fromJson(Map<String, dynamic>.from(a)))
        .toList();
    final total = data['total'] is int
        ? data['total'] as int
        : int.tryParse(data['total']?.toString() ?? '') ?? asistentes.length;
    return AttendeesResult(total: total, asistentes: asistentes);
  }
}
