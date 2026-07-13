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
import '../../services/evaluations_service.dart';
import 'malla_list_controller.dart';
import 'widgets/course_detail_sheet.dart';

class MallaListPage extends GetView<MallaListController> {
  const MallaListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return Scaffold(
      backgroundColor: MaterialTheme.pageBg(brightness),
      body: Stack(
        children: [
          Column(
            children: [
              Obx(
                () => controller.simulationMode.value
                    ? const _SimulationBanner()
                    : const SizedBox.shrink(),
              ),
              _ProgressHeader(controller: controller),
              Obx(
                () => controller.filter.value == MallaListFilter.todos
                    ? _CycleStepper(controller: controller)
                    : _ActiveFilterBar(controller: controller),
              ),
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
                  return controller.filter.value == MallaListFilter.todos
                      ? _FocusedCycle(controller: controller)
                      : _FilteredList(controller: controller);
                }),
              ),
              Obx(
                () => controller.simulationMode.value
                    ? _SimulationPanel(controller: controller)
                    : const SizedBox.shrink(),
              ),
            ],
          ),
          Obx(() {
            final hidden = controller.loading.value ||
                controller.error.value != null ||
                controller.simulationMode.value;
            if (hidden) return const SizedBox.shrink();
            // Solo el ícono (matraz), con latido para llamar la atención. Va en
            // la esquina inferior derecha; la burbuja del chatbot queda a la izq.
            return Positioned(
              right: 18,
              bottom: 20,
              child: _PulsingSimFab(onPressed: controller.enterSimulation),
            );
          }),
        ],
      ),
    );
  }
}

// ── FAB "Simular mi avance" (solo ícono, con latido) ───────────────────────────
/// Botón compacto: solo el matraz, con un latido suave + halo que crece y se
/// desvanece para llamar la atención. Respeta el "reduce motion" del sistema.
class _PulsingSimFab extends StatefulWidget {
  const _PulsingSimFab({required this.onPressed});
  final VoidCallback onPressed;

  @override
  State<_PulsingSimFab> createState() => _PulsingSimFabState();
}

