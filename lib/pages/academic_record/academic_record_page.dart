// lib/pages/academic_record/academic_record_page.dart
// Pantalla "Mi récord académico" (RF-REC-2 y RF-REC-4).

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../components/error_retry.dart';
import '../../components/skeleton.dart';
import '../../configs/themes.dart';
import '../../models/academic_record_model.dart';
import 'academic_record_controller.dart';
import 'record_format.dart';
import 'record_position_badge.dart';

/// El histórico del portal, con un estilo más entendible que su tabla de 12
/// columnas.
///
/// No confundir con "Notas oficiales" (`/mis-notas`), que son las que el
/// docente carga en ULima++ para el ciclo en curso.
class AcademicRecordPage extends GetView<AcademicRecordController> {
  const AcademicRecordPage({super.key});

  static const String title = 'Mi récord académico';
  static const String emptyTitle = 'Aún no tienes tu récord';
  static const String emptyBody =
      'Sincroniza con miUlima una vez y verás aquí tus notas de toda la '
      'carrera, tu PPA y tus créditos.';
  static const String syncButtonLabel = 'Sincronizar con el portal';
  static const String loadErrorTitle = 'No se pudo cargar tu récord';

  static const Key skeletonKey = Key('record-page-skeleton');
  static const Key ringKey = Key('record-credits-ring');
  static const Key successViewKey = Key('record-success-view');

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.brightnessOf(context);

    return Scaffold(
      backgroundColor: MaterialTheme.pageBg(brightness),
      appBar: AppBar(
        title: const Text(
          title,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        centerTitle: false,
      ),
      body: Obx(() {
        final record = controller.record;
        // Sin récord en memoria: o falló la carga, o todavía está en camino.
        if (record == null) {
          if (controller.hasError) {
            return ErrorRetry(title: loadErrorTitle, onRetry: controller.retry);
          }
          return const _RecordSkeleton();
        }
        if (!record.hasRecord) return const _RecordEmptyState();
        return _RecordSuccessView(controller: controller, record: record);
      }),
    );
  }
}

/// Silueta de la pantalla mientras carga: encabezado, chips y tarjeta.
class _RecordSkeleton extends StatelessWidget {
  const _RecordSkeleton();

  @override
  Widget build(BuildContext context) {
    return const SkeletonPulse(
      key: AcademicRecordPage.skeletonKey,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 18, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkeletonBox(width: double.infinity, height: 110, borderRadius: 14),
            SizedBox(height: 16),
            Row(
              children: [
                SkeletonBox(width: 64, height: 30, borderRadius: 20),
                SizedBox(width: 8),
                SkeletonBox(width: 64, height: 30, borderRadius: 20),
                SizedBox(width: 8),
                SkeletonBox(width: 64, height: 30, borderRadius: 20),
              ],
            ),
            SizedBox(height: 16),
            SkeletonBox(width: double.infinity, height: 220, borderRadius: 14),
          ],
        ),
      ),
    );
  }
}

/// RF-REC-4: el alumno nunca sincronizó. No es un error ni una lista vacía.
class _RecordEmptyState extends StatelessWidget {
  const _RecordEmptyState();

  @override
  Widget build(BuildContext context) {
    final b = Theme.brightnessOf(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history_edu_outlined,
              size: 48,
              color: MaterialTheme.textMuted(b),
            ),
            const SizedBox(height: 12),
            Text(
              AcademicRecordPage.emptyTitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: MaterialTheme.textPrimary(b),
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AcademicRecordPage.emptyBody,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: MaterialTheme.textSecondary(b),
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => Get.toNamed<dynamic>('/portal-sync'),
              style: FilledButton.styleFrom(
                backgroundColor: MaterialTheme.primaryColor,
                foregroundColor: Colors.white,
                minimumSize: const Size(0, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(AcademicRecordPage.syncButtonLabel),
            ),
          ],
        ),
      ),
    );
  }
}

/// El récord cargado. SingleChildScrollView y no ListView: así todos los hijos
/// existen en el árbol aunque queden fuera de pantalla.
class _RecordSuccessView extends StatelessWidget {
  const _RecordSuccessView({required this.controller, required this.record});

  final AcademicRecordController controller;
  final AcademicRecord record;

  @override
  Widget build(BuildContext context) {
    final b = Theme.brightnessOf(context);
    final synced = controller.syncedLabel;

    return SingleChildScrollView(
      key: AcademicRecordPage.successViewKey,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _RecordHeader(snapshot: record.snapshot),
          const SizedBox(height: 10),
          if (synced != null)
            Text(
              synced,
              style: TextStyle(
                color: MaterialTheme.textMuted(b),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

/// Anillo de créditos, PPA e insignia de ubicación relativa.
///
/// Cada pieza se omite si su dato falta: un récord sin créditos requeridos no
/// dibuja un anillo en 0 %, y uno sin PPA no muestra "0".
class _RecordHeader extends StatelessWidget {
  const _RecordHeader({required this.snapshot});

  final AcademicSnapshot? snapshot;

  @override
  Widget build(BuildContext context) {
    final b = Theme.brightnessOf(context);
    final s = snapshot;
    final progress = creditsProgress(s?.creditsAccumulated, s?.creditsRequired);
    final ppa = s?.ppa;
    final posicion = formatRelativePosition(s?.relativePosition);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MaterialTheme.cardBg(b),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: MaterialTheme.borderColor(b)),
      ),
      child: Row(
        children: [
          if (progress != null) ...[
            SizedBox(
              key: AcademicRecordPage.ringKey,
              width: 84,
              height: 84,
              child: CustomPaint(
                painter: _CreditsRingPainter(
                  progress: progress,
                  track: MaterialTheme.progressBg(b),
                  color: MaterialTheme.primaryColor,
                ),
                child: Center(
                  child: Text(
                    progressPercentLabel(progress),
                    style: TextStyle(
                      color: MaterialTheme.textPrimary(b),
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (ppa != null) ...[
                  Text(
                    'PPA',
                    style: TextStyle(
                      color: MaterialTheme.labelColor(b),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    formatDecimal(ppa),
                    style: TextStyle(
                      color: MaterialTheme.textPrimary(b),
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
                if (posicion != null) ...[
                  const SizedBox(height: 6),
                  RecordPositionBadge(label: posicion),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Anillo del avance de créditos, con la misma forma que `_AnilloAsistencia`
/// de descrip_cursos.dart: pista completa y un arco que arranca a las 12.
class _CreditsRingPainter extends CustomPainter {
  const _CreditsRingPainter({
    required this.progress,
    required this.track,
    required this.color,
  });

  final double progress;
  final Color track;
  final Color color;

  static const double _grosor = 8;
  static const double _arriba = -math.pi / 2;

  @override
  void paint(Canvas canvas, Size size) {
    final rect =
        Rect.fromLTWH(0, 0, size.width, size.height).deflate(_grosor / 2);
    final trazo = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _grosor
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(rect.center, rect.width / 2, trazo..color = track);

    final barrido = progress.clamp(0.0, 1.0) * 2 * math.pi;
    if (barrido > 0) {
      canvas.drawArc(rect, _arriba, barrido, false, trazo..color = color);
    }
  }

  @override
  bool shouldRepaint(_CreditsRingPainter old) =>
      old.progress != progress || old.track != track || old.color != color;
}
