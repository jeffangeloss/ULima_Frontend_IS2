// lib/pages/bienvenida/widgets/franja_con_sello.dart
// La franja con el sello (RF-BIEN-4) y la píldora del registro (RF-BIEN-8).

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../components/logo/sello_del_logo.dart';
import '../../../configs/themes.dart';
import '../../../domain/bienvenida/bienvenida_turnos.dart';
import '../bienvenida_controller.dart';

class FranjaConSello extends StatelessWidget {
  const FranjaConSello({
    super.key,
    required this.latido,
    required this.rombos,
    this.radioInferior = 26,
  });

  final ValueListenable<double> latido;
  final ValueListenable<List<double>?> rombos;
  final double radioInferior;

  @override
  Widget build(BuildContext context) => CabeceraConSello(
    color: MaterialTheme.bienvenidaFranja(Theme.brightnessOf(context)),
    radioInferior: radioInferior,
    sello: SelloDelLogo(latido: latido, rombos: rombos),
  );
}

class PildoraDelRegistro extends StatelessWidget {
  const PildoraDelRegistro({super.key, required this.estado});

  final EstadoDeLaPildora estado;

  @override
  Widget build(BuildContext context) {
    final b = Theme.brightnessOf(context);
    final creada = estado == EstadoDeLaPildora.creada;
    final texto = creada
        ? TextosDeLaBienvenida.pildoraCreada
        : TextosDeLaBienvenida.pildoraCreando;
    return Semantics(
      liveRegion: true,
      label: texto,
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: creada
              ? MaterialTheme.bienvenidaPildoraLista(b)
              : MaterialTheme.bienvenidaPildora(b),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (creada)
                const Icon(LucideIcons.check, size: 14, color: Colors.white)
              else
                const SizedBox.square(
                  dimension: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
              const SizedBox(width: 8),
              Text(
                texto,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
