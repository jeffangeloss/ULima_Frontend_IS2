import 'package:get/get.dart';

import '../../../models/anuncio_model.dart';
import '../../../models/curso_delegado_model.dart';
import '../../../models/estadisticas_seccion_model.dart';
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
}
