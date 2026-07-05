// lib/models/malla_models.dart
// Modelos del dominio de la malla curricular.
//
// TT03: los tipos puros (CourseStatus, CourseNode, CourseProgress, marcadores
// de ciclo) viven en lib/domain/malla/malla_entities.dart — sin dependencias
// de Flutter — y se re-exportan aquí para que los imports existentes sigan
// funcionando sin cambios. En este archivo solo queda la capa visual
// (colores por estado), que sí requiere Flutter.

import 'package:flutter/material.dart';

import '../domain/malla/malla_entities.dart';

export '../domain/malla/malla_entities.dart';

extension CourseStatusX on CourseStatus {
  /// Color principal para pintar la card.
  Color get color {
    switch (this) {
      case CourseStatus.approved:
        return const Color(0xFF10B981);
      case CourseStatus.current:
        return const Color(0xFFF59E0B);
      case CourseStatus.unlocked:
        return const Color(0xFF0EA5E9);
      case CourseStatus.locked:
        return const Color(0xFF94A3B8);
    }
  }

  /// Borde más oscuro (1 stop más fuerte que el fondo).
  Color get borderColor {
    switch (this) {
      case CourseStatus.approved:
        return const Color(0xFF059669);
      case CourseStatus.current:
        return const Color(0xFFD97706);
      case CourseStatus.unlocked:
        return const Color(0xFF0284C7);
      case CourseStatus.locked:
        return const Color(0xFF64748B);
    }
  }
}
