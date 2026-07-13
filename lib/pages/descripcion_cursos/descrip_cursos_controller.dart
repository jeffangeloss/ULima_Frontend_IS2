import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:ulima_plus/models/anuncio_model.dart';
import 'package:ulima_plus/models/asesoria_model.dart';
import 'package:ulima_plus/models/contacto_model.dart';
import 'package:ulima_plus/models/docente_model.dart';
import 'package:ulima_plus/models/seccion_model.dart';
import 'package:ulima_plus/services/anuncio_service.dart';
import 'package:ulima_plus/services/asesoria_service.dart';
import 'package:ulima_plus/services/contacto_service.dart';
import 'package:ulima_plus/services/seccion_service.dart';
import 'package:ulima_plus/pages/horario/horario_controller.dart';

class DescripCursosController extends GetxController {
  final SeccionService _seccionService = SeccionService();
  final AnuncioService _anuncioService = AnuncioService();
  final AsesoriaService _asesoriaService;
  final ContactoService _contactoService = ContactoService();

  // HU17: `asesoriaService` es inyectable para pruebas (por defecto la real).
  DescripCursosController({AsesoriaService? asesoriaService})
      : _asesoriaService = asesoriaService ?? AsesoriaService();

  RxList<Seccion> secciones = <Seccion>[].obs;
  Rxn<Seccion> seccionActual = Rxn<Seccion>();
  RxList<Anuncio> anuncios = <Anuncio>[].obs;
  RxList<Asesoria> asesorias = <Asesoria>[].obs;
  RxList<ContactoCurso> alumnosContacto = <ContactoCurso>[].obs;
  Rxn<Docente> docenteContacto = Rxn<Docente>();
  Rxn<Docente> jpContacto = Rxn<Docente>(); // HU18: jefe de práctica (0 o 1)
  RxInt selectedTab = 0.obs;
  RxBool isLoading = false.obs;

  Seccion? getSeccionPorId(String id) {
    return secciones.firstWhereOrNull((s) => s.idSeccion == id);
  }

  Future<void> cargarDatosCurso(String idSeccion) async {
    try {
      isLoading.value = true;
      Seccion? seccion;

      // 1. Primero intentamos rescatar la data desde el HorarioController
      // porque contiene la asistencia REAL y específica del usuario autenticado.
      if (Get.isRegistered<HorarioController>()) {
        final hCtrl = Get.find<HorarioController>();
        final courseData = hCtrl.uniqueEnrolledCourses.firstWhereOrNull(
          (c) => c['idSeccion']?.toString() == idSeccion
        );
        if (courseData != null) {
          seccion = Seccion.fromJson(courseData);
        }
      }

      // 2. Fallback: Si no se encontró, llamamos al endpoint de detalle general.
      seccion ??= await _seccionService.findSectionById(idSeccion);

      if (seccion == null) {
        throw Exception('No existe seccion con id $idSeccion');
      }

      seccionActual.value = seccion;
      secciones.value = [seccion];

      // Cada tab se carga por separado: si UNO falla, los otros igual cargan
      // (antes un fallo en cualquiera disparaba limpiarDatos y borraba todo).
      await Future.wait([
        fetchAnuncios(idSeccion).catchError((e) => debugPrint('anuncios falló: $e')),
        fetchAsesorias(idSeccion).catchError((e) => debugPrint('asesorías falló: $e')),
        fetchContactos(idSeccion).catchError((e) => debugPrint('contactos falló: $e')),
      ]);
    } catch (e) {
      debugPrint('Error cargando datos del curso: $e');
      limpiarDatos();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchAnuncios(String idSeccion) async {
    final data = await _anuncioService.fetchAnuncios(idSeccion);
    anuncios.value = data;
  }

  Future<void> fetchAsesorias(String idSeccion) async {
    final data = await _asesoriaService.fetchAsesorias(idSeccion);
    asesorias.value = data;
  }

  // HU17: confirma/cancela la asistencia con actualización optimista del contador.
  // Si el backend falla, revierte al estado previo y avisa. Idempotente: si otra
  // request ya está en curso para esa asesoría, se ignora el tap.
  final RxSet<String> rsvpEnCurso = <String>{}.obs;

  Future<void> toggleRsvp(Asesoria asesoria) async {
    if (rsvpEnCurso.contains(asesoria.id)) return;

    final index = asesorias.indexWhere((a) => a.id == asesoria.id);
    if (index == -1) return;

    final previa = asesorias[index];
    final quiereAsistir = !previa.myRsvp;

    // 1) Optimista: reflejar el cambio en la UI de inmediato.
    final asistentesOptimista =
        (previa.asistentes + (quiereAsistir ? 1 : -1)).clamp(0, 1 << 31);
    asesorias[index] =
        previa.copyWith(myRsvp: quiereAsistir, asistentes: asistentesOptimista);
    rsvpEnCurso.add(asesoria.id);

    try {
      final res = quiereAsistir
          ? await _asesoriaService.confirmarAsistencia(asesoria.id)
          : await _asesoriaService.cancelarAsistencia(asesoria.id);

      // 2) Reconciliar con el conteo autoritativo del backend.
      final actual = asesorias.indexWhere((a) => a.id == asesoria.id);
      if (actual != -1) {
        asesorias[actual] = asesorias[actual]
            .copyWith(myRsvp: res.myRsvp, asistentes: res.asistentes);
      }
    } catch (e) {
      // 3) Rollback al estado previo.
      final actual = asesorias.indexWhere((a) => a.id == asesoria.id);
      if (actual != -1) asesorias[actual] = previa;
      debugPrint('Error en RSVP de asesoría ${asesoria.id}: $e');
      Get.snackbar(
        'No se pudo actualizar',
        quiereAsistir
            ? 'No pudimos confirmar tu asistencia. Inténtalo de nuevo.'
            : 'No pudimos cancelar tu asistencia. Inténtalo de nuevo.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      rsvpEnCurso.remove(asesoria.id);
    }
  }

  Future<void> fetchContactos(String idSeccion) async {
    final data = await _contactoService.fetchContactos(idSeccion);
    docenteContacto.value = data['docente'] as Docente?;
    jpContacto.value = data['jefePractica'] as Docente?;
    alumnosContacto.value = List<ContactoCurso>.from(data['alumnos'] ?? []);
  }

  void limpiarDatos() {
    secciones.clear();
    seccionActual.value = null;
    anuncios.clear();
    asesorias.clear();
    alumnosContacto.clear();
    docenteContacto.value = null;
    jpContacto.value = null;
  }
}
