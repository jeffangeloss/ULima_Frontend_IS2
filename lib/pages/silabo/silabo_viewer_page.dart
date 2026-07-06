// lib/pages/silabo/silabo_viewer_page.dart
// HU21: visor de sílabos DENTRO de la app (ruta '/silabo').
// Reemplaza la expulsión a Drive del botón "Ver Sílabo": muestra el PDF con
// pinch-zoom e indicador "Página N de M". Estados explícitos:
//   - cargando: skeleton tipo "página de documento"
//   - error:   mensaje claro + "Reintentar" y fallback "Abrir en Drive"
//   - listo:   PdfViewPinch (pdfx)
// Dark mode completo vía MaterialTheme.
//
// Ampliación HU21 (issue #106, 2026-07-06):
//   - Zoom tipo lupa: pill flotante acercar/alejar/restablecer + doble-toque,
//     sobre el mismo PdfViewPinch (control programático del zoom).
//   - Botón descargar/compartir en el AppBar: hoja de compartir del sistema
//     con el PDF cacheado (en iOS "Guardar en Archivos" = descarga).
//     Deshabilitado mientras carga; oculto en estado de error.

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pdfx/pdfx.dart';

import '../../components/skeleton.dart';
import '../../configs/themes.dart';
import 'silabo_viewer_controller.dart';

class SilaboViewerPage extends GetView<SilaboViewerController> {
  const SilaboViewerPage({super.key});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return Scaffold(
      backgroundColor: MaterialTheme.pageBg(brightness),
      appBar: AppBar(
        backgroundColor: MaterialTheme.headerColor(brightness),
        foregroundColor: Colors.white,
        title: Text(
          controller.cursoTitulo,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          overflow: TextOverflow.ellipsis,
        ),
        actions: [_BotonCompartir(controller: controller)],
      ),
      body: Obx(() {
        switch (controller.estado.value) {
          case SilaboViewerEstado.cargando:
            return const _SilaboSkeleton();
          case SilaboViewerEstado.error:
            return _SilaboError(controller: controller);
          case SilaboViewerEstado.listo:
            return _SilaboPdf(controller: controller);
        }
      }),
    );
  }
}

/// Visor PDF con pinch-zoom, doble-toque, pill de zoom (acercar / alejar /
/// restablecer) y chip flotante "Página N de M".
class _SilaboPdf extends StatelessWidget {
  const _SilaboPdf({required this.controller});

  final SilaboViewerController controller;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return LayoutBuilder(builder: (context, constraints) {
      final viewport = constraints.biggest;
      return Stack(
        children: [
          Positioned.fill(
            child: _DobleToqueZoom(
              controller: controller,
              viewport: viewport,
              child: PdfViewPinch(
                controller: controller.pdfController!,
                maxScale: SilaboViewerController.zoomMaximo,
                onDocumentLoaded: controller.onDocumentLoaded,
                onPageChanged: controller.onPageChanged,
                onDocumentError: controller.onDocumentError,
                backgroundDecoration: BoxDecoration(
                  color: MaterialTheme.pageBg(brightness),
                ),
                builders: PdfViewPinchBuilders<DefaultBuilderOptions>(
                  options: const DefaultBuilderOptions(),
                  documentLoaderBuilder: (_) => const _SilaboSkeleton(),
                  errorBuilder: (_, _) => _SilaboError(controller: controller),
                ),
              ),
            ),
          ),
          // Pill de zoom en la esquina inferior derecha, por encima del chip
          // de página (bottom 16 + alto del chip) para no taparlo.
          Positioned(
            right: 12,
            bottom: 64,
            child: _ControlesZoom(controller: controller, viewport: viewport),
          ),
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Center(
              child: Obx(() {
                final total = controller.totalPaginas.value;
                if (total <= 0) return const SizedBox.shrink();
                return IgnorePointer(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: MaterialTheme.blackColor.withValues(alpha: 0.72),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      'Página ${controller.paginaActual.value} de $total',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      );
    });
  }
}

/// Doble-toque estilo lector de PDF: amplía anclado al punto tocado; si ya
/// hay zoom, vuelve al ajuste de ancho. No interfiere con el pinch/arrastre
/// de PdfViewPinch (usa solo el reconocedor de doble toque).
class _DobleToqueZoom extends StatefulWidget {
  const _DobleToqueZoom({
    required this.controller,
    required this.viewport,
    required this.child,
  });

  final SilaboViewerController controller;
  final Size viewport;
  final Widget child;

  @override
  State<_DobleToqueZoom> createState() => _DobleToqueZoomState();
}

class _DobleToqueZoomState extends State<_DobleToqueZoom> {
  // Posición capturada en el down; el zoom se ejecuta recién en onDoubleTap,
  // cuando el gesto está CONFIRMADO (en onDoubleTapDown el segundo contacto
  // aún puede convertirse en arrastre y dispararía un zoom no deseado).
  Offset? _posicionDobleToque;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onDoubleTapDown: (details) => _posicionDobleToque = details.localPosition,
      onDoubleTap: () {
        final posicion = _posicionDobleToque;
        if (posicion != null) {
          widget.controller.alternarZoomDobleToque(posicion, widget.viewport);
        }
        _posicionDobleToque = null;
      },
      onDoubleTapCancel: () => _posicionDobleToque = null,
      child: widget.child,
    );
  }
}

/// Pill vertical flotante con los controles de zoom explícitos.
class _ControlesZoom extends StatelessWidget {
  const _ControlesZoom({required this.controller, required this.viewport});

  final SilaboViewerController controller;
  final Size viewport;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final divider = Container(
      width: 22,
      height: 1,
      color: MaterialTheme.borderColor(brightness),
    );
    return Container(
      decoration: BoxDecoration(
        color: MaterialTheme.cardBg(brightness).withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: MaterialTheme.borderColor(brightness)),
        boxShadow: [
          BoxShadow(
            color: MaterialTheme.blackColor.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Obx(() {
        final zoom = controller.nivelZoom.value;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _BotonZoom(
              icono: Icons.add,
              tooltip: 'Acercar',
              habilitado: zoom < SilaboViewerController.zoomMaximo - 0.01,
              onPressed: () => controller.acercar(viewport),
            ),
            divider,
            _BotonZoom(
              icono: Icons.remove,
              tooltip: 'Alejar',
              habilitado: zoom > SilaboViewerController.zoomMinimo + 0.01,
              onPressed: () => controller.alejar(viewport),
            ),
            divider,
            _BotonZoom(
              icono: Icons.fit_screen_outlined,
              tooltip: 'Restablecer zoom',
              habilitado: true,
              onPressed: controller.restablecerZoom,
            ),
          ],
        );
      }),
    );
  }
}

/// Botón individual de la pill de zoom (compacto, theme-aware).
class _BotonZoom extends StatelessWidget {
  const _BotonZoom({
    required this.icono,
    required this.tooltip,
    required this.habilitado,
    required this.onPressed,
  });

