double calcularPromedioPonderado(List<Map<String, dynamic>> entries) {
  double sumaPonderada = 0;
  double sumaPesos = 0;

  for (final entry in entries) {
    final valor = _asDouble(entry['valor']);
    final peso = _asDouble(entry['peso']);
    if (peso <= 0) continue;

    sumaPonderada += valor * peso;
    sumaPesos += peso;
  }

  if (sumaPesos <= 0) return 0;
  return sumaPonderada / sumaPesos;
}

double _asDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}