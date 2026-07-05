import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../components/descripcion_cursos/asesoria_card.dart';
import '../../components/descripcion_cursos/empty_tab_state.dart';
import '../../components/skeleton.dart';
import 'descrip_cursos_controller.dart';

class AsesoriasTab extends StatelessWidget {
  final String idSeccion;
  final DescripCursosController control = Get.find();

  AsesoriasTab({super.key, required this.idSeccion});

  Widget _buildBody(BuildContext context) {
    return Obx(() {
      if (control.isLoading.value && control.asesorias.isEmpty) {
        return const SkeletonCardList(
          count: 3,
          padding: EdgeInsets.fromLTRB(16, 4, 16, 16),
          showAvatar: false,
        );
      }
      if (control.asesorias.isEmpty) {
        return const EmptyTabState(
          icon: Icons.videocam_outlined,
          title: 'Aún no hay asesorías programadas',
          message:
              'Todavía no hay horarios de asesoría publicados. Cuando el docente los comparta, podrás verlos aquí.',
        );
      }

      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: ListView.builder(
          padding: EdgeInsets.zero,
          itemCount: control.asesorias.length,
          itemBuilder: (context, index) {
            final asesoria = control.asesorias[index];

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: CardAsesoria(asesoria: asesoria),
            );
          },
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return _buildBody(context);
  }
}
