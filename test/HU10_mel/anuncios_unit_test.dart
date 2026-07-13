// test/HU10_mel/anuncios_unit_test.dart
//
// PRUEBAS UNITARIAS - HU10 modelos cliente para anuncios gestionados.
// Se prueban reglas pequenas de Anuncio y CursoDelegado, sin red ni GetX.

import 'package:flutter_test/flutter_test.dart';
import 'package:ulima_plus/models/anuncio_model.dart';
import 'package:ulima_plus/models/curso_delegado_model.dart';
import 'package:ulima_plus/models/user_model.dart';

final _autor = UserModel(
  code: '20232637',
  firstName: 'Mel',
  lastName: 'Ruiz',
  email: '20232637@aloe.ulima.edu.pe',
  role: 'delegado',
  currentCycle: '2026-1',
  setupComplete: true,
);

void main() {
  group('UNITARIA · HU10 Anuncio/CursoDelegado', () {
    test('caso 1: Anuncio.fromJson normaliza ids numericos a string', () {
      final anuncio = Anuncio.fromJson({
        'id': 10,
        'idSeccion': 20,
        'titulo': 'Parcial',
        'mensaje': 'Repasar',
        'fecha': '2026-07-13',
        'autorCode': 20232637,
      }, autor: _autor);

      expect(anuncio.id, '10');
      expect(anuncio.idSeccion, '20');
      expect(anuncio.autorCode, '20232637');
    });

    test('caso 2: copyWith cambia solo campos indicados', () {
      final base = Anuncio(
        id: '1',
        idSeccion: '20',
        titulo: 'Antes',
        mensaje: 'Mensaje',
        fecha: '2026-07-13',
        autorCode: _autor.code,
        autor: _autor,
      );

      final updated = base.copyWith(titulo: 'Despues');

      expect(updated.titulo, 'Despues');
      expect(updated.mensaje, base.mensaje);
      expect(updated.autor, same(base.autor));
    });

    test('caso 3: CursoDelegado.fromJson acepta nombres backend en ingles', () {
      final curso = CursoDelegado.fromJson({
        'courseId': 7,
        'courseName': 'IS2',
        'sectionId': 20,
        'sectionCode': 'SW02',
        'role': 'delegate',
        'enrolledStudents': 35,
      });

      expect(curso.idCurso, '7');
      expect(curso.idSeccion, '20');
      expect(curso.codigoSeccion, 'SW02');
      expect(curso.alumnosMatriculados, 35);
    });

    test('caso 4: rolTexto distingue subdelegado de delegado', () {
      expect(
        CursoDelegado.fromJson({'role': 'subdelegate'}).rolTexto,
        'Subdelegado',
      );
      expect(CursoDelegado.fromJson({'role': 'delegate'}).rolTexto, 'Delegado');
    });
  });
}
