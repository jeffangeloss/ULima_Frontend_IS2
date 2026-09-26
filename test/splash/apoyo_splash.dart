// test/splash/apoyo_splash.dart
//
// Apoyo de las pruebas del splash. No termina en _test.dart, así que
// `flutter test` no lo corre como suite.

import 'dart:math';

/// Un `Random` que devuelve [valores] en orden, cada uno módulo el máximo que
/// le piden, y anota esos máximos.
class RandomFijo implements Random {
  RandomFijo(this.valores);

  final List<int> valores;
  final List<int> maximos = <int>[];
  var _i = 0;

  @override
  int nextInt(int max) {
    maximos.add(max);
    final v = valores[_i % valores.length];
    _i++;
    return v % max;
  }

  @override
  double nextDouble() => 0;

  @override
  bool nextBool() => false;
}
