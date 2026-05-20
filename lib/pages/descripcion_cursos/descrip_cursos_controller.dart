import 'package:get/get.dart';
import 'package:ulima_plus/models/anuncio_model.dart';
import 'package:ulima_plus/models/docente_model.dart';
import 'package:ulima_plus/models/seccion_model.dart';
import 'package:ulima_plus/models/user_model.dart';
import 'package:ulima_plus/services/anuncio_service.dart';
import 'package:ulima_plus/services/contacto_service.dart';
import '../../models/asesoria_model.dart';
import '../../services/asesoria_service.dart';
import '../../services/seccion_service.dart';

class DescripCursosController extends GetxController {
  //Listas
  RxList<Seccion> secciones = <Seccion>[].obs;
  RxList<Anuncio> anuncios = <Anuncio>[].obs;
  RxList<Asesoria> asesorias = <Asesoria>[].obs;
  RxList<UserModel> alumnosContacto = <UserModel>[].obs;

  //1 docente por seccion
  Rxn<Docente> docenteContacto = Rxn<Docente>();

  RxInt selectedTab = 0.obs;

  @override
  void onInit() {
    super.onInit();
    fetchSecciones();
    fetchAnuncios();
    fetchAsesorias();
    fetchContactos();
  }


  //OBTENEMOS LOS DATOS
  Future<void> fetchSecciones() async {
    final service = SeccionService();
    final data = await service.fetchSecciones();

    secciones.value = data;
  }

    Future<void> fetchAnuncios() async {
    final service = AnuncioService();
    final data = await service.fetchAnuncios();

    anuncios.value = data;
   }

    Future<void> fetchAsesorias() async {
    final service = AsesoriaService();
    final data = await service.fetchAsesorias();

    asesorias.value = data;

   }

   Future<void> fetchContactos() async {
    final service = ContactoService();
    final data = await service.fetchContactos('1'); //aqui va ID_SECCION

    //data
    docenteContacto.value = data['docente'];
    alumnosContacto.value = data['alumnos'];


   }


}
