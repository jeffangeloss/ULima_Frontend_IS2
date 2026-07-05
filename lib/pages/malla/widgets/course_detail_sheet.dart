// lib/pages/malla/widgets/course_detail_sheet.dart
// Bottom sheet de detalles de un curso, extraído de malla_page.dart (HU19)
// para compartirlo entre la malla clásica (lienzo) y la vista lista.
// El contenido visual es el mismo; las dependencias del controller se
// inyectan por parámetro para que cualquier vista pueda reusarlo.

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../configs/themes.dart';
import '../../../models/malla_models.dart';
import '../../../services/evaluations_service.dart';

/// Abre el sheet con el estilo compartido por ambas vistas de la malla.
void showCourseDetailSheet(
  BuildContext context, {
  required CourseNode course,
  required Map<String, CourseStatus> statuses,
  required Map<String, CourseNode> courseById,
  required bool Function(int throughLevel, Map<String, CourseStatus> statuses)
      hasCompletedMandatoryCycles,
  VoidCallback? onCycleStatus,
}) {
  final brightness = Theme.of(context).brightness;
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: MaterialTheme.sheetBg(brightness),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => CourseDetailSheet(
      course: course,
      statuses: statuses,
      courseById: courseById,
      hasCompletedMandatoryCycles: hasCompletedMandatoryCycles,
      onCycleStatus: onCycleStatus,
    ),
  );
}

class CourseDetailSheet extends StatelessWidget {
  const CourseDetailSheet({
    super.key,
    required this.course,
    required this.statuses,
    required this.courseById,
    required this.hasCompletedMandatoryCycles,
    this.onCycleStatus,
  });

  final CourseNode course;
  final Map<String, CourseStatus> statuses;

  /// Lookup id → curso para mostrar nombres de prerrequisitos.
  final Map<String, CourseNode> courseById;

  /// True si todos los obligatorios hasta el nivel dado están aprobados
  /// según [statuses] (delegado a la capa de dominio por el caller).
  final bool Function(int throughLevel, Map<String, CourseStatus> statuses)
      hasCompletedMandatoryCycles;

  /// Acción del botón de ciclo de estado. Null → el sheet es solo lectura
  /// (la vista lista lo oculta fuera del modo simulación).
  final VoidCallback? onCycleStatus;

