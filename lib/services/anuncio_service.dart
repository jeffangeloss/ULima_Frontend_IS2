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

      return anunciosRaw.map((a) {
        final json = Map<String, dynamic>.from(a as Map);
        final autorJson = Map<String, dynamic>.from(json['autor'] as Map);
        return Anuncio.fromJson(json, autor: UserModel.fromJson(autorJson));
      }).toList();
    } catch (e) {
      debugPrint('Error cargando anuncios: $e');
      return [];
    }
  }
}
