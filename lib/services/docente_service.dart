import '../models/docente_model.dart';
import 'api_client.dart';

class DocenteService {
  final ApiClient _api = ApiClient();

  Future<List<Docente>> fetchDocentes() async {
    final data = await _api.getJson('/course-detail/teachers');
    final List docentes = data['docentes'] ?? [];

    return docentes.map((d) => Docente.fromJson(d)).toList();
  }

  Future<Docente?> findDocenteByCode(String code) async {
    final docentes = await fetchDocentes();

    try {
      return docentes.firstWhere((d) => d.code == code);
    } catch (e) {
      return null;
    }
  }
}
