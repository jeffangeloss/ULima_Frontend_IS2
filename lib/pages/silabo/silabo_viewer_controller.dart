// lib/pages/silabo/silabo_viewer_controller.dart
// HU21: controller del visor in-app de sílabos (ruta '/silabo').
// Recibe por argumentos la URL del sílabo (formato Drive de la BD) y el
// título del curso; descarga el PDF vía SilaboService y expone estados
// explícitos de carga/éxito/error para la página.
//
// Ampliación HU21 (issue #106, 2026-07-06):
//   - Zoom tipo lupa con controles explícitos (acercar/alejar/restablecer y
//     doble-toque). API verificada en pdfx 2.9.2: PdfControllerPinch extiende
//     TransformationController y expone goTo(matrix), zoomRatio y
//     calculatePageFitMatrix(), así que el zoom programático se hace sobre el
//     MISMO PdfViewPinch sin cambiar de widget (ruta "a").
//   - Compartir/descargar el PDF ya cacheado con la hoja del sistema
//     (share_plus); en iOS "Guardar en Archivos" ES la descarga.

import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:pdfx/pdfx.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain/silabo/silabo_link.dart';
import '../../services/silabo_service.dart';

enum SilaboViewerEstado { cargando, listo, error }

/// Firma de la hoja de compartir del sistema; inyectable para tests.
typedef CompartirArchivos = Future<ShareResult> Function(ShareParams params);

/// Fábrica del controller de pdfx; inyectable para tests (sin canales
/// nativos: un PdfControllerPinch con un document que nunca completa).
typedef CrearPdfController = PdfControllerPinch Function(Uint8List bytes);

class SilaboViewerController extends GetxController {
  SilaboViewerController({
    SilaboService? service,
    CompartirArchivos? compartirArchivos,
    CrearPdfController? crearPdfController,
  })  : _service = service ?? SilaboService(),
        _compartirArchivos =
            compartirArchivos ?? ((params) => SharePlus.instance.share(params)),
        _crearPdfController = crearPdfController ??
            ((bytes) =>
                PdfControllerPinch(document: PdfDocument.openData(bytes)));

  final SilaboService _service;
  final CompartirArchivos _compartirArchivos;
  final CrearPdfController _crearPdfController;

  /// Límites y pasos del zoom. 1.0 = ajuste de ancho: pdfx maqueta las
  /// páginas ocupando el ancho del viewport a escala 1 (layout base).
  static const double zoomMinimo = 1.0;
  static const double zoomMaximo = 5.0;
  static const double factorPasoZoom = 1.4;
  static const double zoomDobleToque = 2.5;

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

  /// Nivel de zoom actual (1.0 = ajuste de ancho). Se sincroniza también con
  /// el pinch del usuario para habilitar/deshabilitar los botones.
  final nivelZoom = 1.0.obs;

  /// True mientras se prepara/abre la hoja de compartir (evita doble toque).
  final compartiendo = false.obs;

  /// Controller de pdfx; se crea recién cuando hay bytes válidos.
  PdfControllerPinch? pdfController;

