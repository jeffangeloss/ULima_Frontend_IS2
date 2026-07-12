import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/asesoria_model.dart';

class CardAsesoria extends StatefulWidget {
  final Asesoria asesoria;
  // HU17: callback para confirmar/cancelar asistencia. Si es null, no se muestra
  // el botón (p.ej. usos de solo-lectura o tests que no ejercitan el RSVP).
  final Future<void> Function()? onToggleRsvp;

  const CardAsesoria({super.key, required this.asesoria, this.onToggleRsvp});

  @override
  State<CardAsesoria> createState() => _CardAsesoriaState();
}

class _CardAsesoriaState extends State<CardAsesoria> {
  bool expanded = false;
  bool _rsvpBusy = false; // HU17: deshabilita el botón mientras corre la request.

  Future<void> _onRsvpPressed() async {
    if (_rsvpBusy || widget.onToggleRsvp == null) return;
    setState(() => _rsvpBusy = true);
    try {
      await widget.onToggleRsvp!();
    } finally {
      if (mounted) setState(() => _rsvpBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      children: [
        InkWell(
          onTap: () {
            setState(() {
              expanded = !expanded;
            });
          },

          borderRadius: BorderRadius.circular(16),

          child: Container(
            width: double.infinity,

            padding: const EdgeInsets.all(16),

            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: colors.outline, width: 0.5),
            ),

            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,

              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      // HU18: badge "Extra · fecha" + etiqueta del dictante (Profesor/JP).
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (widget.asesoria.esExtra)
                            _Chip(
                              text: widget.asesoria.fecha != null
                                  ? 'Extra · ${widget.asesoria.fecha}'
                                  : 'Extra',
                              color: colors.primary,
                            ),
                          _Chip(
                            text: widget.asesoria.dictanteRol,
                            color: colors.secondary,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${widget.asesoria.dia} ${widget.asesoria.inicio} - ${widget.asesoria.fin}',

                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.groups_outlined,
                              size: 14, color: colors.secondary),
                          const SizedBox(width: 4),
                          Text(
                            '${widget.asesoria.asistentes} asistirán',
                            style: TextStyle(color: colors.secondary, fontSize: 12),
                          ),
                        ],
                      ),
                      // HU17: botón para confirmar/cancelar asistencia.
                      if (widget.onToggleRsvp != null) ...[
                        const SizedBox(height: 8),
                        _RsvpButton(
                          asistira: widget.asesoria.myRsvp,
                          busy: _rsvpBusy,
                          onPressed: _onRsvpPressed,
                        ),
                      ],
                    ],
                  ),
                ),

                Text(
                  expanded ? '▲' : '▼',

                  style: TextStyle(color: colors.primary, fontSize: 16),
                ),
              ],
            ),
          ),
        ),

        if (expanded)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(16),

            decoration: BoxDecoration(
              color: colors.surface.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.outline),
            ),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _info(context, 'Docente', widget.asesoria.docente.fullName),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [
                          _info(context, 'Aula', widget.asesoria.aula),
                        ],
                      ),
                    ),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,

                        children: [
                          Text(
                            'Zoom',

                            style: TextStyle(
                              color: colors.secondary,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),

                          GestureDetector(
                            onTap: () async {
                              final Uri url = Uri.parse(widget.asesoria.zoom);

                              await launchUrl(
                                url,

                                mode: LaunchMode.externalApplication,
                              );
                            },

                            child: const Text(
                              'Acceder a la sala',
                              style: TextStyle(
                                color: Color.fromARGB(255, 33, 89, 243),
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.underline,
                                decorationColor: Color.fromARGB(
                                  255,
                                  33,
                                  89,
                                  243,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _info(BuildContext context, String title, String value) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        Text(title, style: TextStyle(color: colors.secondary, fontSize: 12)),

        const SizedBox(height: 4),

        Text(
          value,

          style: TextStyle(color: colors.onSurface.withValues(alpha: 0.9)),
        ),
      ],
    );
  }
}

/// HU17: botón compacto para confirmar/cancelar asistencia a la asesoría.
/// Confirmado → botón "outlined" con check y opción de cancelar; sin confirmar →
/// botón "filled" que invita a asistir. Muestra spinner mientras corre la request.
class _RsvpButton extends StatelessWidget {
  const _RsvpButton({
    required this.asistira,
    required this.busy,
    required this.onPressed,
  });

  final bool asistira;
  final bool busy;
  final Future<void> Function() onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final Widget child = busy
        ? const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(asistira ? Icons.check_circle : Icons.add, size: 16),
              const SizedBox(width: 6),
              Text(asistira ? 'Asistiré · Cancelar' : 'Asistiré'),
            ],
          );

    final onTap = busy ? null : onPressed;
    final style = ButtonStyle(
      visualDensity: VisualDensity.compact,
      padding: WidgetStatePropertyAll(
        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
    );

    return Semantics(
      button: true,
      label: asistira ? 'Cancelar asistencia' : 'Confirmar asistencia',
      child: asistira
          ? OutlinedButton(
              onPressed: onTap,
              style: style.copyWith(
                foregroundColor: WidgetStatePropertyAll(colors.primary),
              ),
              child: child,
            )
          : FilledButton(
              onPressed: onTap,
              style: style,
              child: child,
            ),
    );
  }
}

/// Etiqueta compacta (HU18): badge "Extra · fecha" y rol del dictante.
class _Chip extends StatelessWidget {
  const _Chip({required this.text, required this.color});
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