  final IconData icono;
  final String tooltip;
  final bool habilitado;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return IconButton(
      onPressed: habilitado ? onPressed : null,
      tooltip: tooltip,
      iconSize: 20,
      visualDensity: VisualDensity.compact,
      color: MaterialTheme.textPrimary(brightness),
      disabledColor: MaterialTheme.textMuted(brightness).withValues(alpha: 0.5),
      icon: Icon(icono),
    );
  }
}

/// Botón del AppBar para descargar/compartir el PDF ya cacheado.
/// Deshabilitado mientras carga o mientras se abre la hoja; oculto en error.
class _BotonCompartir extends StatelessWidget {
  const _BotonCompartir({required this.controller});

  final SilaboViewerController controller;

  @override
  Widget build(BuildContext context) {
    final esIos = Theme.of(context).platform == TargetPlatform.iOS;
    return Obx(() {
      if (controller.estado.value == SilaboViewerEstado.error) {
        return const SizedBox.shrink();
      }
      final habilitado = controller.estado.value == SilaboViewerEstado.listo &&
          !controller.compartiendo.value;
      return IconButton(
        tooltip: 'Descargar sílabo',
        onPressed: habilitado
            ? () {
                // Rect del botón: ancla del popover de compartir en iPad.
                final box = context.findRenderObject() as RenderBox?;
                final origen = (box != null && box.hasSize)
                    ? box.localToGlobal(Offset.zero) & box.size
                    : null;
                controller.compartir(origen: origen);
              }
            : null,
        icon: Icon(esIos ? Icons.ios_share : Icons.share_outlined),
      );
    });
  }
}

/// Skeleton de carga con silueta de página de documento (título + párrafos).
class _SilaboSkeleton extends StatelessWidget {
  const _SilaboSkeleton();

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return SkeletonPulse(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: MaterialTheme.cardBg(brightness),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              SkeletonBox(width: 180, height: 18),
              SizedBox(height: 18),
              SkeletonBox(height: 12),
              SizedBox(height: 8),
              SkeletonBox(height: 12),
              SizedBox(height: 8),
              SkeletonBox(width: 240, height: 12),
              SizedBox(height: 24),
              SkeletonBox(width: 140, height: 14),
              SizedBox(height: 12),
              SkeletonBox(height: 12),
              SizedBox(height: 8),
              SkeletonBox(height: 12),
              SizedBox(height: 8),
              SkeletonBox(height: 12),
              SizedBox(height: 8),
              SkeletonBox(width: 200, height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

/// Estado de error: mensaje claro + "Reintentar" + fallback "Abrir en Drive".
class _SilaboError extends StatelessWidget {
  const _SilaboError({required this.controller});

  final SilaboViewerController controller;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.picture_as_pdf_outlined,
              size: 56,
              color: MaterialTheme.textMuted(brightness),
            ),
            const SizedBox(height: 16),
            Obx(
              () => Text(
                controller.mensajeError.value,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: MaterialTheme.textSecondary(brightness),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: controller.cargar,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: MaterialTheme.primaryColor,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: controller.abrirEnDrive,
              icon: const Icon(Icons.open_in_new, size: 18),
              label: const Text('Abrir en Drive'),
              style: OutlinedButton.styleFrom(
                foregroundColor: MaterialTheme.textPrimary(brightness),
                side: BorderSide(color: MaterialTheme.borderColor(brightness)),
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