  /// Bytes del PDF ya validados (%PDF); fuente del botón de compartir.
  Uint8List? _bytesPdf;

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
      nivelZoom.value = zoomMinimo;
      _bytesPdf = bytes;
      pdfController = _crearPdfController(bytes)
        ..addListener(_sincronizarZoom);
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
    _bytesPdf = null;
    mensajeError.value =
        'El sílabo no está disponible para verlo dentro de la app.';
    estado.value = SilaboViewerEstado.error;
  }

  // ---------------------------------------------------------------------
  // Zoom tipo lupa (ruta "a": control programático sobre PdfControllerPinch,
  // que ES un TransformationController: value = Matrix4 del InteractiveViewer
  // interno de PdfViewPinch).
  // ---------------------------------------------------------------------

  /// Un paso de zoom hacia adentro, anclado al centro del [viewport].
  void acercar(Size viewport) => _zoomPorFactor(factorPasoZoom, viewport);

  /// Un paso de zoom hacia afuera, anclado al centro del [viewport].
  void alejar(Size viewport) => _zoomPorFactor(1 / factorPasoZoom, viewport);

  /// Vuelve al ajuste de ancho de la página visible (escala 1.0).
  Future<void> restablecerZoom() async {
    final c = pdfController;
    if (c == null || estado.value != SilaboViewerEstado.listo) return;
    try {
      final destino = c.calculatePageFitMatrix(pageNumber: c.page);
      if (destino == null) return;
      await c.goTo(destination: destino);
    } catch (_) {
      // Visor aún no montado/medido: no hay nada que restablecer.
    }
  }

  /// Doble-toque estilo lector de PDF: si ya hay zoom, vuelve al ajuste de
  /// ancho; si no, amplía a [zoomDobleToque] anclado en [posicion].
  void alternarZoomDobleToque(Offset posicion, Size viewport) {
    final c = pdfController;
    if (c == null || estado.value != SilaboViewerEstado.listo) return;
    if (c.zoomRatio > zoomMinimo + 0.1) {
      restablecerZoom();
      return;
    }
    _irA(calcularMatrizZoom(
      actual: c.value,
      factor: zoomDobleToque / c.zoomRatio,
      centro: posicion,
      viewport: viewport,
      documento: _tamanoDocumento(),
    ));
  }

  void _zoomPorFactor(double factor, Size viewport) {
    final c = pdfController;
    if (c == null || estado.value != SilaboViewerEstado.listo) return;
    _irA(calcularMatrizZoom(
      actual: c.value,
      factor: factor,
      centro: viewport.center(Offset.zero),
      viewport: viewport,
      documento: _tamanoDocumento(),
    ));
  }

  void _irA(Matrix4 destino) {
    try {
      pdfController?.goTo(
        destination: destino,
        duration: const Duration(milliseconds: 180),
      );
    } catch (_) {
      // goTo exige el visor montado (_state interno); si no lo está, no-op.
    }
  }

  void _sincronizarZoom() {
    final c = pdfController;
    if (c == null) return;
    nivelZoom.value = c.zoomRatio;
  }

  /// Tamaño del documento maquetado (a escala 1), derivado de los rects
  /// públicos de la primera y última página (el padding del layout es
  /// simétrico). Null si el visor todavía no maquetó.
  Size? _tamanoDocumento() {
    final c = pdfController;
    final paginas = c?.pagesCount;
    if (c == null || paginas == null || paginas < 1) return null;
    try {
      final primera = c.getPageRect(1);
      final ultima = c.getPageRect(paginas);
      if (primera == null || ultima == null) return null;
      return Size(primera.right + primera.left, ultima.bottom + primera.top);
    } catch (_) {
      return null;
    }
  }

  /// Matriz destino al aplicar [factor] de zoom alrededor de [centro] (en
  /// coordenadas del viewport), con la escala resultante limitada a
  /// [minimo]..[maximo]. Si se conoce el tamaño del [documento] (a escala 1),
  /// también corrige la traslación para no dejar bandas vacías al alejar.
  /// Función pura (sin estado del visor): testeable de forma aislada.
  static Matrix4 calcularMatrizZoom({
    required Matrix4 actual,
    required double factor,
    required Offset centro,
    required Size viewport,
    Size? documento,
    double minimo = zoomMinimo,
    double maximo = zoomMaximo,
  }) {
    final escalaActual = actual.row0[0] <= 0 ? 1.0 : actual.row0[0];
    final escalaFinal =
        (escalaActual * factor).clamp(minimo, maximo).toDouble();
    final f = escalaFinal / escalaActual;

    // destino = T(centro) · S(f) · T(-centro) · actual  →  el punto del
    // documento que estaba bajo [centro] sigue bajo [centro] tras el zoom.
    final destino = (Matrix4.identity()
          ..translateByDouble(centro.dx, centro.dy, 0, 1)
          ..scaleByDouble(f, f, 1, 1)
          ..translateByDouble(-centro.dx, -centro.dy, 0, 1))
        .multiplied(actual);

    if (documento != null) {
      // Sin huecos: la traslación t debe cumplir
      //   viewport - escala*documento <= t <= 0   (por eje).
      // Si el contenido es más chico que el viewport (PDF de 1 página corta),
      // se alinea al borde superior/izquierdo (t = 0).
      double corregir(double t, double vista, double contenido) {
        final tMinimo = (vista - contenido).clamp(double.negativeInfinity, 0.0);
        return t.clamp(tMinimo, 0.0).toDouble();
      }

      destino.setEntry(
        0,
        3,
        corregir(destino.row0[3], viewport.width,
            escalaFinal * documento.width),
      );
      destino.setEntry(
        1,
        3,
        corregir(destino.row1[3], viewport.height,
            escalaFinal * documento.height),
      );
    }
    return destino;
  }

  // ---------------------------------------------------------------------
  // Descarga / compartir (share_plus)
  // ---------------------------------------------------------------------

  /// Comparte el PDF ya descargado con la hoja del sistema (en iOS incluye
  /// "Guardar en Archivos", que es la descarga en móvil). [origen] es el rect
  /// del botón: obligatorio para el popover de iPad.
  Future<void> compartir({Rect? origen}) async {
    final bytes = _bytesPdf;
    if (bytes == null ||
        compartiendo.value ||
        estado.value != SilaboViewerEstado.listo) {
      return;
    }
    compartiendo.value = true;
    try {
      final archivo = await _service.prepararCompartible(cursoTitulo, bytes);
      await _compartirArchivos(ShareParams(
        files: [XFile(archivo.path, mimeType: 'application/pdf')],
        subject: cursoTitulo,
        sharePositionOrigin: origen,
      ));
    } catch (_) {
      if (isClosed) return;
      Get.snackbar('No se pudo compartir', 'Intenta de nuevo en unos minutos.');
    } finally {
      if (!isClosed) compartiendo.value = false;
    }
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
