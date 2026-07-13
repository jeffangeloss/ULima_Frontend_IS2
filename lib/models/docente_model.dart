import 'networking_model.dart';

class Docente {
  final String code;
  final String firstName;
  final String lastName;
  final NetworkingCardDto? networking;

  Docente({
    required this.code,
    required this.firstName,
    required this.lastName,
    this.networking,
  });

  String get fullName => '$firstName $lastName';

  // Convierte JSON a objeto
  factory Docente.fromJson(Map<String, dynamic> json) {
    return Docente(
      code: json['code']?.toString() ?? 'Sin código',
      firstName: json['firstName']?.toString() ?? 'No',
      lastName: json['lastName']?.toString() ?? 'Asignado',
      networking: _parseNetworking(json['networking']),
    );
  }

  static NetworkingCardDto? _parseNetworking(dynamic value) {
    if (value is! Map) return null;
    try {
      return NetworkingCardDto.fromJson(Map<String, dynamic>.from(value));
    } on FormatException {
      return null;
    }
  }
}
