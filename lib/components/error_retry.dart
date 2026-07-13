import 'package:flutter/material.dart';

/// Estado de error reutilizable con botón "Reintentar".
///
/// Distingue un FALLO de carga de una lista legítimamente vacía. La app venía
/// mostrando estados "sin datos" (o pantallas en blanco) cuando en realidad la
/// petición había fallado, dejando al usuario sin pista del problema
/// (ver docs/AUDITORIA_TECNICA.md §6.1 en el backend). Mostrar este widget en
/// lugar del estado vacío cuando la carga terminó en error.
///
/// Mismo lenguaje visual que `EmptyTabState` y que el `_ErrorState` de la malla,
/// para tener un solo patrón de error en toda la app.
class ErrorRetry extends StatelessWidget {
  const ErrorRetry({
    super.key,
    required this.onRetry,
    this.title = 'No se pudo cargar',
    this.message =
        'Hubo un problema al cargar esta información. Revisa tu conexión e inténtalo de nuevo.',
    this.icon = Icons.wifi_off_rounded,
    this.compact = false,
  });

  final VoidCallback onRetry;
  final String title;
  final String message;
  final IconData icon;

  /// `true` alinea arriba (para pestañas/listas, como `EmptyTabState`); `false`
  /// centra vertical (para pantallas completas, como la malla).
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: colors.error.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Icon(icon, color: colors.error, size: 30),
        ),
        const SizedBox(height: 16),
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: colors.onSurface,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: colors.onSurfaceVariant,
            fontSize: 13,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 18),
        ElevatedButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded, size: 18),
          label: const Text(
            'Reintentar',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: colors.primary,
            foregroundColor: colors.onPrimary,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );

    return Align(
      alignment: compact ? Alignment.topCenter : Alignment.center,
      child: Padding(
        padding: EdgeInsets.fromLTRB(32, compact ? 28 : 0, 32, 0),
        child: content,
      ),
    );
  }
}
