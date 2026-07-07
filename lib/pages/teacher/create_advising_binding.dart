// lib/pages/teacher/create_advising_binding.dart

import 'package:get/get.dart';

import 'create_advising_controller.dart';

class CreateAdvisingBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => CreateAdvisingController());
  }
}
