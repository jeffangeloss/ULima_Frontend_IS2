// lib/pages/silabo/silabo_viewer_page.dart
// HU21: visor de sílabos DENTRO de la app (ruta '/silabo').
// Reemplaza la expulsión a Drive del botón "Ver Sílabo": muestra el PDF con
// pinch-zoom e indicador "Página N de M". Estados explícitos:
//   - cargando: skeleton tipo "página de documento"
//   - error:   mensaje claro + "Reintentar" y fallback "Abrir en Drive"
//   - listo:   PdfViewPinch (pdfx)
// Dark mode completo vía MaterialTheme.

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

/// Visor PDF con pinch-zoom + chip flotante "Página N de M".
class _SilaboPdf extends StatelessWidget {
  const _SilaboPdf({required this.controller});

  final SilaboViewerController controller;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Stack(
      children: [
        Positioned.fill(
          child: PdfViewPinch(
            controller: controller.pdfController!,
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
        Positioned(
          bottom: 16,
          left: 0,
          right: 0,
          child: Center(
            child: Obx(() {
              final total = controller.totalPaginas.value;
              if (total <= 0) return const SizedBox.shrink();
              return Container(
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
              );
            }),
          ),
        ),
      ],
    );
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
