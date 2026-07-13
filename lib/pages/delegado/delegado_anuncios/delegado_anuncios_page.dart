import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../components/descripcion_cursos/anuncio_card.dart';
import '../../../components/error_retry.dart';
import '../../../components/skeleton.dart';
import '../../../configs/themes.dart';
import '../../../models/anuncio_model.dart';
import '../../../models/curso_delegado_model.dart';
import '../../../models/estadisticas_seccion_model.dart';
import 'delegado_anuncios_controller.dart';

class DelegadoAnunciosPage extends StatefulWidget {
  const DelegadoAnunciosPage({super.key, required this.curso});

  final CursoDelegado curso;

  @override
  State<DelegadoAnunciosPage> createState() => _DelegadoAnunciosPageState();
}

class _DelegadoAnunciosPageState extends State<DelegadoAnunciosPage> {
  late final String _tag;
  late final DelegadoAnunciosController controller;

  @override
  void initState() {
    super.initState();
    _tag = widget.curso.idSeccion;
    controller = Get.put(
      DelegadoAnunciosController(curso: widget.curso),
      tag: _tag,
    );
  }

  @override
  void dispose() {
    Get.delete<DelegadoAnunciosController>(tag: _tag);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.brightnessOf(context);

    return Scaffold(
      backgroundColor: MaterialTheme.pageBg(brightness),
      appBar: AppBar(title: const Text('Gestión de Sección')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: controller.openCreate,
        backgroundColor: MaterialTheme.primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(LucideIcons.plus),
        label: const Text('Nuevo anuncio'),
      ),
      body: RefreshIndicator(
        color: MaterialTheme.primaryColor,
        onRefresh: controller.refreshAll,
        child: Obx(
          () => CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: _CourseHeader(
                  curso: widget.curso,
                  brightness: brightness,
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
                  child: _StatisticsSection(controller: controller),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                  child: _SectionTitle(
                    title: 'Historial de anuncios',
                    subtitle: 'Publicaciones enviadas a esta sección',
                    brightness: brightness,
                    onRefresh: controller.fetchAnnouncements,
                  ),
                ),
              ),
              if (controller.loadingAnnouncements.value &&
                  controller.anunciosPublicados.isEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: SkeletonCardList(count: 3, showAvatar: false),
                  ),
                )
              else if (controller.anunciosPublicados.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _EmptyState(
                    icon: LucideIcons.megaphone,
                    message: 'Aún no has publicado anuncios para esta sección.',
                    brightness: brightness,
                  ),
                )
              else
                SliverList.builder(
                  itemCount: controller.anunciosPublicados.length,
                  itemBuilder: (_, index) => Padding(
                    padding: EdgeInsets.fromLTRB(16, index == 0 ? 0 : 6, 16, 6),
                    child: _AnnouncementCard(
                      anuncio: controller.anunciosPublicados[index],
                      onEdit: () => controller.openEdit(
                        controller.anunciosPublicados[index],
                      ),
                      onDelete: () => _confirmDelete(
                        context,
                        controller.anunciosPublicados[index],
                      ),
                    ),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 92)),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Anuncio anuncio) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar anuncio'),
        content: Text('¿Eliminar "${anuncio.titulo}" del historial?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (ok == true) await controller.deleteAnnouncement(anuncio);
  }
}

class _CourseHeader extends StatelessWidget {
  const _CourseHeader({required this.curso, required this.brightness});

  final CursoDelegado curso;
  final Brightness brightness;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: MaterialTheme.primaryColor.withValues(alpha: 0.15),
            child: const Icon(
              LucideIcons.shieldCheck,
              color: MaterialTheme.primaryColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  curso.nombreCurso,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: MaterialTheme.textPrimary(brightness),
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _Badge(
                      text: curso.codigoSeccion,
                      color: MaterialTheme.primaryColor,
                    ),
                    _Badge(
                      text: curso.rolTexto,
                      color: MaterialTheme.textMuted(brightness),
                    ),
                    _Badge(
                      text: '${curso.alumnosMatriculados} alumnos',
                      color: MaterialTheme.textMuted(brightness),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.subtitle,
    required this.brightness,
    this.onRefresh,
  });

  final String title;
  final String subtitle;
  final Brightness brightness;
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: MaterialTheme.textPrimary(brightness),
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: MaterialTheme.textMuted(brightness),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        if (onRefresh != null)
          IconButton(
            tooltip: 'Actualizar',
            visualDensity: VisualDensity.compact,
            onPressed: onRefresh,
            icon: const Icon(
              LucideIcons.refreshCw,
              color: MaterialTheme.primaryDark,
              size: 18,
            ),
          ),
      ],
    );
  }
}

class _StatisticsSection extends StatelessWidget {
  const _StatisticsSection({required this.controller});

  final DelegadoAnunciosController controller;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.brightnessOf(context);

