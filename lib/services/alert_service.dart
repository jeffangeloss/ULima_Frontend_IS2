// lib/services/alert_service.dart
// Servicio para obtener y actualizar alertas de riesgo académico.

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../configs/modo_estatico.dart';
import '../models/alert_model.dart';
import 'api_client.dart';
import 'auth_service.dart';

class AlertService extends GetxService {
  static AlertService get to => Get.find();

  /// Comienzo del título de las alertas que el backend crea con la asistencia
  /// leída de miUlima (`attendance-risk.service.ts`). En modo estático no se
  /// muestran (RF-EST-10).
  static const String prefijoAlertaDeInasistencias =
      'Alerta de inasistencias - ';

  final ApiClient _api = ApiClient();
  final RxList<AlertModel> _alerts = <AlertModel>[].obs;
  final RxBool _loading = false.obs;
  // Distingue "falló la carga" de "sin alertas": el buzón mostraba "¡Todo al
  // día!" incluso cuando la petición fallaba (ver docs/AUDITORIA_TECNICA.md §6.1).
  // Se mantiene el catch (fetchAlerts se llama fire-and-forget desde el home,
  // así que nunca debe propagar) y se expone el estado de error a la vista.
  final RxBool _hasError = false.obs;

  List<AlertModel> get alerts => _alerts;
  bool get isLoading => _loading.value;
  bool get hasError => _hasError.value;
  int get unreadCount => _alerts.where((a) => !a.isRead).length;

  Future<void> fetchAlerts() async {
    final user = AuthService.to.currentUser;
    // Las alertas de riesgo son de alumno; un docente recibe 403 en /alerts/me.
    if (user == null || user.isTeacher) return;

    _loading.value = true;
    _hasError.value = false;
    try {
      final response = await _api.getJson('/alerts/me');
      final List<dynamic> listRaw = response['alerts'] ?? [];
      final List<AlertModel> loadedAlerts = listRaw
          .map((item) {
            return AlertModel.fromJson(Map<String, dynamic>.from(item as Map));
          })
          // La versión estática oculta el riesgo de asistencia en toda
          // pantalla (RF-EST-10), también el que el servidor ya guardó. El
          // filtro vive aquí para que la campana, el contador y el buzón lo
          // compartan.
          .where(
            (a) =>
                !ModoEstatico.activo ||
                !a.title.startsWith(prefijoAlertaDeInasistencias),
          )
          .toList();
      _alerts.assignAll(loadedAlerts);
    } catch (e) {
      debugPrint('Error fetching alerts: $e');
      _hasError.value = true;
    } finally {
      _loading.value = false;
    }
  }

  Future<void> markAsRead(int alertId) async {
    final user = AuthService.to.currentUser;
    if (user == null) return;

    try {
      await _api.putJson('/alerts/me/$alertId/read', body: {});
      final index = _alerts.indexWhere((a) => a.id == alertId);
      if (index != -1) {
        _alerts[index].isRead = true;
        _alerts.refresh();
      }
    } catch (e) {
      debugPrint('Error marking alert as read: $e');
    }
  }
}
