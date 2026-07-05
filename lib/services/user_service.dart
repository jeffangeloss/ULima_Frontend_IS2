import '../models/user_model.dart';
import 'api_client.dart';

class UserService {
  final ApiClient _api = ApiClient();

  Future<List<UserModel>> fetchUsers() async {
    final data = await _api.getJson('/academic-profile/users');
    final List users = data['users'] ?? [];

    return users.map((u) => UserModel.fromJson(u)).toList();
  }

  Future<UserModel?> findUserByCode(String code) async {
    final users = await fetchUsers();

    try {
      return users.firstWhere((u) => u.code == code);
    } catch (e) {
      return null;
    }
  }

  Future<UserModel> findRequiredUserByCode(String code) async {
    final user = await findUserByCode(code);
    if (user == null) {
      throw Exception('No existe un usuario con codigo $code');
    }

    return user;
  }
}
