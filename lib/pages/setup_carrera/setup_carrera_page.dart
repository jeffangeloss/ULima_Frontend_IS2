// lib/pages/setup_carrera/setup_carrera_page.dart
// Wizard de configuración inicial (primer login).

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../configs/themes.dart';
import '../../services/auth_service.dart';
import 'setup_carrera_controller.dart';

class SetupCarreraPage extends StatelessWidget {
  const SetupCarreraPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SetupCarreraController());
    final user = AuthService.to.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F8),
      body: SafeArea(
        child: Column(
          children: [
            _WizardHeader(name: user?.firstName ?? 'Alumno'),
            Expanded(
              child: Obx(() {
                switch (controller.step.value) {
                  case SetupStep.carrera:
                    return _CarreraStep(controller: controller);
                  case SetupStep.decision:
                    return _DecisionStep(controller: controller);
                  case SetupStep.seleccion:
                    return _SeleccionStep(controller: controller);
                }
              }),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _WizardHeader extends StatelessWidget {
  const _WizardHeader({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
      decoration: const BoxDecoration(
        color: MaterialTheme.primaryColor,
        boxShadow: [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.sparkles, color: Colors.white, size: 22),
              const SizedBox(width: 10),
              Text(
                'Hola, $name',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Antes de empezar, cuéntanos qué estás estudiando.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Paso 1: Carrera ───────────────────────────────────────────────────────────

class _CarreraStep extends StatelessWidget {
  const _CarreraStep({required this.controller});
  final SetupCarreraController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _SectionLabel(
                  icon: LucideIcons.graduationCap,
                  title: 'Tu carrera',
                  subtitle:
                      'Se asigna automáticamente según tu cuenta ULima.',
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE5E5E5)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFE8DC),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          LucideIcons.graduationCap,
                          color: MaterialTheme.primaryDark,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Carrera asignada',
                              style: TextStyle(
                                color: Color(0xFF777777),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Obx(
                              () => Text(
                                controller.selectedCarreraName,
                                style: const TextStyle(
                                  color: Color(0xFF1A1A1A),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF2F2F2),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.lock_outline,
                              size: 14,
                              color: Color(0xFF777777),
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Fija',
                              style: TextStyle(
                                color: Color(0xFF777777),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        _BottomButton(
          label: 'Continuar',
          icon: LucideIcons.arrowRight,
          onPressed: controller.goToDecision,
        ),
      ],
    );
  }
}

// ── Paso 2: Decisión de especialidad ─────────────────────────────────────────

class _DecisionStep extends StatelessWidget {
  const _DecisionStep({required this.controller});
  final SetupCarreraController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _SectionLabel(
                  icon: LucideIcons.bookmark,
                  title: 'Especialización',
                  subtitle:
                      'Opcional. Puedes elegirla ahora, explorarla o decidirlo luego desde tu perfil.',
                ),
                const SizedBox(height: 20),
                _DecisionCard(
                  icon: LucideIcons.check,
                  title: 'Sí, quiero elegir ahora',
                  subtitle: 'Seleccionas tu mención principal y tus intereses.',
                  onTap: controller.chooseSi,
                ),
                const SizedBox(height: 10),
                _DecisionCard(
                  icon: LucideIcons.clock,
                  title: 'Todavía no estoy seguro',
                  subtitle: 'Continúas sin especialización. Puedes elegirla luego.',
                  onTap: controller.chooseNoSe,
                  isSecondary: true,
                ),
                const SizedBox(height: 10),
                _DecisionCard(
                  icon: LucideIcons.search,
                  title: 'Quiero explorar primero',
                  subtitle: 'Ver de qué trata cada mención antes de decidir.',
                  onTap: controller.chooseExplorar,
                  isSecondary: true,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DecisionCard extends StatelessWidget {
  const _DecisionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isSecondary = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isSecondary;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSecondary ? Colors.white : const Color(0xFFFFF1EA),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSecondary
                ? const Color(0xFFE5E5E5)
                : MaterialTheme.primaryColor,
            width: isSecondary ? 1 : 1.6,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSecondary
                    ? const Color(0xFFF2F2F2)
                    : const Color(0xFFFFE8DC),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Icon(
                icon,
                size: 20,
                color: isSecondary
                    ? const Color(0xFF777777)
                    : MaterialTheme.primaryDark,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isSecondary
                          ? const Color(0xFF1A1A1A)
                          : MaterialTheme.primaryDark,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF777777),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              LucideIcons.chevronRight,
              size: 18,
              color: isSecondary
                  ? const Color(0xFFBBBBBB)
                  : MaterialTheme.primaryColor,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Paso 3: Selección de especialidades ───────────────────────────────────────

class _SeleccionStep extends StatelessWidget {
  const _SeleccionStep({required this.controller});
  final SetupCarreraController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final opciones = controller.especialidadesDisponibles;
      final isExplore =
          controller.decision.value == SpecialtyDecision.explorar;

      return Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _SectionLabel(
                    icon: LucideIcons.bookmark,
                    title: isExplore
                        ? 'Explorando especializaciones'
                        : 'Especialización principal',
                    subtitle: isExplore
                        ? 'Cuando te decidas, toca una para elegirla. Puedes saltar por ahora.'
                        : 'Elige una mención como tu diploma principal.',
                  ),
                  const SizedBox(height: 16),
                  // Sección principal (radio)
                  ...opciones.map((esp) {
                    final id = int.tryParse(esp['id']?.toString() ?? '') ?? 0;
                    final name = esp['name'] as String;
                    final desc = esp['description'] as String? ?? '';
                    final isPrincipal = controller.selectedPrincipal.value == id;
                    final isInteres = controller.selectedInteres.contains(id);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _EspecialidadCard(
                        name: name,
                        desc: desc,
                        isPrincipal: isPrincipal,
                        isInteres: isInteres,
                        onTapPrincipal: () => controller.setPrincipal(id),
                        onTapInteres: () => controller.toggleInteres(id),
                      ),
                    );
                  }),
                  const SizedBox(height: 8),
                  _ErrorBanner(controller: controller),
                ],
              ),
            ),
          ),
          Obx(
            () => _BottomButton(
              label: (controller.selectedPrincipal.value == null &&
                      controller.selectedInteres.isEmpty)
                  ? 'Saltar por ahora'
                  : 'Finalizar configuración',
              icon: LucideIcons.arrowRight,
              onPressed: controller.saving.value ? null : controller.finish,
              loading: controller.saving.value,
            ),
          ),
        ],
      );
    });
  }
}

class _EspecialidadCard extends StatefulWidget {
  const _EspecialidadCard({
    required this.name,
    required this.desc,
    required this.isPrincipal,
    required this.isInteres,
    required this.onTapPrincipal,
    required this.onTapInteres,
  });

  final String name;
  final String desc;
  final bool isPrincipal;
  final bool isInteres;
  final VoidCallback onTapPrincipal;
  final VoidCallback onTapInteres;

  @override
  State<_EspecialidadCard> createState() => _EspecialidadCardState();
}

class _EspecialidadCardState extends State<_EspecialidadCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.isPrincipal || widget.isInteres;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      decoration: BoxDecoration(
        color: widget.isPrincipal
            ? const Color(0xFFFFF1EA)
            : widget.isInteres
                ? const Color(0xFFF5FAFF)
                : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: widget.isPrincipal
              ? MaterialTheme.primaryColor
              : widget.isInteres
                  ? const Color(0xFF0EA5E9)
                  : const Color(0xFFE5E5E5),
          width: active ? 1.6 : 1,
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.name,
                        style: TextStyle(
                          color: widget.isPrincipal
                              ? MaterialTheme.primaryDark
                              : const Color(0xFF1A1A1A),
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (widget.isPrincipal)
                        const Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: Text(
                            'Principal',
                            style: TextStyle(
                              color: MaterialTheme.primaryColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        )
                      else if (widget.isInteres)
                        const Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: Text(
                            'Me interesa',
                            style: TextStyle(
                              color: Color(0xFF0EA5E9),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() => _expanded = !_expanded),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Icon(
                      _expanded
                          ? LucideIcons.chevronUp
                          : LucideIcons.chevronDown,
                      size: 16,
                      color: const Color(0xFFAAAAAA),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_expanded && widget.desc.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: Text(
                widget.desc,
                style: const TextStyle(
                  color: Color(0xFF666666),
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
            ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFF0F0F0)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: _ActionChip(
                    label: widget.isPrincipal ? 'Quitar principal' : 'Principal',
                    icon: widget.isPrincipal
                        ? LucideIcons.x
                        : LucideIcons.star,
                    active: widget.isPrincipal,
                    color: MaterialTheme.primaryColor,
                    onTap: widget.onTapPrincipal,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ActionChip(
                    label: widget.isInteres ? 'Quitar interés' : 'Me interesa',
                    icon: widget.isInteres
                        ? LucideIcons.x
                        : LucideIcons.heart,
                    active: widget.isInteres,
                    color: const Color(0xFF0EA5E9),
                    onTap: widget.isPrincipal ? null : widget.onTapInteres,
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

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.label,
    required this.icon,
    required this.active,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool active;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: disabled
              ? const Color(0xFFF5F5F5)
              : active
                  ? color.withValues(alpha: 0.12)
                  : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: disabled
                ? const Color(0xFFE0E0E0)
                : active
                    ? color.withValues(alpha: 0.5)
                    : const Color(0xFFE0E0E0),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 13,
              color: disabled
                  ? const Color(0xFFCCCCCC)
                  : active
                      ? color
                      : const Color(0xFF888888),
            ),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: disabled
                      ? const Color(0xFFCCCCCC)
                      : active
                          ? color
                          : const Color(0xFF555555),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Compartidos ───────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: const Color(0xFFFFE8DC),
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Icon(icon, color: MaterialTheme.primaryDark, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF1A1A1A),
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Color(0xFF6B6B6B),
                  fontSize: 12,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.controller});
  final SetupCarreraController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final msg = controller.errorMessage.value;
      if (msg == null) return const SizedBox.shrink();
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF1EC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFFFCFBF)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.error_outline,
              size: 16,
              color: MaterialTheme.primaryDark,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                msg,
                style: const TextStyle(
                  color: MaterialTheme.primaryDark,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _BottomButton extends StatelessWidget {
  const _BottomButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.loading = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: SizedBox(
          height: 54,
          child: ElevatedButton.icon(
            onPressed: onPressed,
            icon: loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.2,
                    ),
                  )
                : Icon(icon, size: 20),
            label: Text(
              label,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: MaterialTheme.primaryColor,
              foregroundColor: Colors.white,
              disabledBackgroundColor:
                  MaterialTheme.primaryColor.withValues(alpha: 0.6),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
