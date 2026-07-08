import 'package:flutter/foundation.dart';

import '../models/anuncio_model.dart';
import '../models/user_model.dart';
import 'api_client.dart';
import 'auth_service.dart';

class DelegateAnnouncementService {
  final ApiClient _api = ApiClient();
  final List<Anuncio> _mockAnnouncements = [];

  Future<List<Anuncio>> fetchAnnouncementsBySection(String sectionId) async {
    try {
      final data = await _api.getJson(
        '/api/v1/sections/$sectionId/announcements',
      );
      final raw = _unwrapList(data);
      final anuncios = raw.map((item) {
        final json = Map<String, dynamic>.from(item as Map);
        final normalized = _normalizeAnnouncement(json, sectionId);
        final autorRaw = json['autor'] ?? json['author'];
        final autorJson = autorRaw is Map
            ? Map<String, dynamic>.from(autorRaw)
            : _currentUserJson();
        return Anuncio.fromJson(
          normalized,
          autor: UserModel.fromJson(autorJson),
        );
      }).toList();

      anuncios.sort((a, b) {
        final aDate = DateTime.tryParse(a.fecha);
        final bDate = DateTime.tryParse(b.fecha);
        if (aDate == null && bDate == null) return 0;
        if (aDate == null) return 1;
        if (bDate == null) return -1;
        return bDate.compareTo(aDate);
      });

      return anuncios;
    } catch (e) {
      debugPrint('Historial mock de anuncios delegado: $e');
      return _mockAnnouncements
          .where((anuncio) => anuncio.idSeccion == sectionId)
          .toList()
        ..sort((a, b) => b.fecha.compareTo(a.fecha));
    }
  }

  Future<bool> createAnnouncement({
    required String sectionId,
    required String title,
    required String message,
  }) async {
    try {
      final data = await _api.postJson(
        '/api/v1/delegate/announcements',
        body: {'sectionId': sectionId, 'title': title, 'message': message},
      );

      return data['success'] == true ||
          data['id'] != null ||
          data['data'] != null;
    } catch (e) {
      debugPrint('Publicacion mock de anuncio delegado: $e');
      await Future<void>.delayed(const Duration(milliseconds: 350));
      _mockAnnouncements.insert(
        0,
        Anuncio(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          idSeccion: sectionId,
          titulo: title,
          mensaje: message,
          fecha: DateTime.now().toIso8601String(),
          autorCode: AuthService.to.currentUser?.code ?? '',
          autor:
              AuthService.to.currentUser ??
              UserModel.fromJson(_currentUserJson()),
        ),
      );
      return true;
    }
  }

  List<dynamic> _unwrapList(Map<String, dynamic> data) {
    final payload = data['data'];
    if (payload is List) return payload;
    if (payload is Map && payload['announcements'] is List) {
      return payload['announcements'] as List;
    }
    if (data['anuncios'] is List) return data['anuncios'] as List;
    if (data['announcements'] is List) return data['announcements'] as List;
    return const [];
  }

  Map<String, dynamic> _normalizeAnnouncement(
    Map<String, dynamic> json,
    String sectionId,
  ) {
    return {
      'id': json['id'] ?? json['announcementId'] ?? '',
      'idSeccion': json['idSeccion'] ?? json['sectionId'] ?? sectionId,
      'titulo': json['titulo'] ?? json['title'] ?? '',
      'mensaje': json['mensaje'] ?? json['message'] ?? '',
      'fecha': json['fecha'] ?? json['publishedAt'] ?? json['createdAt'] ?? '',
      'autorCode':
          json['autorCode'] ??
          json['authorCode'] ??
          AuthService.to.currentUser?.code ??
          '',
    };
  }

  Map<String, dynamic> _currentUserJson() {
    final user = AuthService.to.currentUser;
    return {
      'code': user?.code ?? '',
      'firstName': user?.firstName ?? 'Delegado',
      'lastName': user?.lastName ?? '',
      'email': user?.email ?? '',
      'role': user?.role ?? 'delegado',
      'currentCycle': user?.currentCycle ?? '2026-1',
      'setupComplete': user?.setupComplete ?? true,
    };
  }
}
