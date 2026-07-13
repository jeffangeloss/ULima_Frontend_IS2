import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../components/skeleton.dart';
import '../../configs/course_colors.dart';
import '../../configs/themes.dart';
import '../../models/official_grades_models.dart';
import 'teacher_grade_section_controller.dart';

/// Grilla de calificación de una sección: el profesor toca un alumno y pone
/// sus notas por evaluación. La nota final se calcula por ponderación.
/// Header con el nombre del curso completo (sin cortes) + color por curso, y
/// buscador por código/apellido para ubicar al alumno rápido.
class TeacherGradeSectionPage extends StatelessWidget {
  const TeacherGradeSectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<TeacherGradeSectionController>();
    final brightness = Theme.brightnessOf(context);
    final accent = courseAccentColor(controller.sectionId);

    return Scaffold(
      backgroundColor: MaterialTheme.pageBg(brightness),
      appBar: AppBar(title: const Text('Calificar')),
      body: Obx(() {
        final loading = controller.isLoading.value;
        final grid = controller.grid.value;

        if (loading && grid == null) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: SkeletonCardList(count: 6, showAvatar: true),
          );
        }
        if (controller.loadError.value != null && grid == null) {
          return _fill(_Empty(icon: Icons.wifi_off, message: controller.loadError.value!, brightness: brightness));
        }
        if (grid == null || grid.students.isEmpty) {
          return _fill(_Empty(
            icon: Icons.group_outlined,
            message: 'No hay alumnos matriculados en esta sección.',
            brightness: brightness,
          ));
        }

        return Column(
          children: [
            _CourseHeader(
              courseName: controller.courseName,
              sectionCode: controller.sectionCode,
              studentCount: grid.students.length,
              assessmentCount: grid.assessments.length,
              accent: accent,
              brightness: brightness,
            ),
            _SearchBar(onChanged: controller.setSearch, brightness: brightness),
            Expanded(
              child: Obx(() {
                final visible = controller.visibleStudents;
                if (visible.isEmpty) {
                  return _fill(_Empty(
                    icon: Icons.search_off,
                    message: 'Sin resultados para "${controller.search.value}".',
                    brightness: brightness,
                  ));
                }
                return RefreshIndicator(
                  onRefresh: controller.load,
                  color: MaterialTheme.primaryColor,
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 88),
                    itemCount: visible.length,
                    itemBuilder: (_, i) {
                      final student = visible[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _StudentTile(
                          student: student,
                          accent: accent,
                          finalGrade: controller.finalFor(student.enrollmentId),
                          calificado: controller.hasAnyScore(student.enrollmentId),
                          brightness: brightness,
                          onTap: () => _openSheet(context, controller, student, brightness),
                        ),
                      );
                    },
                  ),
                );
              }),
            ),
          ],
        );
      }),
    );
  }

  void _openSheet(
    BuildContext context,
    TeacherGradeSectionController controller,
    GradingStudent student,
    Brightness brightness,
  ) {
    final grid = controller.grid.value;
    if (grid == null) return;
    final current = <int, double?>{
      for (final a in grid.assessments) a.assessmentId: controller.scoreFor(student.enrollmentId, a.assessmentId),
    };
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: MaterialTheme.cardBg(brightness),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _GradeStudentSheet(
        student: student,
        assessments: grid.assessments,
        current: current,
        brightness: brightness,
        onSave: (values) => controller.saveStudent(student.enrollmentId, values),
      ),
    );
  }

  Widget _fill(Widget child) => ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [SizedBox(height: 420, child: Center(child: child))],
      );
}

/// Banner del curso: nombre COMPLETO (se ajusta en varias líneas, sin recorte),
/// sección y conteos. Acento por color del curso.
class _CourseHeader extends StatelessWidget {
  const _CourseHeader({
    required this.courseName,
    required this.sectionCode,
    required this.studentCount,
    required this.assessmentCount,
    required this.accent,
    required this.brightness,
  });

  final String courseName;
  final String sectionCode;
  final int studentCount;
  final int assessmentCount;
  final Color accent;
  final Brightness brightness;

  @override
  Widget build(BuildContext context) {
    final subtitle = [
      if (sectionCode.isNotEmpty) 'Sección $sectionCode',
      '$studentCount alumnos',
      '$assessmentCount evaluaciones',
    ].join(' · ');

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.school_rounded, color: accent, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  courseName,
                  // Sin recorte: el nombre largo se ajusta en hasta 3 líneas.
                  maxLines: 3,
                  softWrap: true,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    height: 1.2,
                    color: MaterialTheme.textPrimary(brightness),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: MaterialTheme.textSecondary(brightness),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Buscador por código o apellido/nombre. Filtra la lista al escribir.
class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.onChanged, required this.brightness});

  final ValueChanged<String> onChanged;
  final Brightness brightness;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: TextField(
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        style: TextStyle(color: MaterialTheme.textPrimary(brightness)),
        decoration: InputDecoration(
          hintText: 'Buscar por código o apellido',
          prefixIcon: Icon(Icons.search, color: MaterialTheme.textMuted(brightness)),
          isDense: true,
          filled: true,
          fillColor: MaterialTheme.cardBg(brightness),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: MaterialTheme.borderColor(brightness)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: MaterialTheme.primaryColor, width: 1.5),
          ),
        ),
      ),
    );
  }
}

