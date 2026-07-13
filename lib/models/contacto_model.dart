import 'package:ulima_plus/models/user_model.dart';

import 'networking_model.dart';

class ContactoCurso {
  final UserModel user;
  final String roleInSection;
  final NetworkingCardDto? networking;

  ContactoCurso({
    required this.user,
    required this.roleInSection,
    this.networking,
  });

  void operator [](String other) {}
}
