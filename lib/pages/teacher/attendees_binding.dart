// lib/pages/teacher/attendees_binding.dart

import 'package:get/get.dart';

import 'attendees_controller.dart';

class AttendeesBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => AttendeesController());
  }
}
