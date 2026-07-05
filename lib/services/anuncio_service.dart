import 'package:flutter/foundation.dart';
import '../models/anuncio_model.dart';
import '../models/user_model.dart';
import 'api_client.dart';

class AnuncioService {
  final ApiClient _api = ApiClient();

  Future<List<Anuncio>> fetchAnuncios(String idSeccion) async {
    try {
      final data = await _api.getJson(
        '/course-detail/sections/$idSeccion/announcements',
      );
      final List<dynamic> anunciosRaw = data['anuncios'] ?? [];

      final anuncios = anunciosRaw.map((a) {
        final json = Map<String, dynamic>.from(a as Map);
        final autorJson = Map<String, dynamic>.from(json['autor'] as Map);
        return Anuncio.fromJson(json, autor: UserModel.fromJson(autorJson));
      }).toList();

      anuncios.sort((a, b) {
        final fechaA = DateTime.tryParse(a.fecha);
        final fechaB = DateTime.tryParse(b.fecha);
        if (fechaA == null && fechaB == null) return 0;
        if (fechaA == null) return 1;
        if (fechaB == null) return -1;
        return fechaB.compareTo(fechaA);
      });

      return anuncios;
    } catch (e) {
      debugPrint('Error cargando anuncios: $e');
      return [];
    }
  }
}