class _PulsingSimFabState extends State<_PulsingSimFab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))
      ..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fab = FloatingActionButton(
      heroTag: 'sim_fab',
      onPressed: widget.onPressed,
      backgroundColor: MaterialTheme.primaryColor,
      foregroundColor: Colors.white,
      tooltip: 'Simular mi avance',
      child: const Icon(Icons.science_outlined),
    );

    // Reduce motion: FAB estático, sin latido.
    if (MediaQuery.of(context).disableAnimations) return fab;

    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final t = _c.value; // 0..1
        final beat = 1.0 + 0.06 * (0.5 - (t - 0.5).abs()) * 2;
        return SizedBox(
          width: 56,
          height: 56,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              _ring(t),
              Transform.scale(scale: beat, child: child),
            ],
          ),
        );
      },
      child: fab,
    );
  }

  Widget _ring(double t) {
    final scale = 1.0 + t * 0.6;
    final opacity = ((1.0 - t) * 0.45).clamp(0.0, 1.0);
    return IgnorePointer(
      child: Opacity(
        opacity: opacity,
        child: Transform.scale(
          scale: scale,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: MaterialTheme.primaryColor, width: 3),
            ),
          ),
        ),
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
        // Compacto para dar el mayor alto posible a la lista (Parte 5).
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
        decoration: BoxDecoration(
          color: MaterialTheme.cardBg(brightness),
          border: Border(
            bottom: BorderSide(color: colors.outline.withValues(alpha: 0.5)),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Malla curricular',
                    style: TextStyle(
                      color: MaterialTheme.textPrimary(brightness),
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                // Filtros movidos a un botón que abre un bottom sheet (antes
                // eran 5 chips en 2 líneas). Muestra el filtro activo.
                _FiltersButton(controller: controller),
                const SizedBox(width: 8),
                // TT07: acceso de solo lectura a la vista mapa (clásica).
                // Deshabilitado durante TODO el modo simulación: el mapa solo
                // muestra estado persistido y lo que se ve en pantalla durante
                // una simulación aún no lo está.
                _MapViewButton(enabled: !sim),
              ],
            ),
            const SizedBox(height: 7),
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
            const SizedBox(height: 5),
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

// ── Botón "Vista mapa" (TT07) ──────────────────────────────────────────────────
// Abre la malla clásica como vista mapa de SOLO LECTURA (/malla-clasica).
// En modo simulación queda deshabilitado y, al tocarlo, explica por qué:
// el mapa solo muestra estado persistido y la simulación en curso no lo está.
class _MapViewButton extends StatelessWidget {
  const _MapViewButton({required this.enabled});
  final bool enabled;

  void _onTap() {
    if (!enabled) {
      Get.snackbar(
        'Vista mapa no disponible',
        'Guarda o descarta la simulación para ver el mapa',
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(12),
      );
      return;
    }
    Get.toNamed<void>('/malla-clasica');
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final fg = enabled
        ? MaterialTheme.textSecondary(brightness)
        : MaterialTheme.textMuted(brightness);
    return Semantics(
      button: true,
      enabled: enabled,
      child: Material(
        color: MaterialTheme.tagBg(brightness),
        borderRadius: BorderRadius.circular(99),
        child: InkWell(
          borderRadius: BorderRadius.circular(99),
          onTap: _onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(99),
              border: Border.all(color: MaterialTheme.borderColor(brightness)),
            ),
            child: Opacity(
              opacity: enabled ? 1 : 0.5,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.map_outlined, size: 15, color: fg),
                  const SizedBox(width: 6),
                  Text(
                    'Vista mapa',
                    style: TextStyle(
                      color: fg,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Botón de filtros (abre bottom sheet) ───────────────────────────────────────
class _FiltersButton extends StatelessWidget {
  const _FiltersButton({required this.controller});
  final MallaListController controller;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Obx(() {
      final active = controller.filter.value != MallaListFilter.todos;
      final fg = active
          ? Colors.white
          : MaterialTheme.textSecondary(brightness);
      return Material(
        color: active
            ? MaterialTheme.primaryColor
            : MaterialTheme.tagBg(brightness),
        borderRadius: BorderRadius.circular(99),
        child: InkWell(
          borderRadius: BorderRadius.circular(99),
          onTap: () => _openFilterSheet(context, controller),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(99),
              border: Border.all(
                color: active
                    ? Colors.transparent
                    : MaterialTheme.borderColor(brightness),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.tune, size: 15, color: fg),
                const SizedBox(width: 6),
                Text(
                  active ? controller.filter.value.label : 'Filtros',
                  style: TextStyle(
                    color: fg,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

void _openFilterSheet(BuildContext context, MallaListController controller) {
  final brightness = Theme.of(context).brightness;
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: MaterialTheme.sheetBg(brightness),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(8, 12, 8, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: Text(
                'Filtrar cursos',
                style: TextStyle(
                  color: MaterialTheme.textPrimary(brightness),
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Obx(() {
              final active = controller.filter.value;
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final f in MallaListFilter.values)
                    _FilterOptionTile(
                      label: f.label,
                      selected: f == active,
                      onTap: () {
                        controller.setFilter(f);
                        Navigator.of(ctx).pop();
                      },
                    ),
                ],
              );
            }),
          ],
        ),
      ),
    ),
  );
}

class _FilterOptionTile extends StatelessWidget {
  const _FilterOptionTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return ListTile(
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      leading: Icon(
        selected ? Icons.radio_button_checked : Icons.radio_button_off,
        color: selected
            ? MaterialTheme.primaryColor
            : MaterialTheme.textMuted(brightness),
      ),
      title: Text(
        label,
        style: TextStyle(
          color: MaterialTheme.textPrimary(brightness),
          fontSize: 14,
          fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
        ),
      ),
    );
  }
}

// ── Barra de filtro activo (reemplaza al rail cuando hay filtro) ────────────────
class _ActiveFilterBar extends StatelessWidget {
  const _ActiveFilterBar({required this.controller});
  final MallaListController controller;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Obx(() {
      final f = controller.filter.value;
      final count = controller.filteredAll.length;
      return Container(
        width: double.infinity,
        color: MaterialTheme.cardBg(brightness),
        padding: const EdgeInsets.fromLTRB(16, 2, 12, 10),
        child: Row(
          children: [
            Expanded(
              child: Text(
                '${f.label} · $count ${count == 1 ? 'curso' : 'cursos'}',
                style: TextStyle(
                  color: MaterialTheme.textSecondary(brightness),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            InkWell(
              borderRadius: BorderRadius.circular(99),
              onTap: () => controller.setFilter(MallaListFilter.todos),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.close, size: 14,
                        color: MaterialTheme.textMuted(brightness)),
                    const SizedBox(width: 4),
                    Text(
                      'Quitar filtro',
                      style: TextStyle(
                        color: MaterialTheme.textMuted(brightness),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}

// ── Selector de ciclo: stepper "◀ Ciclo N ▶" + popup ────────────────────────────
// Reemplaza al rail scrollable (mismo patrón que el header de días del horario).
// Las flechas mueven al ciclo anterior/siguiente; tocar el centro abre un popup
// con la lista vertical de ciclos y sus cursos para saltar rápido.
class _CycleStepper extends StatelessWidget {
  const _CycleStepper({required this.controller});
  final MallaListController controller;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: MaterialTheme.cardBg(brightness),
        border: Border(
          bottom: BorderSide(color: colors.outline.withValues(alpha: 0.4)),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: Obx(() {
        final key = controller.focusedKey.value;
        final canPrev = controller.canFocusPrev;
        final canNext = controller.canFocusNext;
        return Row(
          children: [
            _StepArrow(
              icon: Icons.chevron_left,
              enabled: canPrev,
              onTap: controller.focusPrev,
            ),
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _openCyclePicker(context, controller),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            controller.labelForKey(key),
                            style: TextStyle(
                              color: MaterialTheme.textPrimary(brightness),
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.unfold_more,
                            size: 16,
                            color: MaterialTheme.textMuted(brightness),
                          ),
                        ],
                      ),
                      Text(
                        controller.summaryForKey(key),
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
            ),
            _StepArrow(
              icon: Icons.chevron_right,
              enabled: canNext,
              onTap: controller.focusNext,
            ),
          ],
        );
      }),
    );
  }
}

class _StepArrow extends StatelessWidget {
  const _StepArrow({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return IconButton(
      onPressed: enabled ? onTap : null,
      icon: Icon(icon, size: 26),
      color: colors.primary,
      disabledColor: colors.outline.withValues(alpha: 0.5),
      visualDensity: VisualDensity.compact,
    );
  }
}

// Popup: lista vertical de ciclos (y sus cursos) para saltar rápido de ciclo.
void _openCyclePicker(BuildContext context, MallaListController controller) {
  final brightness = Theme.of(context).brightness;
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: MaterialTheme.sheetBg(brightness),
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      // Altura acotada (hasta ~72% de pantalla) con scroll vertical interno.
      final maxH = MediaQuery.of(ctx).size.height * 0.72;
      return SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxH),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: MaterialTheme.borderColor(brightness),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                child: Row(
                  children: [
                    Text(
                      'Ir a un ciclo',
                      style: TextStyle(
                        color: MaterialTheme.textPrimary(brightness),
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: Obx(() {
                  final keys = controller.railKeys;
                  final focused = controller.focusedKey.value;
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    itemCount: keys.length,
                    itemBuilder: (_, i) => _CyclePickerSection(
                      controller: controller,
                      cycleKey: keys[i],
                      selected: keys[i] == focused,
                      onPick: () {
                        controller.focus(keys[i]);
                        Navigator.of(ctx).pop();
                      },
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _CyclePickerSection extends StatelessWidget {
  const _CyclePickerSection({
    required this.controller,
    required this.cycleKey,
    required this.selected,
    required this.onPick,
  });

  final MallaListController controller;
  final int cycleKey;
  final bool selected;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final complete = cycleKey == MallaListController.electivesRailKey
        ? controller.isElectivesComplete
        : controller.isLevelComplete(cycleKey);

    // Fila simple por ciclo: solo para saltar rápido; sin listar los cursos.
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: selected
            ? MaterialTheme.primaryColor.withValues(alpha: 0.10)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected
              ? MaterialTheme.primaryColor.withValues(alpha: 0.5)
              : MaterialTheme.borderColor(brightness),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onPick,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              if (complete)
                const Padding(
                  padding: EdgeInsets.only(right: 6),
                  child: Icon(Icons.check_circle,
                      size: 16, color: Color(0xFF16A34A)),
                ),
              Text(
                controller.labelForKey(cycleKey),
                style: TextStyle(
                  color: MaterialTheme.textPrimary(brightness),
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '— ${controller.summaryForKey(cycleKey)}',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: MaterialTheme.textMuted(brightness),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (selected)
                Icon(Icons.my_location,
                    size: 16, color: MaterialTheme.primaryColor),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Ciclo enfocado (filtro = Todos) ─────────────────────────────────────────────
// Muestra un único ciclo (el seleccionado en el rail) o la pestaña Electivos,
// sin acordeones: la navegación por ciclo la da el rail de arriba.
class _FocusedCycle extends StatelessWidget {
  const _FocusedCycle({required this.controller});
  final MallaListController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final key = controller.focusedKey.value;
      final isElectives = key == MallaListController.electivesRailKey;

      final children = <Widget>[];

      if (isElectives) {
        for (final entry in controller.electiveGroups.entries) {
          children.add(_SpecialtyLabel(text: entry.key));
          for (final course in entry.value) {
            children
                .add(_CourseListCard(controller: controller, course: course));
          }
        }
      } else {
        for (final course in controller.mandatoryForLevel(key)) {
          children.add(_CourseListCard(controller: controller, course: course));
        }
      }

      if (children.isEmpty) {
        return const _EmptyState(filterActive: false);
      }

      // El ciclo y su resumen ya los muestra el stepper de arriba.
      // (La física clamped es global — ver AppScrollBehavior en main.dart.)
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 96),
        children: children,
      );
    });
  }
}

// ── Resultados de filtro (filtro activo) ────────────────────────────────────────
// Lista plana a través de todos los ciclos, con una etiqueta por ciclo para no
// perder el contexto de dónde cae cada curso.
class _FilteredList extends StatelessWidget {
  const _FilteredList({required this.controller});
  final MallaListController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final children = <Widget>[];

      for (final level in controller.mandatoryLevels) {
        final visible = controller.filtered(controller.mandatoryForLevel(level));
        if (visible.isEmpty) continue;
        children.add(_SpecialtyLabel(text: 'Ciclo $level'));
        for (final course in visible) {
          children.add(_CourseListCard(controller: controller, course: course));
        }
      }

      for (final entry in controller.electiveGroups.entries) {
        final visible = controller.filtered(entry.value);
        if (visible.isEmpty) continue;
        children.add(_SpecialtyLabel(text: 'Electivos · ${entry.key}'));
        for (final course in visible) {
          children.add(_CourseListCard(controller: controller, course: course));
        }
      }

      if (children.isEmpty) {
        return const _EmptyState(filterActive: true);
      }

      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
        children: children,
      );
    });
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
    // Obx propio por card: las lecturas reactivas (estado, simulación, versión
    // de sílabos) deben ocurrir DENTRO del closure de un Obx para que GetX
    // registre la suscripción y la card se repinte al cambiar.
    return Obx(() {
      final status = controller.statusOf(course.id);
      final simChanged = controller.isSimulatedChange(course.id);
      // Depende de la precarga de sílabos (no reactiva): al leer la versión, la
      // card se repinta cuando los datos llegan y aparece el ícono de sílabo.
      controller.syllabusVersion.value;
      final silaboUrl = EvaluationSyllabusService().getSilaboUrl(course.id);
      // En modo simulación la card es tappable (cicla el estado); en modo normal
      // no reacciona al tap (el detalle va por ⓘ y el sílabo por el ícono PDF).
      final simulating = controller.simulationMode.value;

      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: MaterialTheme.cardBg(brightness),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: MaterialTheme.borderColor(brightness),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: simulating ? () => controller.onCourseTap(course) : null,
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
                    // Acceso directo al sílabo (solo si el curso tiene uno):
                    // antes estaba enterrado dentro del bottom sheet de detalle.
                    if (silaboUrl != null)
                      Center(
                        child: IconButton(
                          tooltip: 'Ver sílabo',
                          icon: Icon(
                            Icons.picture_as_pdf_outlined,
                            size: 20,
                            color: brightness == Brightness.light
                                ? const Color(0xFF0369A1)
                                : const Color(0xFF38BDF8),
                          ),
                          onPressed: () => Get.toNamed<void>(
                            '/silabo',
                            arguments: {
                              'url': silaboUrl,
                              'titulo': course.name,
                            },
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
