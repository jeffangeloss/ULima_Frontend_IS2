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

double sumaDePesos(List notas) {
  return notas.fold(0.0, (sum, item) {
    final peso = double.tryParse(item['peso']?.toString() ?? '') ?? 0.0;
    return sum + peso;
  });
}
