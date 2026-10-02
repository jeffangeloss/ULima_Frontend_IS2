import 'package:get/get.dart';

import '../../configs/modo_estatico.dart';
import '../../models/portal_sync_models.dart';
import '../../services/alert_service.dart';
import '../../services/auth_service.dart';
import '../../services/portal_sync_service.dart';

class HomeController extends GetxController {
  /// En modo estático no se crea el servicio del portal (RF-EST-9). Solo una
  /// prueba puede inyectar uno.
  HomeController({PortalSyncService? portalSync})
      : _portalSync = portalSync ??
            (ModoEstatico.activo ? null : PortalSyncService());

  final PortalSyncService? _portalSync;

  final portalStatus = PortalSyncStatus.desconocido.obs;

  /// "Después" oculta el aviso solo hasta el próximo arranque de la app, así que
  /// vive en memoria y no en `shared_preferences`: el alumno que aún no cargó
  /// sus datos debe volver a verlo, no perderlo para siempre por un toque.
  final pospuesto = false.obs;

  /// El aviso es solo para alumnos: portal-sync exige rol de alumno en el
  /// backend, y un docente recibiría 403.
  bool get _esAlumno => !(AuthService.to.currentUser?.isTeacher ?? false);

  /// La versión estática no ofrece cargar desde miUlima (RF-EST-9). El estado
  /// se lee antes que el modo, porque el `Obx` del inicio exige leer un
  /// observable en cada construcción.
  bool get mostrarBannerCarga {
    final faltanCursos = portalStatus.value.needsImport;
    return !ModoEstatico.activo &&
        _esAlumno &&
        !pospuesto.value &&
        faltanCursos;
  }

  /// Texto del aviso. `activePeriod` puede venir null (el contrato lo permite
  /// cuando todavía no hay ningún período activo), así que hay dos redacciones.
  String get textoBanner {
    final p = portalStatus.value.activePeriod;
    return p == null
        ? 'Aún no tienes tus cursos cargados. Tráelos desde miUlima.'
        : 'Aún no tienes los cursos del ciclo ${p.code}. Tráelos desde miUlima.';
  }

  @override
  void onInit() {
    super.onInit();
    try {
      AlertService.to.fetchAlerts();
    } catch (_) {}
    refrescarEstadoPortal();
  }

  /// `status()` nunca lanza: ante cualquier fallo devuelve el estado neutro, que
  /// deja el aviso oculto. Proponerle cargar a quien ya tiene sus datos es peor
  /// que no proponérselo a quien los necesita, que igual puede entrar por Perfil.
  Future<void> refrescarEstadoPortal() async {
    final portal = _portalSync;
    if (ModoEstatico.activo || portal == null || !_esAlumno) return;
    portalStatus.value = await portal.status();
  }

  void posponerCarga() => pospuesto.value = true;
}
