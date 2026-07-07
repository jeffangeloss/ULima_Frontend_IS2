// lib/pages/teacher/teacher_home_page.dart
// HU18: pantalla principal del docente (profesor/JP). Lista sus asesorías con
// el contador de confirmados; el header muestra su rol; el "+" abre el
// formulario de asesoría extra.

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../components/skeleton.dart';
import '../../configs/themes.dart';
import '../../models/advising_models.dart';
import 'teacher_home_controller.dart';

class TeacherHomePage extends StatelessWidget {
  const TeacherHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<TeacherHomeController>();
    final brightness = Theme.brightnessOf(context);

    return Scaffold(
      backgroundColor: MaterialTheme.pageBg(brightness),
      appBar: AppBar(
        title: const Text('Mis asesorías'),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout),
            onPressed: controller.logout,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: controller.openCreate,
        backgroundColor: MaterialTheme.primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Asesoría extra'),
      ),
      body: RefreshIndicator(
        onRefresh: controller.loadSessions,
        color: MaterialTheme.primaryColor,
        child: Obx(() {
          final loading = controller.isLoading.value;
          final sessions = controller.sessions;

          return CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _Header(controller: controller, brightness: brightness)),
              if (loading && sessions.isEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: SkeletonCardList(count: 3, showAvatar: false),
                  ),
                )
              else if (controller.loadError.value != null && sessions.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _EmptyState(
                    icon: Icons.wifi_off,
                    message: controller.loadError.value!,
                    brightness: brightness,
                  ),
                )
              else if (sessions.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _EmptyState(
                    icon: Icons.event_available_outlined,
                    message: 'Aún no tienes asesorías. Pulsa "Asesoría extra" para crear una.',
                    brightness: brightness,
                  ),
                )
              else
                SliverList.builder(
                  itemCount: sessions.length,
                  itemBuilder: (_, i) => Padding(
                    padding: EdgeInsets.fromLTRB(16, i == 0 ? 4 : 6, 16, 6),
                    child: _SessionCard(
                      session: sessions[i],
                      brightness: brightness,
                      onTap: () => controller.openAttendees(sessions[i]),
                      onDelete: sessions[i].esExtra
                          ? () => _confirmDelete(context, controller, sessions[i])
                          : null,
                    ),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 88)),
            ],
          );
        }),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    TeacherHomeController controller,
    AdvisingSession session,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar asesoría'),
        content: Text('¿Eliminar la asesoría extra del ${session.fecha ?? session.dia}?'),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok == true) await controller.deleteSession(session);
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.controller, required this.brightness});
  final TeacherHomeController controller;
  final Brightness brightness;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: MaterialTheme.primaryColor.withValues(alpha: 0.15),
            child: const Icon(Icons.school, color: MaterialTheme.primaryColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  controller.displayName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: MaterialTheme.textPrimary(brightness),
                  ),
                ),
                const SizedBox(height: 2),
                _RolePill(label: controller.roleLabel),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RolePill extends StatelessWidget {
  const _RolePill({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: MaterialTheme.primaryColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: MaterialTheme.primaryColor,
        ),
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({
    required this.session,
    required this.brightness,
    required this.onTap,
    required this.onDelete,
  });

  final AdvisingSession session;
  final Brightness brightness;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  static const _modalityLabel = {
    'classroom': 'Presencial',
    'virtual': 'Virtual',
    'hybrid': 'Híbrida',
  };

  @override
  Widget build(BuildContext context) {
    final cuandoExtra = session.esExtra && session.fecha != null
        ? '${session.dia} · ${session.fecha}'
        : session.dia;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: MaterialTheme.cardBg(brightness),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: MaterialTheme.borderColor(brightness)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    session.courseName,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: MaterialTheme.textPrimary(brightness),
                    ),
                  ),
                ),
                if (session.esExtra) const _Badge(text: 'Extra', color: MaterialTheme.primaryColor),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.schedule, size: 15, color: MaterialTheme.textMuted(brightness)),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    '$cuandoExtra · ${session.inicio}–${session.fin}',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, color: MaterialTheme.textSecondary(brightness)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.place_outlined, size: 15, color: MaterialTheme.textMuted(brightness)),
                const SizedBox(width: 4),
                Text(
                  _modalityLabel[session.modality] ?? session.modality,
                  style: TextStyle(fontSize: 13, color: MaterialTheme.textSecondary(brightness)),
                ),
                const SizedBox(width: 12),
                _Badge(text: session.rol, color: MaterialTheme.textMuted(brightness)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.groups_outlined, size: 16, color: MaterialTheme.primaryColor),
                const SizedBox(width: 4),
                Text(
                  session.cupo != null
                      ? '${session.asistentes} / ${session.cupo} confirmados'
                      : '${session.asistentes} confirmados',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: MaterialTheme.primaryColor,
                  ),
                ),
                const Spacer(),
                if (onDelete != null)
                  IconButton(
                    tooltip: 'Eliminar',
                    visualDensity: VisualDensity.compact,
                    icon: Icon(Icons.delete_outline, size: 20, color: MaterialTheme.textMuted(brightness)),
                    onPressed: onDelete,
                  ),
                Icon(Icons.chevron_right, color: MaterialTheme.textMuted(brightness)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.message, required this.brightness});
  final IconData icon;
  final String message;
  final Brightness brightness;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: MaterialTheme.textMuted(brightness)),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: MaterialTheme.textSecondary(brightness)),
          ),
        ],
      ),
    );
  }
}
