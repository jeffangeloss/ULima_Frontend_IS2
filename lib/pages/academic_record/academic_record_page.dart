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
import 'record_course_row.dart';
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

  /// Key de cada chip de ciclo. El chip y el encabezado de la tarjeta dicen el
  /// mismo texto, así que los tests tocan por key, no por texto.
  static ValueKey<String> periodChipKey(String periodCode) =>
      ValueKey<String>('record-period-chip-$periodCode');

  /// Key de la tarjeta de cursos del ciclo elegido.
  static const Key coursesCardKey = Key('record-courses-card');

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
          // Chips de ciclo y cursos del ciclo elegido (RF-REC-2), en su propio
          // Obx: el Obx del body solo registra los Rx que se leen dentro de su
          // closure, y selectedPeriodCode.value se lee acá. Sin este Obx,
          // tocar un chip cambiaría el Rx y la lista no se repintaría.
          Obx(() {
            // currentPeriodCode lee selectedPeriodCode.value y el récord, y
            // controller.record vuelve a leer el mismo Rx: los dos quedan
            // registrados en ESTE Obx. Por eso se usa controller.record y no
            // el campo `record` del widget, que no es observable.
            final selected = controller.currentPeriodCode;
            final rec = controller.record;
            if (rec == null || selected == null) {
              return const SizedBox.shrink();
            }
            // `selected` sale de estos mismos `coursesByPeriod`, leídos sin
            // ningún await en medio: el ciclo siempre está.
            final period = rec.coursesByPeriod.firstWhere(
              (p) => p.periodCode == selected,
            );
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _PeriodChips(
                  periodCodes: controller.periodCodes,
                  selected: selected,
                  onSelect: controller.selectPeriod,
                ),
                const SizedBox(height: 12),
                _PeriodCoursesCard(
                  period: period,
                  average: AcademicRecordController.periodAverage(
                    rec.periodSummaries,
                    selected,
                  ),
                  isMostRecent: controller.isMostRecentPeriod(selected),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

/// Fila horizontal de chips de ciclo (RF-REC-2), en el orden del backend: del
/// más reciente al más viejo. Plantilla: `_FilterChips`
/// (lib/pages/teacher/at_risk_students_page.dart:391-412).
class _PeriodChips extends StatelessWidget {
  const _PeriodChips({
    required this.periodCodes,
    required this.selected,
    required this.onSelect,
  });

  final List<String> periodCodes;
  final String selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // El padding va a la derecha de cada chip, también del último: así
          // el final de la fila respira cuando se llega scrolleando.
          for (final code in periodCodes)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _PeriodChip(
                key: AcademicRecordPage.periodChipKey(code),
                periodCode: code,
                isSelected: code == selected,
                onTap: () => onSelect(code),
              ),
            ),
        ],
      ),
    );
  }
}

/// Un chip de ciclo. Copia de `_FilterChip`
/// (lib/pages/teacher/at_risk_students_page.dart:444-485) con el naranja de la
/// app fijo y sin el conteo entre paréntesis, más la key y el Semantics que
/// aquel no tiene.
class _PeriodChip extends StatelessWidget {
  const _PeriodChip({
    super.key,
    required this.periodCode,
    required this.isSelected,
    required this.onTap,
  });

  final String periodCode;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const chipColor = MaterialTheme.primaryColor;
    return Semantics(
      button: true,
      selected: isSelected,
      child: GestureDetector(
        onTap: onTap,
        // Opaque para que el toque valga también en el padding del chip, no
        // solo encima del texto.
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? chipColor.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? chipColor : chipColor.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: Text(
            periodCode,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isSelected ? chipColor : chipColor.withValues(alpha: 0.7),
            ),
          ),
        ),
      ),
    );
  }
}

/// Los cursos del ciclo elegido, en una tarjeta (RF-REC-2).
///
/// El promedio llega ya resuelto desde `periods`: si el backend no tiene ese
/// ciclo, o su `average` es null, acá llega null y no se pinta nada. Nunca un
/// 0. Del resumen del ciclo no entra nada más: ni la ubicación relativa, ni el
/// nivel, ni los grupos de cursos y créditos. Cada fila es un
/// [RecordCourseRow], y es esta tarjeta la que le dice si el ciclo es el más
/// reciente del récord (RF-REC-3).
class _PeriodCoursesCard extends StatelessWidget {
  const _PeriodCoursesCard({
    required this.period,
    required this.average,
    required this.isMostRecent,
  });

  final RecordPeriod period;
  final double? average;
  final bool isMostRecent;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.brightnessOf(context);
    final promedio = average;
    final filas = <Widget>[];
    for (var i = 0; i < period.courses.length; i++) {
      if (i > 0) {
        filas.add(
          Divider(
            height: 1,
            thickness: 1,
            color: MaterialTheme.borderColor(brightness),
          ),
        );
      }
      filas.add(
        RecordCourseRow(
          course: period.courses[i],
          isMostRecentPeriod: isMostRecent,
        ),
      );
    }
    return Container(
      key: AcademicRecordPage.coursesCardKey,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MaterialTheme.cardBg(brightness),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: MaterialTheme.borderColor(brightness)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                period.periodCode,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: MaterialTheme.textPrimary(brightness),
                ),
              ),
              const Spacer(),
              if (promedio != null)
                Text(
                  'prom. ${formatDecimal(promedio)}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: MaterialTheme.textSecondary(brightness),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          ...filas,
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
