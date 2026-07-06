import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../descripcion_cursos/descrip_cursos.dart';
import 'horario_controller.dart';
import '../../components/skeleton.dart';

class HorarioPage extends StatelessWidget {
  const HorarioPage({super.key});

  static const double startHour = 7.0;
  static const double endHour = 22.0;
  static const double hourHeight = 85.0;

  double _timeToHours(String timeStr) {
    try {
      final cleanStr = timeStr.trim().toLowerCase();
      
      // If it contains am/pm, use the 12-hour parser
      if (cleanStr.contains('am') || cleanStr.contains('pm')) {
        final parts = cleanStr.split(' ');
        if (parts.length >= 2) {
          final isPm = parts[1] == 'pm';
          final hms = parts[0].split(':');
          int hour = int.tryParse(hms[0]) ?? 12;
          int minute = hms.length > 1 ? (int.tryParse(hms[1]) ?? 0) : 0;

          if (isPm && hour != 12) hour += 12;
          if (!isPm && hour == 12) hour = 0;

          return hour + (minute / 60.0);
        }
      }

      // Try 24-hour parser (e.g., "14:00:00", "14:00")
      final hms = cleanStr.split(':');
      if (hms.isNotEmpty) {
        final hour = int.tryParse(hms[0]);
        if (hour != null) {
          final minute = hms.length > 1 ? (int.tryParse(hms[1]) ?? 0) : 0;
          return hour + (minute / 60.0);
        }
      }

      return 7.0;
    } catch (_) {
      return 7.0;
    }
  }

  Color _resolveScheduleColor(String colorStr, ColorScheme colors) {
    final cleanColor = colorStr.trim();
    final hexColor = cleanColor.startsWith('#')
        ? cleanColor.substring(1)
        : cleanColor;

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

  Widget _currentTimeLine() {
    return IgnorePointer(
      child: SizedBox(
        height: 12,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.centerLeft,
          children: [
            Positioned(
              left: 0,
              right: 0,
              child: Container(height: 2, color: const Color(0xFFFF5252)),
            ),
            Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                color: Color(0xFFFF5252),
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(HorarioController());
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF1E1E26)
          : const Color(0xFFF8F9FA),
      body: Obx(() {
        final activeDay = controller.currentDay;
        if (activeDay == null) {
          // Skeleton con la silueta del horario (selector de días + bloques
          // de clases) en lugar del spinner central.
          return SkeletonPulse(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      for (var i = 0; i < 5; i++) ...[
                        const Expanded(
                          child: SkeletonBox(height: 44, borderRadius: 12),
                        ),
                        if (i < 4) const SizedBox(width: 8),
                      ],
                    ],
                  ),
                  const SizedBox(height: 22),
                  for (final alto in const [88.0, 64.0, 110.0, 76.0]) ...[
                    SkeletonBox(
                      width: double.infinity,
                      height: alto,
                      borderRadius: 14,
                    ),
                    const SizedBox(height: 14),
                  ],
                ],
              ),
            ),
          );
        }

        final courses = controller.currentDayCourses;
        final totalHours = (endHour - startHour).toInt() + 1;
        final currentHour = controller.currentLimaHourDecimal;
        final showCurrentTimeLine =
            controller.isCurrentLimaDay(activeDay) &&
            currentHour >= startHour &&
            currentHour <= endHour;
        final currentLineTop = (currentHour - startHour) * hourHeight + 6.0;

        return Column(
          children: [
            Container(
              color: isDark ? const Color(0xFF262630) : const Color(0xFFFFF2EC),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: colors.primary,
                      size: 20,
                    ),
                    onPressed: controller.previousDay,
                  ),
                  Text(
                    '${activeDay.dayName}, ${activeDay.dateText}',
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF2D2D2D),
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: colors.primary,
                      size: 20,
                    ),
                    onPressed: controller.nextDay,
                  ),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 1, color: Color(0xFFE5E5E5)),
            Container(
              width: double.infinity,
              color: isDark ? const Color(0xFF1B1B22) : Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 8),
              alignment: Alignment.center,
              child: Text(
                activeDay.weekText,
                style: TextStyle(
                  color: isDark
                      ? const Color(0xFFB0B0C0)
                      : const Color(0xFF666666),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Divider(height: 1, thickness: 1, color: Color(0xFFE5E5E5)),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Stack(
                    children: [
                      Column(
                        children: List.generate(totalHours, (index) {
                          final hourVal = startHour + index;
                          final isPm = hourVal >= 12;
                          final displayHour = hourVal > 12
                              ? (hourVal - 12).toInt()
                              : hourVal.toInt();
                          final amPm = isPm ? 'pm' : 'am';

                          return SizedBox(
                            height: hourHeight,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 65,
                                  child: Padding(
                                    padding: const EdgeInsets.only(
                                      left: 16,
                                      top: 4,
                                    ),
                                    child: Text(
                                      '$displayHour $amPm',
                                      style: TextStyle(
                                        color: isDark
                                            ? const Color(0xFF9090A0)
                                            : const Color(0xFF9E9E9E),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Container(
                                    margin: const EdgeInsets.only(top: 12),
                                    height: 1.2,
                                    color: isDark
                                        ? const Color(0xFF2C2C38)
                                        : const Color(0xFFECECEC),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ),
                      ...courses.map((course) {
                        final bool isEvaluation =
                            course['isEvaluation'] == true;

                        final nombreStr =
                            (course['curso'] as String? ?? 'CURSO')
                                .toUpperCase();
                        final aulaStr =
                            course['salon'] as String? ?? 'Sin salón';
                        final colorStr = course['color'] as String? ?? 'blue';
                        final startStr =
                            course['hora_inicio'] as String? ?? '07:00 am';
                        final endStr =
                            course['hora_fin'] as String? ?? '09:00 am';

                        final startVal = _timeToHours(startStr);
                        final endVal = _timeToHours(endStr);

                        final double topPosition =
                            (startVal - startHour) * hourHeight + 12.0;
                        final double heightVal =
                            (endVal - startVal) * hourHeight - 8.0;

                        final courseColor = _resolveScheduleColor(colorStr, colors);

                        return Positioned(
                          top: topPosition,
                          left: 75,
                          right: 20,
                          height: heightVal,
                          child: InkWell(
                            onTap: () {
                              final String idSeccion = course['idSeccion']?.toString() ?? '';
                              if (idSeccion.isNotEmpty) {
                                Get.to(
                                  () => DescripCursosPage(idSeccion: idSeccion),
                                );
                              }
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              decoration: BoxDecoration(
                                color: courseColor,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: courseColor.withValues(
                                      alpha: 0.35,
                                    ),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Stack(
                                children: [
                                  Center(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Text(
                                            nombreStr,
                                            textAlign: TextAlign.center,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: 0.3,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            "Sección: ${course['codigoSeccion'] ?? 'Sin sección'}",
                                            style: TextStyle(
                                              color: Colors.white.withValues(
                                                alpha: 0.9,
                                              ),
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            aulaStr,
                                            style: TextStyle(
                                              color: Colors.white.withValues(
                                                alpha: 0.9,
                                              ),
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  if (isEvaluation)
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(
                                            alpha: 0.25,
                                          ),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          "📝 EVAL: ${course['evalSigla']}",
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 8,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 0.3,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                      if (showCurrentTimeLine)
                        Positioned(
                          top: currentLineTop,
                          left: 75,
                          right: 0,
                          child: _currentTimeLine(),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}
