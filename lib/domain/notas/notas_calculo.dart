// lib/domain/notas/notas_calculo.dart
// Cálculo puro del promedio ponderado de la calculadora de notas (HU06/HU07).
// Sin Flutter ni GetX: dominio testeable con `flutter test`. El cálculo de
// notas es responsabilidad del cliente (ver AUDITORIA_TABLERO.md / grades.spec).

/// Promedio ponderado: Σ (nota × peso/100). Cada nota es un mapa con `valor`
/// y `peso` (porcentaje). Tolera valores nulos o no numéricos (cuentan como 0).
double calcularPromedioPonderado(List notas) {
  if (notas.isEmpty) return 0.0;
  double suma = 0;
  for (final n in notas) {
    final valor = double.tryParse(n['valor']?.toString() ?? '') ?? 0.0;
    final peso = double.tryParse(n['peso']?.toString() ?? '') ?? 0.0;
    suma += valor * (peso / 100.0);
  }
  return suma;
}

/// Suma de los pesos (%) de las notas ingresadas (para saber el avance).
double sumaDePesos(List notas) {
  return notas.fold(0.0, (sum, item) {
    final peso = double.tryParse(item['peso']?.toString() ?? '') ?? 0.0;
    return sum + peso;
  });
}
