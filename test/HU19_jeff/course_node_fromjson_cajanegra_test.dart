// test/HU19_jeff/course_node_fromjson_cajanegra_test.dart
//
// CAJA NEGRA — HU19 (malla): deserializar un curso desde el JSON del backend.
// Funcionalidad: CourseNode.fromJson(map)  — lib/domain/malla/malla_entities.dart
//
// Se derivan CUATRO casos desde los REQUISITOS del payload (no del código). El
// objeto debe tolerar campos faltantes o valores límite sin romper la malla.
//
// CAMPOS (10): id, code, name, credits, level, prerequisites, category, row,
//              specialties, externalFaculty.
//
// PARTICIÓN DE EQUIVALENCIA + VALORES LÍMITE:
// | Campo            | Clase válida             | Clase por defecto / límite                    |
// |------------------|--------------------------|-----------------------------------------------|
// | id/code/name     | string                   | ausente/null → '' ; número → su string        |
// | credits          | num → toInt              | ausente/null → 3 ; LÍMITE 0 → 0 (no default)  |
// | level / row      | num → toInt              | ausente → 1 / 0                                |
// | prerequisites    | lista de strings         | null → [] ; ['', 'a', null] → ['a'] (filtra)  |
// | specialties      | lista de strings         | null → [] ; filtra vacíos                     |
// | category         | EEGG/COMMON/ELECTIVE/... | desconocida o null → faculty (isElective=F)   |
// | externalFaculty  | string → isExternal=T    | ausente → null → isExternal=F                 |

import 'package:flutter_test/flutter_test.dart';
import 'package:ulima_plus/domain/malla/malla_entities.dart';

void main() {
  group('CAJA NEGRA · CourseNode.fromJson (HU19)', () {
    test('CV1: payload completo y válido (category ELECTIVE, con facultad externa)', () {
      final c = CourseNode.fromJson({
        'id': '101',
        'code': 'ISW2',
        'name': 'Ingeniería de Software 2',
        'credits': 4,
        'level': 8,
        'prerequisites': ['50', '51'],
        'category': 'ELECTIVE',
        'row': 2,
        'specialties': ['SW'],
        'externalFaculty': 'Ciencias',
      });
      expect(c.id, '101');
      expect(c.code, 'ISW2');
      expect(c.name, 'Ingeniería de Software 2');
      expect(c.credits, 4);
      expect(c.level, 8);
      expect(c.prerequisites, ['50', '51']);
      expect(c.isElective, isTrue);
      expect(c.row, 2);
      expect(c.specialties, ['SW']);
      expect(c.isExternal, isTrue);
    });

    test('CV2 (defaults): objeto vacío → strings vacíos, credits 3, level 1, row 0, faculty', () {
      final c = CourseNode.fromJson(<String, dynamic>{});
      expect(c.id, '');
      expect(c.code, '');
      expect(c.name, '');
      expect(c.credits, 3);
      expect(c.level, 1);
      expect(c.row, 0);
      expect(c.isElective, isFalse); // category por defecto = faculty
      expect(c.prerequisites, isEmpty);
      expect(c.specialties, isEmpty);
      expect(c.isExternal, isFalse); // externalFaculty ausente → null
    });

    test('CNV1 (límite): prerequisites con vacíos y null se filtran → solo los reales', () {
      final c = CourseNode.fromJson({
        'prerequisites': ['', 'a', null, '  ', 'b'],
      });
      // Filtra '' y null (whitespace no se recorta, se conserva).
      expect(c.prerequisites, ['a', '  ', 'b']);
    });

    test('CNV2 (límite): credits == 0 se respeta (no cae al default 3)', () {
      expect(CourseNode.fromJson({'credits': 0}).credits, 0);
    });
  });
}
