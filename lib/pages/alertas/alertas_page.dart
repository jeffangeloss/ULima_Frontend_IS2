// lib/pages/alertas/alertas_page.dart
// Pantalla de buzón de alertas para el estudiante.

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ulima_plus/components/skeleton.dart';
import 'package:ulima_plus/configs/themes.dart';
import 'package:ulima_plus/models/alert_model.dart';
import 'package:ulima_plus/services/alert_service.dart';

class AlertasPage extends StatefulWidget {
  const AlertasPage({super.key});

  @override
  State<AlertasPage> createState() => _AlertasPageState();
}

class _AlertasPageState extends State<AlertasPage> {
  @override
  void initState() {
    super.initState();
    // Refresh alerts when opening the page
    AlertService.to.fetchAlerts();
  }

  String _formatDateTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.isNegative) return 'Hace un momento';
    if (diff.inMinutes < 60) {
      return 'Hace ${diff.inMinutes} min';
    } else if (diff.inHours < 24) {
      return 'Hace ${diff.inHours} h';
    } else {
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    }
  }

  Widget _buildAlertIcon(String type) {
    if (type == 'academic_risk') {
      return Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          LucideIcons.alertOctagon,
          color: Colors.redAccent,
          size: 26,
        ),
      );
    } else if (type == 'high_load') {
      return Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.amber.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          LucideIcons.calendarClock,
          color: Colors.amber,
          size: 26,
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.blue.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          LucideIcons.bell,
          color: Colors.blueAccent,
          size: 26,
        ),
      );
    }
  }

  Color _getLeftBorderColor(String type) {
    if (type == 'academic_risk') return Colors.redAccent;
    if (type == 'high_load') return Colors.amber;
    return Colors.blueAccent;
  }

  void _markAllAsRead() async {
    final unreadAlerts = AlertService.to.alerts.where((a) => !a.isRead).toList();
    if (unreadAlerts.isEmpty) return;

    Get.showOverlay(
      asyncFunction: () async {
        for (final alert in unreadAlerts) {
          await AlertService.to.markAsRead(alert.id);
        }
      },
      loadingWidget: const Center(child: CircularProgressIndicator()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        backgroundColor: MaterialTheme.headerColor(Theme.brightnessOf(context)),
        foregroundColor: Colors.white,
        title: const Text(
          'Buzón de Alertas',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          Obx(() {
            final hasUnread = AlertService.to.alerts.any((a) => !a.isRead);
            if (!hasUnread) return const SizedBox.shrink();
            return IconButton(
              icon: const Icon(LucideIcons.checkCheck),
              tooltip: 'Marcar todas como leídas',
              onPressed: _markAllAsRead,
            );
          }),
          IconButton(
            icon: const Icon(LucideIcons.refreshCw),
            tooltip: 'Actualizar',
            onPressed: () => AlertService.to.fetchAlerts(),
          ),
        ],
      ),
      body: Obx(() {
        if (AlertService.to.isLoading && AlertService.to.alerts.isEmpty) {
          // Skeleton de cards en lugar de spinner central: mantiene la
          // estructura visual de la lista mientras cargan las alertas.
          return const SkeletonCardList(
            count: 4,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          );
        }

        final alerts = AlertService.to.alerts;

        if (alerts.isEmpty) {
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      LucideIcons.bellRing,
                      color: colors.primary,
                      size: 72,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    '¡Todo al día!',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: colors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No tienes alertas de riesgo académico o alta carga de exámenes en este momento.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: colors.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => AlertService.to.fetchAlerts(),
          color: colors.primary,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: alerts.length,
            itemBuilder: (context, index) {
              final AlertModel alert = alerts[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF26262B) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    onTap: () {
                      if (!alert.isRead) {
                        AlertService.to.markAsRead(alert.id);
                      }
                    },
                    child: Stack(
                      children: [
                        // Left accent bar
                        Positioned(
                          left: 0,
                          top: 0,
                          bottom: 0,
                          width: 5,
                          child: Container(
                            color: _getLeftBorderColor(alert.type),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(
                            left: 18,
                            right: 16,
                            top: 16,
                            bottom: 16,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildAlertIcon(alert.type),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      alert.title,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: alert.isRead
                                            ? FontWeight.normal
                                            : FontWeight.bold,
                                        color: colors.onSurface,
                                      ),
                                    ),
                                    if (alert.courseName != null) ...[
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(LucideIcons.bookOpen, size: 12, color: colors.onSurface.withValues(alpha: 0.5)),
                                          const SizedBox(width: 4),
                                          Text(
                                            alert.courseName!,
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: colors.onSurface.withValues(alpha: 0.6),
                                            ),
                                          ),
                                          if (alert.sectionCode != null && alert.sectionCode!.isNotEmpty) ...[
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                              decoration: BoxDecoration(
                                                color: colors.primary.withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                'Sec ${alert.sectionCode}',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w700,
                                                  color: colors.primary,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _formatDateTime(alert.createdAt),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colors.onSurface.withValues(alpha: 0.5),
                                ),
                              ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      alert.message,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: colors.onSurface.withValues(
                                          alpha: alert.isRead ? 0.6 : 0.85,
                                        ),
                                        height: 1.3,
                                      ),
                                    ),
                                    if (!alert.isRead) ...[
                                      const SizedBox(height: 12),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: TextButton.icon(
                                          onPressed: () => AlertService.to
                                              .markAsRead(alert.id),
                                          icon: const Icon(
                                            LucideIcons.checkCircle,
                                            size: 16,
                                          ),
                                          label: const Text(
                                            'Marcar como leída',
                                            style: TextStyle(fontSize: 13),
                                          ),
                                          style: TextButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 4,
                                            ),
                                            minimumSize: Size.zero,
                                            tapTargetSize:
                                                MaterialTapTargetSize.shrinkWrap,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Unread small dot
                        if (!alert.isRead)
                          Positioned(
                            right: 8,
                            top: 8,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color.fromARGB(255, 29, 111, 219),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      }),
    );
  }
}
