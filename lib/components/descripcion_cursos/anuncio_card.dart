import 'package:flutter/material.dart';

class CardAnuncio extends StatelessWidget {
  final String titulo;
  final String descripcion;
  final String autor;
  final String fecha;
  final Widget? action;

  const CardAnuncio({
    super.key,
    required this.titulo,
    required this.descripcion,
    required this.autor,
    required this.fecha,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    ColorScheme colors = Theme.of(context).colorScheme;
    final formattedFecha = _formatDate(fecha);

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.outline, width: 0.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    titulo,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (action != null) ...[const SizedBox(width: 8), action!],
              ],
            ),

            const SizedBox(height: 10),

            Text(descripcion),

            const SizedBox(height: 14),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,

              children: [
                Expanded(
                  child: Text(
                    autor,

                    style: TextStyle(color: colors.primary, fontSize: 12),
                  ),
                ),

                Text(
                  formattedFecha,

                  style: TextStyle(color: colors.secondary, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _formatDate(String raw) {
    final date = DateTime.tryParse(raw);
    if (date == null) {
      final datePrefix = RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(raw);
      if (datePrefix != null) {
        return '${datePrefix.group(3)}/${datePrefix.group(2)}/${datePrefix.group(1)}';
      }
      return raw.split(RegExp(r'\s+')).first;
    }
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
