import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'horario_controller.dart';
import '../descripcion_cursos/descrip_cursos.dart';
import '../chat/chat_page.dart';

class HorarioListView extends StatelessWidget {
  final HorarioController controller = Get.find();

  HorarioListView({super.key});

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

  Widget _buildAttendanceRing(int asistido, int inasistencia, int total) {
    if (total == 0) total = 1; // Prevent division by zero visually
    final double porcentaje = asistido / total;
    final String percentText = '${(inasistencia / total * 100).toStringAsFixed(0)}%'; // Usually absence is shown in the screenshot? Wait, the screenshot shows 0%, 4%, 2%, 12%. That looks like absence (inasistencia) percentage!

    return Row(
      children: [
        Text(
          percentText,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 50,
          height: 50,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 50,
                height: 50,
                child: CircularProgressIndicator(
                  value: porcentaje,
                  strokeWidth: 8,
                  backgroundColor: Colors.red,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                ),
              ),
              Container(
                width: 30,
                height: 30,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Obx(() {
      final uniqueCourses = controller.uniqueEnrolledCourses;
      final showAttendance = controller.showAttendance.value;

      return Column(
        children: [
          // Header del List View
          Container(
            color: isDark ? const Color(0xFF262630) : const Color(0xFFFFF2EC),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back, color: colors.primary),
                  onPressed: controller.toggleListView,
                ),
                Text(
                  showAttendance ? 'Actualizado: Hace 1 hora' : 'Mis Cursos',
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF2D2D2D),
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: showAttendance ? Colors.white.withOpacity(0.3) : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.remove_red_eye,
                      color: showAttendance ? Colors.black : colors.primary,
                    ),
                    onPressed: controller.toggleAttendance,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFE5E5E5)),

          Expanded(
            child: uniqueCourses.isEmpty
                ? const Center(child: Text("No hay cursos matriculados"))
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: uniqueCourses.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final course = uniqueCourses[index];
                      final courseColor = _resolveScheduleColor(course['color']?.toString() ?? 'blue', colors);
                      final nombre = (course['curso'] as String? ?? 'CURSO').toUpperCase();
                      final seccion = course['codigoSeccion']?.toString() ?? 'Sin sección';
                      final idSeccion = course['idSeccion']?.toString() ?? '';

                      // Extract attendance data
                      final asistido = (course['asistido'] as num?)?.toInt() ?? 0;
                      final inasistencia = (course['inasistencia'] as num?)?.toInt() ?? 0;
                      final total = (course['total'] as num?)?.toInt() ?? (asistido + inasistencia > 0 ? asistido + inasistencia : 1);

                      return InkWell(
                        onTap: () {
                          if (idSeccion.isNotEmpty) {
                            Get.to(() => DescripCursosPage(idSeccion: idSeccion));
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          child: Row(
                            children: [
                              Container(
                                width: 14,
                                height: 14,
                                decoration: BoxDecoration(
                                  color: courseColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      nombre,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? Colors.white : Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Sección: $seccion',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (showAttendance) ...[
                                _buildAttendanceRing(asistido, inasistencia, total),
                                const SizedBox(width: 8),
                              ],
                              GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () {
                                  if (idSeccion.isNotEmpty) {
                                    Get.to(() => ChatPage(sectionId: idSeccion, courseName: nombre));
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  child: const Text('💬', style: TextStyle(fontSize: 22)),
                                ),
                              ),
                              Icon(
                                Icons.chevron_right,
                                color: isDark ? Colors.grey[600] : Colors.grey[400],
                              ),
                            ],
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
