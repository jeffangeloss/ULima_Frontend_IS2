import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../configs/themes.dart';
import '../../../models/curso_delegado_model.dart';
import 'delegado_cursos_controller.dart';

class DelegadoCursosPage extends StatelessWidget {
  DelegadoCursosPage({super.key});

  final DelegadoCursosController controller = Get.put(
    DelegadoCursosController(),
  );

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return Container(
      color: MaterialTheme.pageBg(brightness),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(brightness: brightness),
          Expanded(
            child: Obx(() {
              if (controller.loading.value) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: MaterialTheme.primaryColor,
                  ),
                );
              }

              if (controller.cursos.isEmpty) {
                return const _EmptyState();
              }

              return RefreshIndicator(
                color: MaterialTheme.primaryColor,
                onRefresh: controller.fetchCursos,
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  itemCount: controller.cursos.length,
                  itemBuilder: (context, index) {
                    final curso = controller.cursos[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _CursoDelegadoCard(
                        curso: curso,
                        onTap: () => controller.openCurso(curso),
                      ),
                    );
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.brightness});

  final Brightness brightness;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        color: brightness == Brightness.light
            ? const Color(0xFFFFF2EC)
            : const Color(0xFF262630),
        border: Border(
          bottom: BorderSide(color: MaterialTheme.borderColor(brightness)),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: MaterialTheme.primaryColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              LucideIcons.shieldCheck,
              color: MaterialTheme.primaryDark,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Delegado de Aula',
                  style: TextStyle(
                    color: MaterialTheme.textPrimary(brightness),
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Gestiona tus cursos asignados',
                  style: TextStyle(
                    color: MaterialTheme.textSecondary(brightness),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
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

class _CursoDelegadoCard extends StatelessWidget {
  const _CursoDelegadoCard({required this.curso, required this.onTap});

  final CursoDelegado curso;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: MaterialTheme.cardBg(brightness),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: MaterialTheme.borderColor(brightness)),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: MaterialTheme.espPrincipalBg(brightness),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                LucideIcons.bookOpen,
                color: MaterialTheme.primaryDark,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    curso.codigoSeccion,
                    style: const TextStyle(
                      color: MaterialTheme.primaryDark,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    curso.nombreCurso,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: MaterialTheme.textPrimary(brightness),
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${curso.alumnosMatriculados} alumnos matriculados',
                    style: TextStyle(
                      color: MaterialTheme.textMuted(brightness),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: MaterialTheme.tagBg(brightness),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    curso.rolTexto,
                    style: TextStyle(
                      color: MaterialTheme.textSecondary(brightness),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Icon(
                  LucideIcons.chevronRight,
                  color: MaterialTheme.textMuted(brightness),
                  size: 18,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Text(
          'No tienes cursos asignados como delegado.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: MaterialTheme.textMuted(brightness),
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
