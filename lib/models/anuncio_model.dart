import 'package:ulima_plus/models/user_model.dart';

class Anuncio {
  final String id;
  final String idSeccion;
  final String titulo;
  final String mensaje;
  final String fecha;
  final String autorCode;
  final UserModel autor;

  Anuncio({
    required this.id,
    required this.idSeccion,
    required this.titulo,
    required this.mensaje,
    required this.fecha,
    required this.autorCode,
    required this.autor,
  });

  Anuncio copyWith({
    String? id,
    String? idSeccion,
    String? titulo,
    String? mensaje,
    String? fecha,
    String? autorCode,
    UserModel? autor,
  }) {
    return Anuncio(
      id: id ?? this.id,
      idSeccion: idSeccion ?? this.idSeccion,
      titulo: titulo ?? this.titulo,
      mensaje: mensaje ?? this.mensaje,
      fecha: fecha ?? this.fecha,
      autorCode: autorCode ?? this.autorCode,
      autor: autor ?? this.autor,
    );
  }

  factory Anuncio.fromJson(
    Map<String, dynamic> json, {
    required UserModel autor,
  }) {
    return Anuncio(
      id: json['id'].toString(),
      idSeccion: json['idSeccion'].toString(),
      titulo: json['titulo'].toString(),
      mensaje: json['mensaje'].toString(),
      fecha: json['fecha'].toString(),
      autorCode: json['autorCode'].toString(),
      autor: autor,
    );
  }
}
