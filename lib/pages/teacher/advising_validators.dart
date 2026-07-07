// lib/pages/teacher/advising_validators.dart
// Validadores puros del formulario de asesoría extra (HU18). Sin Flutter ni
// I/O: devuelven null si es válido o un mensaje en español. Son la superficie
// de las pruebas de caja negra (7 campos de entrada) y unitarias del frontend.

int _toMinutes(String hhmm) {
  final parts = hhmm.split(':');
  final h = int.tryParse(parts.isNotEmpty ? parts[0] : '') ?? 0;
  final m = int.tryParse(parts.length > 1 ? parts[1] : '') ?? 0;
  return h * 60 + m;
}

bool _isHhmm(String s) => RegExp(r'^([01]\d|2[0-3]):[0-5]\d$').hasMatch(s);

String? validateSection(int? sectionId) {
  if (sectionId == null) return 'Selecciona una sección.';
  return null;
}

/// `date` es la fecha elegida; `today` se inyecta para poder probarlo.
String? validateDate(DateTime? date, DateTime today) {
  if (date == null) return 'Selecciona la fecha de la asesoría.';
  final d = DateTime(date.year, date.month, date.day);
  final t = DateTime(today.year, today.month, today.day);
  if (d.isBefore(t)) return 'La fecha no puede ser en el pasado.';
  return null;
}

String? validateTimeRange(String startTime, String endTime) {
  if (startTime.isEmpty || endTime.isEmpty) return 'Indica la hora de inicio y de fin.';
  if (!_isHhmm(startTime) || !_isHhmm(endTime)) return 'Hora inválida (usa HH:MM).';
  if (_toMinutes(startTime) >= _toMinutes(endTime)) {
    return 'La hora de inicio debe ser anterior a la de fin.';
  }
  return null;
}

/// La modalidad determina qué ubicación es obligatoria.
String? validateLocation(String modality, String classroom, String meetingUrl) {
  final hasRoom = classroom.trim().isNotEmpty;
  final hasUrl = meetingUrl.trim().isNotEmpty;
  switch (modality) {
    case 'classroom':
      return hasRoom ? null : 'Indica el aula para una asesoría presencial.';
    case 'virtual':
      return hasUrl ? null : 'Indica el enlace para una asesoría virtual.';
    case 'hybrid':
      return (hasRoom || hasUrl) ? null : 'Indica el aula o el enlace.';
    default:
      return 'Modalidad inválida.';
  }
}

/// Cupo opcional: vacío es válido; si viene, debe ser entero positivo.
String? validateCapacity(String capacityText) {
  final t = capacityText.trim();
  if (t.isEmpty) return null;
  final n = int.tryParse(t);
  if (n == null || n <= 0) return 'El cupo debe ser un número mayor que 0.';
  return null;
}

/// Valida todo el formulario, en orden de precedencia. `today` inyectable.
String? validateAdvisingForm({
  required int? sectionId,
  required DateTime? date,
  required String startTime,
  required String endTime,
  required String modality,
  required String classroom,
  required String meetingUrl,
  required String capacityText,
  required DateTime today,
}) {
  return validateSection(sectionId) ??
      validateDate(date, today) ??
      validateTimeRange(startTime, endTime) ??
      validateLocation(modality, classroom, meetingUrl) ??
      validateCapacity(capacityText);
}
