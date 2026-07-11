// lib/pages/teacher/attendees_binding.dart

import 'package:get/get.dart';

import 'attendees_controller.dart';

class AttendeesBinding extends Bindings {
  @override
  void dependencies() {
    // fenix: true garantiza que el controlador se recrea en cada visita y que
    // onInit se vuelve a ejecutar con los nuevos Get.arguments. Sin esto, la
    // segunda visita reutilizaba el controlador anterior con el sessionId viejo
    // y la lista de alumnos quedaba vacía o mostraba datos incorrectos.
    Get.lazyPut(() => AttendeesController(), fenix: true);
  }
}
