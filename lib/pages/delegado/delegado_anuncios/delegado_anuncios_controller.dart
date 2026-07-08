import 'package:get/get.dart';

import '../../../models/anuncio_model.dart';
import '../../../models/curso_delegado_model.dart';
import '../../../models/estadisticas_seccion_model.dart';
import '../../../services/api_client.dart';
import '../../../services/delegate_announcement_service.dart';
import '../../../services/section_statistics_service.dart';
import 'create_announcement_page.dart';

class DelegadoAnunciosController extends GetxController {
  DelegadoAnunciosController({
    required this.curso,
    DelegateAnnouncementService? announcementService,
    SectionStatisticsService? statisticsService,
  }) : _announcementService =
           announcementService ?? DelegateAnnouncementService(),
       _statisticsService = statisticsService ?? SectionStatisticsService();

  final CursoDelegado curso;
  final DelegateAnnouncementService _announcementService;
  final SectionStatisticsService _statisticsService;

  final loadingStats = false.obs;
  final loadingAnnouncements = false.obs;
  final anunciosPublicados = <Anuncio>[].obs;
  final statistics = Rxn<EstadisticasSeccion>();

  @override
  void onInit() {
    super.onInit();
    fetchAnnouncements();
    fetchStatistics();
  }

  Future<void> fetchAnnouncements() async {
    loadingAnnouncements.value = true;
    try {
      anunciosPublicados.assignAll(
        await _announcementService.fetchAnnouncementsBySection(curso.idSeccion),
      );
    } on ApiException catch (e) {
      anunciosPublicados.clear();
      Get.snackbar('No se pudieron cargar los anuncios', e.message);
    } finally {
      loadingAnnouncements.value = false;
    }
  }

  Future<void> fetchStatistics() async {
    loadingStats.value = true;
    try {
      statistics.value = await _statisticsService.fetchSectionStatistics(
        curso.idSeccion,
      );
    } finally {
      loadingStats.value = false;
    }
  }

  Future<void> refreshAll() async {
    await Future.wait([fetchAnnouncements(), fetchStatistics()]);
  }

  Future<void> openCreate() async {
    final created = await Get.to<bool>(
      () => CreateAnnouncementPage(curso: curso),
    );
    if (created == true) await fetchAnnouncements();
  }

  Future<void> openEdit(Anuncio anuncio) async {
    final updated = await Get.to<bool>(
      () => CreateAnnouncementPage(curso: curso, anuncio: anuncio),
    );
    if (updated == true) await fetchAnnouncements();
  }

  Future<void> deleteAnnouncement(Anuncio anuncio) async {
    try {
      final deleted = await _announcementService.deleteAnnouncement(anuncio.id);
      if (deleted) {
        anunciosPublicados.removeWhere((item) => item.id == anuncio.id);
        Get.snackbar('Anuncio eliminado', 'El historial ya fue actualizado.');
      } else {
        Get.snackbar('No se pudo eliminar', 'Intenta nuevamente.');
      }
    } on ApiException catch (e) {
      Get.snackbar('No se pudo eliminar', e.message);
    } catch (e) {
      Get.snackbar('No se pudo eliminar', 'Intenta nuevamente.');
    }
  }
}
