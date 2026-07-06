// lib/pages/silabo/silabo_viewer_controller.dart
// HU21: controller del visor in-app de sílabos (ruta '/silabo').
// Recibe por argumentos la URL del sílabo (formato Drive de la BD) y el
// título del curso; descarga el PDF vía SilaboService y expone estados
// explícitos de carga/éxito/error para la página.

import 'package:get/get.dart';
import 'package:pdfx/pdfx.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain/silabo/silabo_link.dart';
import '../../services/silabo_service.dart';

enum SilaboViewerEstado { cargando, listo, error }

class SilaboViewerController extends GetxController {
  SilaboViewerController({SilaboService? service})
      : _service = service ?? SilaboService();

  final SilaboService _service;

  /// Título del curso mostrado en el AppBar.
  String cursoTitulo = 'Sílabo';

  /// URL cruda recibida de la BD (para el fallback si no parsea como Drive).
  String? rawUrl;

  /// Enlace de Drive interpretado; null si la URL no es de Drive.
  SilaboLink? link;

  final estado = SilaboViewerEstado.cargando.obs;
  final mensajeError = ''.obs;

  /// Indicador "página N de M".
  final paginaActual = 1.obs;
  final totalPaginas = 0.obs;

  /// Controller de pdfx; se crea recién cuando hay bytes válidos.
  PdfControllerPinch? pdfController;

  /// Distingue el primer intento de un "Reintentar" (que ignora la caché).
  bool _yaIntento = false;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Map) {
      final titulo = args['titulo'];
      if (titulo is String && titulo.trim().isNotEmpty) {
        cursoTitulo = titulo.trim();
      }
      final url = args['url'];
      if (url is String && url.trim().isNotEmpty) rawUrl = url.trim();
    }
    link = SilaboLink.tryParse(rawUrl);
    cargar();
  }

  /// Descarga el PDF y prepara el visor. Reentrante (botón "Reintentar").
  Future<void> cargar() async {
    final l = link;
    if (l == null) {
      mensajeError.value =
          'El enlace del sílabo no es válido para verlo dentro de la app.';
      estado.value = SilaboViewerEstado.error;
      return;
    }

    estado.value = SilaboViewerEstado.cargando;
    try {
      final bytes = await _service.obtenerPdf(l, forzarDescarga: _yaIntento);
      _yaIntento = true;
      if (isClosed) return;

      pdfController?.dispose();
      paginaActual.value = 1;
      totalPaginas.value = 0;
      pdfController = PdfControllerPinch(document: PdfDocument.openData(bytes));
      estado.value = SilaboViewerEstado.listo;
    } on SilaboException catch (e) {
      _yaIntento = true;
      if (isClosed) return;
      mensajeError.value = e.message;
      estado.value = SilaboViewerEstado.error;
    } catch (_) {
      _yaIntento = true;
      if (isClosed) return;
      mensajeError.value = 'No se pudo abrir el sílabo.';
      estado.value = SilaboViewerEstado.error;
    }
  }

  /// Callback de PdfViewPinch al terminar de abrir el documento.
  void onDocumentLoaded(PdfDocument document) {
    totalPaginas.value = document.pagesCount;
  }

  /// Callback de PdfViewPinch al cambiar de página visible.
  void onPageChanged(int page) {
    paginaActual.value = page;
  }

  /// El propio render del PDF falló (bytes corruptos): degradar a error.
  void onDocumentError(Object error) {
    if (isClosed) return;
    mensajeError.value =
        'El sílabo no está disponible para verlo dentro de la app.';
    estado.value = SilaboViewerEstado.error;
  }

  /// Fallback: abrir el sílabo en Drive (comportamiento previo a HU21).
  Future<void> abrirEnDrive() async {
    final url = link?.externalViewUrl ?? rawUrl;
    if (url == null) return;
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  @override
  void onClose() {
    pdfController?.dispose();
    super.onClose();
  }
}