  @override
  Widget build(BuildContext context) {
    final currentStatus = statuses[course.id] ?? CourseStatus.locked;
    final brightness = Theme.of(context).brightness;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: MaterialTheme.sheetHandle(brightness),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: currentStatus.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  course.code,
                  style: TextStyle(
                    color: currentStatus.borderColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _PillStatus(status: currentStatus),
              if (course.isExternal) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: MaterialTheme.externalBadgeBg(brightness),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    course.externalFaculty!,
                    style: TextStyle(
                      color: MaterialTheme.textDimmed(brightness),
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(
            course.name,
            style: TextStyle(
              color: MaterialTheme.textPrimary(brightness),
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _InfoTag(
                icon: Icons.layers_outlined,
                text: 'Nivel ${course.level}',
              ),
              _InfoTag(
                icon: Icons.workspace_premium_outlined,
                text: '${course.credits} créditos',
              ),
              if (course.isElective)
                const _InfoTag(icon: Icons.bookmark_border, text: 'Electivo'),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Prerrequisitos',
            style: TextStyle(
              color: MaterialTheme.textSecondary(brightness),
              fontSize: 13,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 6),
          _PrereqList(
            course: course,
            statuses: statuses,
            courseById: courseById,
            hasCompletedMandatoryCycles: hasCompletedMandatoryCycles,
          ),
          if (course.isElective && course.specialties.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Forma parte de los diplomas',
              style: TextStyle(
                color: MaterialTheme.textSecondary(brightness),
                fontSize: 13,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: course.specialties
                  .map(
                    (s) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: MaterialTheme.specialtyBg(brightness),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        s,
                        style: const TextStyle(
                          color: MaterialTheme.primaryDark,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
          const SizedBox(height: 12),
          _SilaboLink(courseId: course.id),
          const SizedBox(height: 18),
          if (currentStatus == CourseStatus.locked)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: MaterialTheme.lockedBg(brightness),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.lock_outline,
                      size: 16, color: MaterialTheme.textMuted(brightness)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Este curso está bloqueado hasta que cumplas sus prerrequisitos.',
                      style: TextStyle(
                        color: MaterialTheme.textDimmed(brightness),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else if (onCycleStatus != null)
            ElevatedButton.icon(
              onPressed: () {
                onCycleStatus!();
                Navigator.pop(context);
              },
              icon: const Icon(Icons.repeat, size: 18),
              label: Text(_nextStatusLabel(currentStatus)),
              style: ElevatedButton.styleFrom(
                backgroundColor: MaterialTheme.primaryColor,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _nextStatusLabel(CourseStatus s) {
    switch (s) {
      case CourseStatus.unlocked:
        return 'Marcar como cursando';
      case CourseStatus.current:
        return 'Marcar como aprobado';
      case CourseStatus.approved:
        return 'Volver a disponible';
      case CourseStatus.locked:
        return 'No disponible';
    }
  }
}

class _PrereqList extends StatelessWidget {
  const _PrereqList({
    required this.course,
    required this.statuses,
    required this.courseById,
    required this.hasCompletedMandatoryCycles,
  });

  final CourseNode course;
  final Map<String, CourseStatus> statuses;
  final Map<String, CourseNode> courseById;
  final bool Function(int throughLevel, Map<String, CourseStatus> statuses)
      hasCompletedMandatoryCycles;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final concrete = course.coursePrerequisites;
    final cycleReq = course.requiredCompletedLevel;
    final cycleReqOk = cycleReq == null
        ? false
        : hasCompletedMandatoryCycles(cycleReq, statuses);

    if (concrete.isEmpty && cycleReq == null) {
      return Text(
        'Este curso no tiene prerrequisitos.',
        style: TextStyle(
          color: MaterialTheme.textMuted(brightness),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      );
    }

    return Column(
      children: [
        if (cycleReq != null)
          _PrereqRow(
            label:
                'Haber aprobado todos los obligatorios hasta el nivel $cycleReq',
            ok: cycleReqOk,
            icon: cycleReqOk ? Icons.flag_outlined : Icons.block,
          ),
        ...concrete.map((p) {
          final c = courseById[p];
          final ok = statuses[p] == CourseStatus.approved;
          return _PrereqRow(
            label: c?.name ?? p,
            ok: ok,
            icon: ok ? Icons.done_all : Icons.block,
          );
        }),
      ],
    );
  }
}

class _PrereqRow extends StatelessWidget {
  const _PrereqRow({required this.label, required this.ok, required this.icon});
  final String label;
  final bool ok;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final color = ok ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: MaterialTheme.textSecondary(brightness),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoTag extends StatelessWidget {
  const _InfoTag({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: MaterialTheme.tagBg(brightness),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: MaterialTheme.textSecondary(brightness)),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              color: MaterialTheme.textSecondary(brightness),
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _PillStatus extends StatelessWidget {
  const _PillStatus({required this.status});
  final CourseStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: status.borderColor.withValues(alpha: 0.5)),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: status.borderColor,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _SilaboLink extends StatelessWidget {
  const _SilaboLink({required this.courseId});
  final String courseId;

  @override
  Widget build(BuildContext context) {
    final url = EvaluationSyllabusService().getSilaboUrl(courseId);
    if (url == null) return const SizedBox.shrink();

    final brightness = Theme.of(context).brightness;
    final linkColor = brightness == Brightness.light
        ? const Color(0xFF0369A1)
        : const Color(0xFF38BDF8);

    return GestureDetector(
      onTap: () =>
          launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.open_in_new, size: 14, color: linkColor),
          const SizedBox(width: 5),
          Text(
            'Ver Sílabo',
            style: TextStyle(
              color: linkColor,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              decoration: TextDecoration.underline,
              decorationColor: linkColor,
            ),
          ),
        ],
      ),
    );
  }
}
