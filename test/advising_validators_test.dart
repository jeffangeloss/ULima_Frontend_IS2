// test/advising_validators_test.dart
// HU18: pruebas de los validadores puros del formulario de asesoría extra
// (7 campos de entrada). Cubren caja negra (particiones por campo) y unitaria
// (rango horario y ubicación por modalidad).

import 'package:flutter_test/flutter_test.dart';
import 'package:ulima_plus/pages/teacher/advising_validators.dart';

void main() {
  final today = DateTime(2026, 7, 6);

  group('validateSection', () {
    test('null → error', () => expect(validateSection(null), isNotNull));
    test('id válido → ok', () => expect(validateSection(12), isNull));
  });

  group('validateDate', () {
    test('null → error', () => expect(validateDate(null, today), isNotNull));
    test('pasado → error',
        () => expect(validateDate(DateTime(2026, 7, 5), today), isNotNull));
    test('hoy → ok', () => expect(validateDate(DateTime(2026, 7, 6), today), isNull));
    test('futuro → ok', () => expect(validateDate(DateTime(2026, 7, 20), today), isNull));
  });

  group('validateTimeRange', () {
    test('vacío → error', () => expect(validateTimeRange('', ''), isNotNull));
    test('formato inválido → error', () => expect(validateTimeRange('25:00', '26:00'), isNotNull));
    test('inicio ≥ fin → error', () => expect(validateTimeRange('11:00', '10:00'), isNotNull));
    test('iguales → error', () => expect(validateTimeRange('10:00', '10:00'), isNotNull));
    test('inicio < fin → ok', () => expect(validateTimeRange('10:00', '11:30'), isNull));
  });

  group('validateLocation', () {
    test('presencial sin aula → error',
        () => expect(validateLocation('classroom', '', 'https://x'), isNotNull));
    test('presencial con aula → ok',
        () => expect(validateLocation('classroom', 'T-501', ''), isNull));
    test('virtual sin enlace → error',
        () => expect(validateLocation('virtual', 'T-501', ''), isNotNull));
    test('virtual con enlace → ok',
        () => expect(validateLocation('virtual', '', 'https://x'), isNull));
    test('híbrida con al menos uno → ok',
        () => expect(validateLocation('hybrid', 'T-501', ''), isNull));
    test('híbrida sin nada → error',
        () => expect(validateLocation('hybrid', '  ', '  '), isNotNull));
  });

  group('validateCapacity', () {
    test('vacío (opcional) → ok', () => expect(validateCapacity(''), isNull));
    test('positivo → ok', () => expect(validateCapacity('20'), isNull));
    test('cero → error', () => expect(validateCapacity('0'), isNotNull));
    test('negativo → error', () => expect(validateCapacity('-3'), isNotNull));
    test('no numérico → error', () => expect(validateCapacity('abc'), isNotNull));
  });

  group('validateAdvisingForm (integración de precedencia)', () {
    String? run({
      int? sectionId = 5,
      DateTime? date,
      String start = '10:00',
      String end = '11:00',
      String modality = 'classroom',
      String classroom = 'T-501',
      String url = '',
      String capacity = '',
    }) =>
        validateAdvisingForm(
          sectionId: sectionId,
          date: date ?? DateTime(2026, 7, 10),
          startTime: start,
          endTime: end,
          modality: modality,
          classroom: classroom,
          meetingUrl: url,
          capacityText: capacity,
          today: today,
        );

    test('caso feliz → null', () => expect(run(), isNull));
    test('sin sección tiene precedencia', () => expect(run(sectionId: null), isNotNull));
    test('fecha pasada', () => expect(run(date: DateTime(2026, 7, 1)), isNotNull));
    test('rango horario inválido', () => expect(run(start: '12:00', end: '11:00'), isNotNull));
    test('ubicación faltante por modalidad', () => expect(run(classroom: ''), isNotNull));
    test('cupo inválido', () => expect(run(capacity: '0'), isNotNull));
  });
}
