import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/docente_model.dart';

class DocenteService {

  // Obtiene docentes
  Future<List<Docente>>
      fetchDocentes() async {

    // Carga JSON
    final String response =
        await rootBundle.loadString(
      'assets/data/docentes.json',
    );

    // Convierte JSON
    final data =
        json.decode(response);

    // Lista docentes
    final List docentes =
        data['docentes'];

    // Convierte a models
    return docentes
        .map(
          (d) =>
              Docente.fromJson(d),
        )
        .toList();
  }

  // Busca docente por código
  Future<Docente?>
      findDocenteByCode(
    String code,
  ) async {

    final docentes =
        await fetchDocentes();

    try {

      return docentes.firstWhere(
        (d) => d.code == code,
      );

    } catch (e) {

      return null;
    }
  }
}