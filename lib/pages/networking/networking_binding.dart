import 'package:get/get.dart';

import '../../services/auth_service.dart';
import '../../services/networking_service.dart';
import 'networking_controller.dart';

class NetworkingBinding extends Bindings {
  @override
  void dependencies() {
    final auth = AuthService.to;
    Get.lazyPut<NetworkingGateway>(() => NetworkingService());
    Get.lazyPut(
      () => NetworkingController(
        gateway: Get.find<NetworkingGateway>(),
        user: auth.currentUser,
        careerLabel: auth.getCareerName(auth.currentUser?.careerId),
      ),
    );
  }
}
