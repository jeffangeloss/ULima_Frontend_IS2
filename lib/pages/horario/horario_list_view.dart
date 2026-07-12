import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'horario_controller.dart';
import '../descripcion_cursos/descrip_cursos.dart';
import '../chat/chat_page.dart';
import '../../configs/themes.dart';

class HorarioListView extends StatelessWidget {
  final HorarioController controller = Get.find();

  HorarioListView({super.key});

  /// Color del curso: resuelve el hex del backend (#RRGGBB / RRGGBB / AARRGGBB)
  /// o, como fallback, un nombre de color. Es el acento por-curso de cada card.
  Color _resolveScheduleColor(String colorStr, ColorScheme colors) {
    final cleanColor = colorStr.trim();
    final hexColor =
        cleanColor.startsWith('#') ? cleanColor.substring(1) : cleanColor;

    if (RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(hexColor)) {
      return Color(int.parse('FF$hexColor', radix: 16));
    }
    if (RegExp(r'^[0-9a-fA-F]{8}$').hasMatch(hexColor)) {
      return Color(int.parse(hexColor, radix: 16));
    }

    return {
          'pink': colors.secondaryContainer,
          'blue': colors.secondary,
          'orange': colors.primary,
          'green': colors.tertiaryContainer,
          'purple': colors.tertiary,
          'teal': colors.primaryContainer,
          'red': colors.error,
        }[cleanColor.toLowerCase()] ??
        colors.outline;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    return Obx(() {
      final uniqueCourses = controller.uniqueEnrolledCourses;
      final showAttendance = controller.showAttendance.value;

      return Column(
        children: [
          // Sub-header naranja claro con back + título + toggle de asistencia.
          Container(
            color: isDark ? const Color(0xFF262630) : const Color(0xFFFFF2EC),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back, color: colors.primary),
                  onPressed: controller.toggleListView,
                  tooltip: 'Volver',
                ),
                Expanded(
                  child: Text(
                    showAttendance ? 'Mi asistencia' : 'Mis cursos',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: MaterialTheme.textPrimary(brightness),
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    showAttendance
                        ? Icons.remove_red_eye
                        : Icons.remove_red_eye_outlined,
                    color: colors.primary,
                  ),
                  tooltip: showAttendance
                      ? 'Ver lista de cursos'
                      : 'Ver asistencia',
                  onPressed: controller.toggleAttendance,
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            thickness: 1,
            color: MaterialTheme.borderColor(brightness),
          ),

          Expanded(
            child: uniqueCourses.isEmpty
                ? _EmptyCourses(brightness: brightness)
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    itemCount: uniqueCourses.length,
                    itemBuilder: (context, index) {
                      final course = uniqueCourses[index];
                      final courseColor = _resolveScheduleColor(
                        course['color']?.toString() ?? 'blue',
                        colors,
                      );
                      final nombre =
                          (course['curso'] as String? ?? 'CURSO').toUpperCase();
                      final seccion =
                          course['codigoSeccion']?.toString() ?? 'Sin sección';
                      final idSeccion = course['idSeccion']?.toString() ?? '';

                      final asistido = (course['asistido'] as num?)?.toInt() ?? 0;
                      final inasistencia =
                          (course['inasistencia'] as num?)?.toInt() ?? 0;
                      final total = (course['total'] as num?)?.toInt() ??
                          (asistido + inasistencia > 0
                              ? asistido + inasistencia
                              : 1);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _CourseCard(
                          brightness: brightness,
                          courseColor: courseColor,
                          nombre: nombre,
                          seccion: seccion,
                          showAttendance: showAttendance,
                          asistido: asistido,
                          inasistencia: inasistencia,
                          total: total,
                          onOpenCourse: idSeccion.isEmpty
                              ? null
                              : () => Get.to(
                                    () => DescripCursosPage(idSeccion: idSeccion),
                                  ),
                          onOpenChat: idSeccion.isEmpty
                              ? null
                              : () => Get.to(
                                    () => ChatPage(
                                      sectionId: idSeccion,
                                      courseName: nombre,
                                    ),
                                  ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      );
    });
  }
}

/// Card de curso del alumno: acento por color de curso (barra sólida), tile,
/// nombre + sección, y accesos claros a chat y detalle. Iconos vectoriales (no
/// emojis), touch targets ≥44pt, y contraste accesible (el color va en fills,
/// el texto en tokens neutros).
class _CourseCard extends StatelessWidget {
  const _CourseCard({
    required this.brightness,
    required this.courseColor,
    required this.nombre,
    required this.seccion,
    required this.showAttendance,
    required this.asistido,
    required this.inasistencia,
    required this.total,
    required this.onOpenCourse,
    required this.onOpenChat,
  });

  final Brightness brightness;
  final Color courseColor;
  final String nombre;
  final String seccion;
  final bool showAttendance;
  final int asistido;
  final int inasistencia;
  final int total;
  final VoidCallback? onOpenCourse;
  final VoidCallback? onOpenChat;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: MaterialTheme.cardBg(brightness),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: MaterialTheme.borderColor(brightness)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onOpenCourse,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Acento por-curso: barra sólida con el color hex del curso.
                Container(width: 6, color: courseColor),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
                    child: Row(
                      children: [
                        // Tile con el color del curso.
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: courseColor.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.menu_book_rounded,
                            color: courseColor,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                nombre,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: MaterialTheme.textPrimary(brightness),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Sección $seccion',
                                style: TextStyle(
                                  color: MaterialTheme.textSecondary(brightness),
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (showAttendance) ...[
                          const SizedBox(width: 8),
                          _AttendanceRing(
                            asistido: asistido,
                            inasistencia: inasistencia,
                            total: total,
                            brightness: brightness,
                          ),
                        ],
                        const SizedBox(width: 6),
                        // Acceso al chat: botón claro y con label a11y (no emoji).
                        Semantics(
                          button: true,
                          label: 'Abrir chat de la sección',
                          child: Material(
                            color: courseColor.withValues(alpha: 0.16),
                            shape: const CircleBorder(),
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                              onTap: onOpenChat,
                              child: SizedBox(
                                width: 44,
                                height: 44,
                                child: Icon(
                                  Icons.forum_rounded,
                                  color: courseColor,
                                  size: 21,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          color: MaterialTheme.textMuted(brightness),
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Anillo compacto de asistencia (modo "Mi asistencia"): track neutro + avance
/// asistido, con el % de inasistencia. Semántica verde/ámbar/rojo por riesgo.
class _AttendanceRing extends StatelessWidget {
  const _AttendanceRing({
    required this.asistido,
    required this.inasistencia,
    required this.total,
    required this.brightness,
  });

  final int asistido;
  final int inasistencia;
  final int total;
  final Brightness brightness;

  @override
  Widget build(BuildContext context) {
    final safeTotal = total == 0 ? 1 : total;
    final attendedRatio = (asistido / safeTotal).clamp(0.0, 1.0);
    final absencePct = (inasistencia / safeTotal * 100).round();

    // Color por riesgo de inasistencia (umbral Ulima: 20% riesgo, 25% impedido).
    final Color ringColor = absencePct >= 25
        ? const Color(0xFFDC2626)
        : absencePct >= 20
            ? const Color(0xFFF59E0B)
            : const Color(0xFF16A34A);

    return SizedBox(
      width: 40,
      height: 40,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              value: attendedRatio,
              strokeWidth: 4.5,
              backgroundColor: MaterialTheme.borderColor(brightness),
              valueColor: AlwaysStoppedAnimation<Color>(ringColor),
            ),
          ),
          Text(
            '$absencePct%',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: MaterialTheme.textPrimary(brightness),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyCourses extends StatelessWidget {
  const _EmptyCourses({required this.brightness});
  final Brightness brightness;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.menu_book_outlined,
              size: 48,
              color: MaterialTheme.textMuted(brightness),
            ),
            const SizedBox(height: 12),
            Text(
              'No hay cursos matriculados.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: MaterialTheme.textSecondary(brightness),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
