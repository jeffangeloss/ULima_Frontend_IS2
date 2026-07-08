class EstadisticasSeccion {
  final double promedioGeneral;
  final double porcentajeAprobados;
  final int rango0_10;
  final int rango11_13;
  final int rango14_16;
  final int rango17_20;

  const EstadisticasSeccion({
    required this.promedioGeneral,
    required this.porcentajeAprobados,
    required this.rango0_10,
    required this.rango11_13,
    required this.rango14_16,
    required this.rango17_20,
  });

  bool get isEmpty =>
      rango0_10 == 0 && rango11_13 == 0 && rango14_16 == 0 && rango17_20 == 0;

  int get maxRango {
    final values = [rango0_10, rango11_13, rango14_16, rango17_20];
    return values.reduce((a, b) => a > b ? a : b);
  }

  factory EstadisticasSeccion.fromJson(Map<String, dynamic> json) {
    return EstadisticasSeccion(
      promedioGeneral:
          (json['promedioGeneral'] as num?)?.toDouble() ??
          (json['averageScore'] as num?)?.toDouble() ??
          0,
      porcentajeAprobados:
          (json['porcentajeAprobados'] as num?)?.toDouble() ??
          (json['approvedPercentage'] as num?)?.toDouble() ??
          0,
      rango0_10:
          (json['rango0_10'] as num?)?.toInt() ??
          (json['range0_10'] as num?)?.toInt() ??
          0,
      rango11_13:
          (json['rango11_13'] as num?)?.toInt() ??
          (json['range11_13'] as num?)?.toInt() ??
          0,
      rango14_16:
          (json['rango14_16'] as num?)?.toInt() ??
          (json['range14_16'] as num?)?.toInt() ??
          0,
      rango17_20:
          (json['rango17_20'] as num?)?.toInt() ??
          (json['range17_20'] as num?)?.toInt() ??
          0,
    );
  }
}