class _StudentTile extends StatelessWidget {
  const _StudentTile({
    required this.student,
    required this.accent,
    required this.finalGrade,
    required this.calificado,
    required this.brightness,
    required this.onTap,
  });

  final GradingStudent student;
  final Color accent;
  final double finalGrade;
  final bool calificado;
  final Brightness brightness;
  final VoidCallback onTap;

  String get _initials {
    final parts = student.fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts[0].characters.first + parts[1].characters.first).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final textPrimary = MaterialTheme.textPrimary(brightness);
    final textSecondary = MaterialTheme.textSecondary(brightness);

    return Material(
      color: MaterialTheme.cardBg(brightness),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: MaterialTheme.borderColor(brightness)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              // Avatar con iniciales en el color del curso (correlación cromática).
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  _initials,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: accent),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(student.fullName,
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textPrimary)),
                    const SizedBox(height: 2),
                    Text(student.code, style: TextStyle(fontSize: 12, color: textSecondary)),
                  ],
                ),
              ),
              if (calificado) _FinalPill(nota: finalGrade),
              const SizedBox(width: 6),
              Icon(Icons.edit_outlined, size: 18, color: textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

class _FinalPill extends StatelessWidget {
  const _FinalPill({required this.nota});
  final double nota;

  @override
  Widget build(BuildContext context) {
    final aprobado = nota >= 10.5;
    final color = aprobado ? const Color(0xFF16A34A) : const Color(0xFFDC2626);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(9)),
      child: Text('Final ${nota.toStringAsFixed(2)}',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: color)),
    );
  }
}

/// Bottom sheet para calificar a un alumno: un campo por evaluación.
class _GradeStudentSheet extends StatefulWidget {
  const _GradeStudentSheet({
    required this.student,
    required this.assessments,
    required this.current,
    required this.brightness,
    required this.onSave,
  });

  final GradingStudent student;
  final List<GradingAssessment> assessments;
  final Map<int, double?> current;
  final Brightness brightness;
  final Future<bool> Function(Map<int, double> values) onSave;

  @override
  State<_GradeStudentSheet> createState() => _GradeStudentSheetState();
}

class _GradeStudentSheetState extends State<_GradeStudentSheet> {
  late final Map<int, TextEditingController> _fields;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _fields = {
      for (final a in widget.assessments)
        a.assessmentId: TextEditingController(
          text: widget.current[a.assessmentId] == null
              ? ''
              : widget.current[a.assessmentId]!.toStringAsFixed(
                  widget.current[a.assessmentId]! % 1 == 0 ? 0 : 2),
        ),
    };
  }

  @override
  void dispose() {
    for (final c in _fields.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final values = <int, double>{};
    for (final entry in _fields.entries) {
      final text = entry.value.text.trim().replaceAll(',', '.');
      if (text.isEmpty) continue; // vacío = no cambiar
      final v = double.tryParse(text);
      if (v == null || v < 0 || v > 20) {
        Get.snackbar('Nota inválida', 'Las notas deben estar entre 0 y 20.');
        return;
      }
      values[entry.key] = double.parse(v.toStringAsFixed(2));
    }
    setState(() => _saving = true);
    final ok = await widget.onSave(values);
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final textPrimary = MaterialTheme.textPrimary(widget.brightness);
    final textSecondary = MaterialTheme.textSecondary(widget.brightness);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(left: 20, right: 20, top: 18, bottom: 18 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.student.fullName,
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: textPrimary)),
          Text(widget.student.code, style: TextStyle(fontSize: 12, color: textSecondary)),
          const SizedBox(height: 16),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                children: widget.assessments.map((a) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${a.code} · ${a.name}',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary),
                                  overflow: TextOverflow.ellipsis),
                              Text('Peso ${a.weight.toStringAsFixed(0)}%',
                                  style: TextStyle(fontSize: 11, color: textSecondary)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 76,
                          child: TextField(
                            controller: _fields[a.assessmentId],
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                            ],
                            textAlign: TextAlign.center,
                            decoration: InputDecoration(
                              hintText: '0-20',
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: MaterialTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: _saving
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Guardar notas', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.icon, required this.message, required this.brightness});

  final IconData icon;
  final String message;
  final Brightness brightness;

  @override
  Widget build(BuildContext context) {
    final textSecondary = MaterialTheme.textSecondary(brightness);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 48, color: textSecondary),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(message, textAlign: TextAlign.center, style: TextStyle(color: textSecondary)),
        ),
      ],
    );
  }
}