    return _Panel(
      brightness: brightness,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionTitle(
            title: 'Estadísticas de la sección',
            subtitle: 'Resumen académico del salón',
            brightness: brightness,
            onRefresh: controller.fetchStatistics,
          ),
          const SizedBox(height: 12),
          Obx(() {
            if (controller.loadingStats.value) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 18),
                child: Center(
                  child: CircularProgressIndicator(
                    color: MaterialTheme.primaryColor,
                  ),
                ),
              );
            }

            // Falló la carga (no es lo mismo que "sin notas todavía").
            if (controller.statsError.value && controller.statistics.value == null) {
              return ErrorRetry(
                compact: true,
                title: 'No se pudieron cargar las estadísticas',
                onRetry: controller.fetchStatistics,
              );
            }

            final stats = controller.statistics.value;
            if (stats == null || stats.isEmpty) {
              return _InlineEmptyState(
                icon: LucideIcons.chartColumn,
                message:
                    'Aún no hay notas oficiales cargadas para esta sección.',
                brightness: brightness,
              );
            }

            return _StatisticsContent(stats: stats);
          }),
        ],
      ),
    );
  }
}

class _StatisticsContent extends StatelessWidget {
  const _StatisticsContent({required this.stats});

  final EstadisticasSeccion stats;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.brightnessOf(context);

    return Column(
      children: [
        Row(
          children: [
            _MetricTile(
              label: 'Promedio general',
              value: stats.promedioGeneral.toStringAsFixed(1),
              brightness: brightness,
            ),
            const SizedBox(width: 10),
            _MetricTile(
              label: 'Aprobados',
              value: '${stats.porcentajeAprobados.toStringAsFixed(0)}%',
              brightness: brightness,
            ),
          ],
        ),
        const SizedBox(height: 16),
        _BarRow(label: '0-10', value: stats.rango0_10, max: stats.maxRango),
        _BarRow(label: '11-13', value: stats.rango11_13, max: stats.maxRango),
        _BarRow(label: '14-16', value: stats.rango14_16, max: stats.maxRango),
        _BarRow(label: '17-20', value: stats.rango17_20, max: stats.maxRango),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.brightness,
  });

  final String label;
  final String value;
  final Brightness brightness;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: MaterialTheme.espPrincipalBg(brightness),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: MaterialTheme.primaryDark,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: MaterialTheme.textSecondary(brightness),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BarRow extends StatelessWidget {
  const _BarRow({required this.label, required this.value, required this.max});

  final String label;
  final int value;
  final int max;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.brightnessOf(context);
    final ratio = max == 0 ? 0.0 : value / max;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 48,
            child: Text(
              label,
              style: TextStyle(
                color: MaterialTheme.textSecondary(brightness),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 12,
                color: MaterialTheme.primaryColor,
                backgroundColor: MaterialTheme.progressBg(brightness),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 24,
            child: Text(
              '$value',
              textAlign: TextAlign.right,
              style: TextStyle(
                color: MaterialTheme.textPrimary(brightness),
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

enum _AnnouncementAction { edit, delete }

class _AnnouncementCard extends StatelessWidget {
  const _AnnouncementCard({
    required this.anuncio,
    required this.onEdit,
    required this.onDelete,
  });

  final Anuncio anuncio;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return CardAnuncio(
      titulo: anuncio.titulo,
      descripcion: anuncio.mensaje,
      autor: '${anuncio.autor.fullName} - ${anuncio.autor.roleLabel}',
      fecha: anuncio.fecha,
      action: PopupMenuButton<_AnnouncementAction>(
        tooltip: 'Acciones',
        icon: Icon(
          LucideIcons.ellipsisVertical,
          size: 18,
          color: colors.secondary,
        ),
        onSelected: (action) {
          switch (action) {
            case _AnnouncementAction.edit:
              onEdit();
              break;
            case _AnnouncementAction.delete:
              onDelete();
              break;
          }
        },
        itemBuilder: (_) => const [
          PopupMenuItem(
            value: _AnnouncementAction.edit,
            child: Row(
              children: [
                Icon(LucideIcons.pencil, size: 17),
                SizedBox(width: 8),
                Text('Editar'),
              ],
            ),
          ),
          PopupMenuItem(
            value: _AnnouncementAction.delete,
            child: Row(
              children: [
                Icon(LucideIcons.trash2, size: 17, color: Colors.red),
                SizedBox(width: 8),
                Text('Eliminar', style: TextStyle(color: Colors.red)),
              ],
            ),
          ),
        ],
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.message,
    required this.brightness,
  });

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
          Icon(icon, size: 46, color: MaterialTheme.textMuted(brightness)),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: MaterialTheme.textSecondary(brightness),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineEmptyState extends StatelessWidget {
  const _InlineEmptyState({
    required this.icon,
    required this.message,
    required this.brightness,
  });

  final IconData icon;
  final String message;
  final Brightness brightness;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: MaterialTheme.tagBg(brightness),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: MaterialTheme.textMuted(brightness)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
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

class _Panel extends StatelessWidget {
  const _Panel({required this.child, required this.brightness});

  final Widget child;
  final Brightness brightness;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: MaterialTheme.cardBg(brightness),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: MaterialTheme.borderColor(brightness)),
      ),
      child: child,
    );
  }
}
