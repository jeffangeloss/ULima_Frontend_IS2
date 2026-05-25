import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/user_model.dart';

class UserService {

  // Obtiene todos los usuarios
  Future<List<UserModel>>
      fetchUsers() async {

    // Carga JSON
    final String response =
        await rootBundle.loadString(
      'assets/data/users.json',
    );

    // Convierte JSON
    final data =
        json.decode(response);

    // Lista users
    final List users =
        data['users'];

    // Convierte a models
    return users
        .map(
          (u) =>
              UserModel.fromJson(u),
        )
        .toList();
  }

  // Busca usuario por código
  Future<UserModel?>
      findUserByCode(
    String code,
  ) async {

    final users =
        await fetchUsers();

    try {

      return users.firstWhere(
        (u) => u.code == code,
      );

    } catch (e) {

      return null;
    }
  }
  
  Future<UserModel> findRequiredUserByCode(String code) async {
    final user=await findUserByCode(code);
    if(user==null){
      throw Exception('No existe un usuario con código $code');
    }
    return user;
  }
}