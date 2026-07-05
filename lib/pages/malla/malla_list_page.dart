// lib/pages/malla/malla_list_page.dart
// Vista lista de la malla curricular (HU19, issues #91/#92).
//
// Lista vertical por ciclos (scroll solo vertical), con header fijo de
// progreso en créditos, chips de filtro, resaltado on-demand de
// prerrequisitos y modo simulación explícito "¿Y si...?".
//
// Interacción elegida: tap corto en la card = resaltar prerrequisitos y
// desbloqueos (modo normal) o ciclar estado (modo simulación); el ícono ⓘ
// de cada card abre el bottom sheet de detalles. Así el tap tiene UN solo
// significado por modo y los detalles quedan siempre a un tap, sin gestos
// ocultos (el long-press desaparece por completo).

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../components/skeleton.dart';
import '../../configs/themes.dart';
import '../../models/malla_models.dart';
import 'malla_list_controller.dart';
import 'widgets/course_detail_sheet.dart';

class MallaListPage extends GetView<MallaListController> {
  const MallaListPage({super.key});

  static const Color _prereqColor = Color(0xFF8B5CF6);
  static const Color _unlocksColor = Color(0xFF14B8A6);

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return Scaffold(
      backgroundColor: MaterialTheme.pageBg(brightness),
      floatingActionButton: Obx(() {
        final hidden = controller.loading.value ||
            controller.error.value != null ||
            controller.simulationMode.value;
        if (hidden) return const SizedBox.shrink();
        return FloatingActionButton.extended(
          onPressed: controller.enterSimulation,
          backgroundColor: MaterialTheme.primaryColor,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.science_outlined),
          label: const Text(
            'Simular mi avance',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
        );
      }),
      body: Column(
        children: [
          Obx(
            () => controller.simulationMode.value
                ? const _SimulationBanner()
                : const SizedBox.shrink(),
          ),
          _ProgressHeader(controller: controller),
          _FilterChipsRow(controller: controller),
          Expanded(
            child: Obx(() {
              if (controller.loading.value) {
                return const SkeletonCardList(count: 6, showAvatar: false);
              }
              final errorMsg = controller.error.value;
              if (errorMsg != null) {
                return _ErrorState(
                  message: errorMsg,
                  onRetry: controller.retry,
                );
              }
              return _CourseList(controller: controller);
            }),
          ),
          Obx(
            () => controller.simulationMode.value
                ? _SimulationPanel(controller: controller)
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

// ── Banner de modo simulación ──────────────────────────────────────────────────
class _SimulationBanner extends StatelessWidget {
  const _SimulationBanner();

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final fg = brightness == Brightness.light
        ? MaterialTheme.primaryDark
        : const Color(0xFFFFB380);
    return Container(
      width: double.infinity,
      color: MaterialTheme.primaryColor.withValues(alpha: 0.14),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(Icons.science_outlined, size: 16, color: fg),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Modo simulación — los cambios no afectan tu avance real',
              style: TextStyle(
                color: fg,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Header fijo de progreso ────────────────────────────────────────────────────
class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({required this.controller});
  final MallaListController controller;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final colors = Theme.of(context).colorScheme;
    return Obx(() {
      final sim = controller.simulationMode.value;
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        decoration: BoxDecoration(
          color: MaterialTheme.cardBg(brightness),
          border: Border(
            bottom: BorderSide(color: colors.outline.withValues(alpha: 0.5)),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mi malla',
              style: TextStyle(
                color: MaterialTheme.textPrimary(brightness),
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            // Barra de progreso: real (naranja sólido) y, en simulación,
            // proyección (naranja translúcido) detrás.
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: SizedBox(
                height: 8,
                width: double.infinity,
                child: Stack(
                  children: [
                    Container(color: MaterialTheme.progressBg(brightness)),
                    if (sim)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor:
                              controller.simApprovedRatio.clamp(0.0, 1.0),
                          heightFactor: 1,
                          child: Container(
                            color: MaterialTheme.primaryColor
                                .withValues(alpha: 0.35),
                          ),
                        ),
                      ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: controller.approvedRatio.clamp(0.0, 1.0),
                        heightFactor: 1,
                        child: Container(color: MaterialTheme.primaryColor),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${controller.approvedCredits}/${controller.totalCredits} '
              'créditos · ${controller.approvedPercent}% de la carrera',
              style: TextStyle(
                color: MaterialTheme.textSecondary(brightness),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (sim) ...[
              const SizedBox(height: 2),
              Text(
                'Proyección: ${controller.simApprovedPercent}% '
                '(${_signed(controller.simExtraCredits)} créditos simulados)',
                style: TextStyle(
                  color: brightness == Brightness.light
                      ? MaterialTheme.primaryDark
                      : const Color(0xFFFFB380),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ],
        ),
      );
    });
  }

  String _signed(int value) => value >= 0 ? '+$value' : '$value';
}

// ── Chips de filtro ────────────────────────────────────────────────────────────
class _FilterChipsRow extends StatelessWidget {
  const _FilterChipsRow({required this.controller});
  final MallaListController controller;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Container(
      width: double.infinity,
      color: MaterialTheme.cardBg(brightness),
      padding: const EdgeInsets.only(bottom: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Obx(() {
          final active = controller.filter.value;
          return Row(
            children: [
              for (final f in MallaListFilter.values) ...[
                _FilterPill(
                  label: f.label,
                  active: f == active,
                  onTap: () => controller.setFilter(f),
                ),
                if (f != MallaListFilter.values.last) const SizedBox(width: 8),
              ],
            ],
          );
        }),
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Material(
      color: active
          ? MaterialTheme.primaryColor
          : MaterialTheme.tagBg(brightness),
      borderRadius: BorderRadius.circular(99),
      child: InkWell(
        borderRadius: BorderRadius.circular(99),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(99),
            border: Border.all(
              color: active
                  ? Colors.transparent
                  : MaterialTheme.borderColor(brightness),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: active
                  ? Colors.white
                  : MaterialTheme.chipInactiveText(brightness),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Lista de ciclos ────────────────────────────────────────────────────────────
class _CourseList extends StatelessWidget {
  const _CourseList({required this.controller});
  final MallaListController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final filterActive = controller.filter.value != MallaListFilter.todos;
      final sections = <Widget>[];

      for (final level in controller.mandatoryLevels) {
        final group = controller.mandatoryForLevel(level);
        final visible = controller.filtered(group);
        if (visible.isEmpty) continue; // ciclos sin resultados se ocultan
        sections.add(
          _CycleSection(
            title: 'Ciclo $level',
            summary:
                '${controller.approvedIn(group)}/${group.length} aprobados',
            expanded:
                filterActive || controller.expandedLevels.contains(level),
            onToggle: () => controller.toggleLevel(level),
            children: [
              for (final course in visible)
                _CourseListCard(controller: controller, course: course),
            ],
          ),
        );
      }

      final electiveGroups = controller.electiveGroups;
      final visibleElectives = controller.filtered(controller.electives);
      if (visibleElectives.isNotEmpty) {
        final allElectives = controller.electives;
        sections.add(
          _CycleSection(
            title: 'Electivos',
            summary: '${controller.approvedIn(allElectives)}/'
                '${allElectives.length} aprobados',
            expanded: filterActive || controller.electivesExpanded.value,
            onToggle: controller.toggleElectives,
            children: [
              for (final entry in electiveGroups.entries)
                if (controller.filtered(entry.value).isNotEmpty) ...[
                  _SpecialtyLabel(text: entry.key),
                  for (final course in controller.filtered(entry.value))
                    _CourseListCard(controller: controller, course: course),
                ],
            ],
          ),
        );
      }

      if (sections.isEmpty) {
        return _EmptyState(filterActive: filterActive);
      }

      // Tap en el vacío de la lista → quita el resaltado.
      return GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: controller.clearHighlight,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
          children: sections,
        ),
      );
    });
  }
}

class _CycleSection extends StatelessWidget {
  const _CycleSection({
    required this.title,
    required this.summary,
    required this.expanded,
    required this.onToggle,
    required this.children,
  });

  final String title;
  final String summary;
  final bool expanded;
  final VoidCallback onToggle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onToggle,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
            child: Row(
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: MaterialTheme.textPrimary(brightness),
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '— $summary',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: MaterialTheme.textMuted(brightness),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Icon(
                  expanded ? Icons.expand_less : Icons.expand_more,
                  size: 20,
                  color: MaterialTheme.textMuted(brightness),
                ),
              ],
            ),
          ),
        ),
        if (expanded) ...children,
        const SizedBox(height: 6),
      ],
    );
  }
}

class _SpecialtyLabel extends StatelessWidget {
  const _SpecialtyLabel({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 6),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          color: MaterialTheme.textMuted(brightness),
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}

// ── Card de curso ──────────────────────────────────────────────────────────────
class _CourseListCard extends StatelessWidget {
  const _CourseListCard({required this.controller, required this.course});

  final MallaListController controller;
  final CourseNode course;

  IconData _statusIcon(CourseStatus status) {
    switch (status) {
      case CourseStatus.approved:
        return Icons.check_circle;
      case CourseStatus.current:
        return Icons.radio_button_checked;
      case CourseStatus.unlocked:
        return Icons.lock_open;
      case CourseStatus.locked:
        return Icons.lock_outline;
    }
  }

  String _categoryLabel(CourseCategory category) {
    switch (category) {
      case CourseCategory.eegg:
        return 'EEGG';
      case CourseCategory.common:
        return 'Común';
      case CourseCategory.faculty:
        return 'Facultad';
      case CourseCategory.elective:
        return 'Electivo';
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    // Obx propio por card: las lecturas reactivas (resaltado, estado,
    // simulación) deben ocurrir DENTRO del closure de un Obx para que GetX
    // registre la suscripción. Este build corre FUERA del closure del Obx de
    // _CourseList (get solo trackea lecturas síncronas dentro del builder),
    // así que leerlas aquí "a secas" dejaría el resaltado on-demand de HU19
    // sin repintar. Además mejora la granularidad: cada tap de resaltado
    // repinta las cards afectadas y no la lista entera.
    return Obx(() {
      final status = controller.statusOf(course.id);
      final role = controller.highlightRoleOf(course.id);
      final simChanged = controller.isSimulatedChange(course.id);

      final Color borderColor;
      final double borderWidth;
      final List<BoxShadow> shadows;
      switch (role) {
        case CourseHighlightRole.selected:
          borderColor = MaterialTheme.primaryColor;
          borderWidth = 2.5;
          shadows = [
            BoxShadow(
              color: MaterialTheme.primaryColor.withValues(alpha: 0.35),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ];
        case CourseHighlightRole.prerequisite:
          borderColor = MallaListPage._prereqColor;
          borderWidth = 2;
          shadows = const [];
        case CourseHighlightRole.unlocks:
          borderColor = MallaListPage._unlocksColor;
          borderWidth = 2;
          shadows = const [];
        case CourseHighlightRole.none:
        case CourseHighlightRole.dimmed:
          borderColor = MaterialTheme.borderColor(brightness);
          borderWidth = 1;
          shadows = const [];
      }

      return AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: role == CourseHighlightRole.dimmed ? 0.35 : 1,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: MaterialTheme.cardBg(brightness),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor, width: borderWidth),
            boxShadow: shadows,
          ),
          clipBehavior: Clip.antiAlias,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => controller.onCourseTap(course),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Franja izquierda con el color del estado.
                    Container(width: 5, color: status.color),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                _StatusBadge(
                                  status: status,
                                  icon: _statusIcon(status),
                                ),
                                _SmallChip(
                                  label: _categoryLabel(course.category),
                                  background: MaterialTheme.tagBg(brightness),
                                  foreground:
                                      MaterialTheme.textSecondary(brightness),
                                ),
                                if (simChanged)
                                  _SmallChip(
                                    label: 'SIMULADO',
                                    background: MaterialTheme.primaryColor
                                        .withValues(alpha: 0.15),
                                    foreground: brightness == Brightness.light
                                        ? MaterialTheme.primaryDark
                                        : const Color(0xFFFFB380),
                                  ),
                                if (role == CourseHighlightRole.prerequisite)
                                  _SmallChip(
                                    label: 'REQUISITO',
                                    background: MallaListPage._prereqColor
                                        .withValues(alpha: 0.15),
                                    foreground: MallaListPage._prereqColor,
                                  ),
                                if (role == CourseHighlightRole.unlocks)
                                  _SmallChip(
                                    label: 'DESBLOQUEA',
                                    background: MallaListPage._unlocksColor
                                        .withValues(alpha: 0.15),
                                    foreground: MallaListPage._unlocksColor,
                                  ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              course.name,
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
                              '${course.code} · ${course.credits} créditos'
                              '${course.isExternal ? ' · ${course.externalFaculty}' : ''}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: MaterialTheme.textMuted(brightness),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Botón explícito de detalles (abre el bottom sheet).
                    Center(
                      child: IconButton(
                        tooltip: 'Ver detalles',
                        icon: Icon(
                          Icons.info_outline,
                          size: 20,
                          color: MaterialTheme.textMuted(brightness),
                        ),
                        onPressed: () => _openDetails(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    });
  }

  void _openDetails(BuildContext context) {
    showCourseDetailSheet(
      context,
      course: course,
      statuses: Map<String, CourseStatus>.from(controller.displayedStatuses),
      courseById: controller.courseById,
      hasCompletedMandatoryCycles: controller.hasCompletedMandatoryCycles,
      // En modo normal el sheet es solo lectura: los estados solo cambian
      // dentro del modo simulación.
      onCycleStatus: controller.simulationMode.value
          ? () => controller.cycleSimStatus(course.id)
          : null,
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status, required this.icon});
  final CourseStatus status;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    // Color + ícono + texto SIEMPRE juntos (accesibilidad daltónica).
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: status.borderColor),
          const SizedBox(width: 4),
          Text(
            status.label,
            style: TextStyle(
              color: status.borderColor,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallChip extends StatelessWidget {
  const _SmallChip({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

// ── Panel inferior del modo simulación ─────────────────────────────────────────
class _SimulationPanel extends StatelessWidget {
  const _SimulationPanel({required this.controller});
  final MallaListController controller;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      decoration: BoxDecoration(
        color: MaterialTheme.cardBg(brightness),
        border: Border(
          top: BorderSide(color: colors.outline.withValues(alpha: 0.5)),
        ),
      ),
      child: Obx(() {
        final extra = controller.simExtraCredits;
        final signed = extra >= 0 ? '+$extra' : '$extra';
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$signed créditos simulados · '
              '${controller.simApprovedPercent}% proyectado',
              style: TextStyle(
                color: MaterialTheme.textPrimary(brightness),
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${controller.simUnlockedCount} cursos desbloqueados por la simulación',
              style: TextStyle(
                color: MaterialTheme.textMuted(brightness),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: controller.saving.value
                        ? null
                        : () => _confirmDiscard(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: MaterialTheme.textSecondary(brightness),
                      side: BorderSide(
                        color: MaterialTheme.borderColor(brightness),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Descartar',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: controller.saving.value
                        ? null
                        : controller.saveSimulation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: MaterialTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      controller.saving.value ? 'Guardando…' : 'Guardar',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      }),
    );
  }

  Future<void> _confirmDiscard(BuildContext context) async {
    if (!controller.simHasChanges) {
      controller.discardSimulation();
      return;
    }
    final brightness = Theme.of(context).brightness;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: MaterialTheme.sheetBg(brightness),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          '¿Descartar la simulación?',
          style: TextStyle(
            color: MaterialTheme.textPrimary(brightness),
            fontSize: 17,
            fontWeight: FontWeight.w900,
          ),
        ),
        content: Text(
          'Perderás los cambios de este escenario. Tu avance real no se ve '
          'afectado.',
          style: TextStyle(
            color: MaterialTheme.textSecondary(brightness),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Descartar',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) controller.discardSimulation();
  }
}

// ── Estados vacíos / de error ──────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.filterActive});
  final bool filterActive;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off,
              size: 40,
              color: MaterialTheme.textMuted(brightness),
            ),
            const SizedBox(height: 10),
            Text(
              filterActive
                  ? 'Ningún curso coincide con este filtro.'
                  : 'No hay cursos para mostrar.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: MaterialTheme.textDimmed(brightness),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.wifi_off,
              size: 40,
              color: MaterialTheme.textMuted(brightness),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: MaterialTheme.textDimmed(brightness),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text(
                'Reintentar',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: MaterialTheme.primaryColor,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
