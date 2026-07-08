import 'package:flutter/foundation.dart';

import '../models/anuncio_model.dart';
import '../models/user_model.dart';
import 'api_client.dart';
import 'auth_service.dart';

class DelegateAnnouncementService {
  final ApiClient _api = ApiClient();
  static final List<Anuncio> _mockAnnouncements = [];
  static final Set<String> _deletedAnnouncementIds = {};

  Future<List<Anuncio>> fetchAnnouncementsBySection(String sectionId) async {
    try {
      final data = await _api.getJson(
        '/section-management/sections/$sectionId/announcements',
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

      return _mergeLocalChanges(sectionId, anuncios);
    } catch (e) {
      if (!_canUseMockFallback(e)) rethrow;
      debugPrint('Historial mock de anuncios delegado: $e');
      return _mergeLocalChanges(sectionId, const []);
    }
  }

  Future<bool> createAnnouncement({
    required String sectionId,
    required String title,
    required String message,
  }) async {
    try {
      final data = await _api.postJson(
        '/section-management/sections/$sectionId/announcements',
        body: {'title': title, 'message': message},
      );

      return data['success'] == true ||
          data['anuncio'] != null ||
          data['message'] != null ||
          data['id'] != null ||
          data['data'] != null;
    } catch (e) {
      if (!_canUseMockFallback(e)) rethrow;
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

  Future<bool> updateAnnouncement({
    required String announcementId,
    required String sectionId,
    required String title,
    required String message,
  }) async {
    try {
      final data = await _api.putJson(
        '/section-management/announcements/$announcementId',
        body: {'title': title, 'message': message},
      );

      return data['success'] == true ||
          data['anuncio'] != null ||
          data['message'] != null ||
          data['id'] != null ||
          data['data'] != null;
    } catch (e) {
      if (!_canUseMockFallback(e)) rethrow;
      debugPrint('Edicion mock de anuncio delegado: $e');
      await Future<void>.delayed(const Duration(milliseconds: 300));
      final index = _mockAnnouncements.indexWhere(
        (anuncio) => anuncio.id == announcementId,
      );
      if (index == -1) {
        _mockAnnouncements.insert(
          0,
          Anuncio(
            id: announcementId,
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
      } else {
        _mockAnnouncements[index] = _mockAnnouncements[index].copyWith(
          titulo: title,
          mensaje: message,
          fecha: DateTime.now().toIso8601String(),
        );
      }
      _deletedAnnouncementIds.remove(announcementId);
      return true;
    }
  }

  Future<bool> deleteAnnouncement(String announcementId) async {
    try {
      final data = await _api.deleteJson(
        '/section-management/announcements/$announcementId',
      );

      return data['success'] == true || data['message'] != null || data.isEmpty;
    } catch (e) {
      if (!_canUseMockFallback(e)) rethrow;
      debugPrint('Eliminacion mock de anuncio delegado: $e');
      await Future<void>.delayed(const Duration(milliseconds: 250));
      _deletedAnnouncementIds.add(announcementId);
      _mockAnnouncements.removeWhere((anuncio) => anuncio.id == announcementId);
      return true;
    }
  }

  bool _canUseMockFallback(Object error) {
    if (error is! ApiException) return true;
    return error.statusCode == 404 && error.code == 'HTTP_ERROR';
  }

  List<Anuncio> _mergeLocalChanges(
    String sectionId,
    List<Anuncio> remoteAnnouncements,
  ) {
    final merged = remoteAnnouncements
        .where((anuncio) => !_deletedAnnouncementIds.contains(anuncio.id))
        .toList();
    final local = _mockAnnouncements.where(
      (anuncio) =>
          anuncio.idSeccion == sectionId &&
          !_deletedAnnouncementIds.contains(anuncio.id),
    );

    for (final localAnnouncement in local) {
      final index = merged.indexWhere(
        (remoteAnnouncement) => remoteAnnouncement.id == localAnnouncement.id,
      );
      if (index == -1) {
        merged.add(localAnnouncement);
      } else {
        merged[index] = localAnnouncement;
      }
    }

    _sortNewestFirst(merged);
    return merged;
  }

  void _sortNewestFirst(List<Anuncio> anuncios) {
    anuncios.sort((a, b) {
      final aDate = DateTime.tryParse(a.fecha);
      final bDate = DateTime.tryParse(b.fecha);
      if (aDate == null && bDate == null) return 0;
      if (aDate == null) return 1;
      if (bDate == null) return -1;
      return bDate.compareTo(aDate);
    });
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
