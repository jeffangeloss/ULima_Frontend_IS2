import 'package:get/get.dart';
import '../../services/alert_service.dart';

class HomeController extends GetxController {
  @override
  void onInit() {
    super.onInit();
    try {
      AlertService.to.fetchAlerts();
    } catch (_) {}
  }
}

