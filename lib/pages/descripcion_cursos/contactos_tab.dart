import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../components/descripcion_cursos/contacto_card.dart';
import '../../components/error_retry.dart';
import '../../components/skeleton.dart';
import 'descrip_cursos_controller.dart';

class ContactosTab extends StatelessWidget {
  final String idSeccion;
  final DescripCursosController control = Get.find();

  ContactosTab({super.key, required this.idSeccion});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Obx(() {
      if (control.isLoading.value &&
          control.docenteContacto.value == null &&
          control.alumnosContacto.isEmpty) {
        return const SkeletonCardList(count: 4, padding: EdgeInsets.all(16));
      }
      // Un fallo de carga se muestra como error con reintentar, no como una
      // lista de contactos vacía (que parecía una sección sin alumnos/docente).
      if (control.contactosError.value &&
          control.docenteContacto.value == null &&
          control.alumnosContacto.isEmpty) {
        return ErrorRetry(
          compact: true,
          title: 'No se pudieron cargar los contactos',
          onRetry: () => control.fetchContactos(idSeccion),
        );
      }
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        children: [
          Text(
            'DOCENTE',
            style: TextStyle(
              color: colors.secondary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          if (control.docenteContacto.value != null)
            ContactoCard(
              nombres: control.docenteContacto.value!.firstName,
              apellidos: control.docenteContacto.value!.lastName,
              rol: 'docente',
            ),
          // HU18: grupo Jefe de Práctica (solo si la sección tiene JP).
          if (control.jpContacto.value != null) ...[
            const SizedBox(height: 22),
            Text(
              'JEFE DE PRÁCTICA',
              style: TextStyle(
                color: colors.secondary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            ContactoCard(
              nombres: control.jpContacto.value!.firstName,
              apellidos: control.jpContacto.value!.lastName,
              rol: 'jp',
            ),
          ],
          const SizedBox(height: 22),
          Text(
            'ALUMNOS',
            style: TextStyle(
              color: colors.secondary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          ...control.alumnosContacto.map((contacto) {
            final user = contacto.user;
            final role = contacto.roleInSection;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ContactoCard(
                nombres: user.firstName,
                apellidos: user.lastName,
                rol: role,
              ),
            );
          }),
        ],
      );
    });
  }
}
