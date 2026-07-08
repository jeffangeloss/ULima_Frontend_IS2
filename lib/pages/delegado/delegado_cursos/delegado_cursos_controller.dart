import 'package:get/get.dart';

import '../../../models/curso_delegado_model.dart';
import '../../../services/delegate_service.dart';
import '../delegado_anuncios/delegado_anuncios_page.dart';

class DelegadoCursosController extends GetxController {
  DelegadoCursosController({DelegateService? delegateService})
    : _delegateService = delegateService ?? DelegateService();

  final DelegateService _delegateService;

  final cursos = <CursoDelegado>[].obs;
  final loading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchCursos();
  }

  Future<void> fetchCursos() async {
    loading.value = true;
    try {
      cursos.assignAll(await _delegateService.fetchDelegateSections());
    } finally {
      loading.value = false;
    }
  }

  void openCurso(CursoDelegado curso) {
    Get.to(() => DelegadoAnunciosPage(curso: curso));
  }
}
