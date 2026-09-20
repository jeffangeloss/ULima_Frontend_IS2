// lib/pages/academic_record/academic_record_controller.dart
// Controller de /mi-record (RF-REC-2).

import 'package:get/get.dart';

import '../../models/academic_record_model.dart';
import '../../services/academic_record_service.dart';
import '../../services/auth_service.dart';

/// Vista de la pantalla sobre el estado único del récord.
///
/// No guarda una copia del récord: lo lee de [AcademicRecordService], que es el
/// mismo estado que pinta la tarjeta del Perfil (RF-REC-5). Así, al volver con
/// back después de borrar, la tarjeta no puede mostrar cifras viejas.
class AcademicRecordController extends GetxController {
  AcademicRecordController({
    AcademicRecordService? service,
    DateTime Function()? now,
  })  : _service = service ?? AcademicRecordService.to,
        _now = now ?? DateTime.now;

  final AcademicRecordService _service;
  final DateTime Function() _now;

  AcademicRecord? get record => _service.record;
  bool get isLoading => _service.isLoading;

  /// Un docente nunca tiene récord: el servicio no dispara el GET para él
  /// (RF-REC-1) y la pantalla se quedaría en el skeleton para siempre.
  /// `/mi-record` es una ruta con nombre y cualquiera puede llegar a ella
  /// ("Qué NO entra: mostrar el récord a otros roles").
  bool get hasError =>
      _service.hasError || (AuthService.to.currentUser?.isTeacher ?? false);

  String? get syncedLabel {
    final s = record?.syncedAt;
    return s == null ? null : syncedAgoLabel(s, _now());
  }

  Future<void> retry() => _service.load(force: true);

  @override
  void onReady() {
    // GetX agenda onReady después del primer frame, así que ningún Rx cambia
    // mientras build construye: el Obx de la tarjeta del Perfil, que queda
    // debajo en la pila, escucha estos mismos Rx.
    super.onReady();
    _service.load();
  }

  /// Pura y expuesta para probarla. Compara FECHAS de calendario en Lima
  /// (UTC-5, sin horario de verano), no bloques de 24 h: una sincronización a
  /// las 23:30 de ayer es "hace 1 día" aunque haya pasado una hora.
  static String syncedAgoLabel(DateTime syncedAt, DateTime now) {
    DateTime diaEnLima(DateTime t) {
      final lima = t.toUtc().subtract(const Duration(hours: 5));
      return DateTime.utc(lima.year, lima.month, lima.day);
    }

    final dias = diaEnLima(now).difference(diaEnLima(syncedAt)).inDays;
    if (dias <= 0) return 'Sincronizado hoy';
    if (dias == 1) return 'Sincronizado hace 1 día';
    return 'Sincronizado hace $dias días';
  }
}
