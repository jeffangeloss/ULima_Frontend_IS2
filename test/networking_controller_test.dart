import 'package:flutter_test/flutter_test.dart';
import 'package:ulima_plus/models/networking_model.dart';
import 'package:ulima_plus/models/user_model.dart';
import 'package:ulima_plus/pages/networking/networking_controller.dart';
import 'package:ulima_plus/pages/networking/networking_link_launcher.dart';
import 'package:ulima_plus/services/networking_service.dart';

class _FakeGateway implements NetworkingGateway {
  _FakeGateway(this.card);

  NetworkingCardDto card;
  NetworkingCardDto? lastUpdate;

  @override
  Future<NetworkingCardDto> fetchMine() async => card;

  @override
  Future<PublicNetworkingCardDto> fetchVisibleByUserId(int userId) async =>
      PublicNetworkingCardDto(
        owner: NetworkingOwnerDto(
          userId: userId,
          fullName: 'Ana Torres',
          primaryDetail: 'Ingenieria de Sistemas',
          secondaryDetail: '$userId - Alumno',
          roleLabel: 'Alumno',
        ),
        card: card,
      );

  @override
  Future<NetworkingCardDto> updateMine(NetworkingCardDto card) async {
    lastUpdate = card;
    this.card = card;
    return card;
  }
}

class _FakeLauncher implements NetworkingLinkLauncher {
  Uri? opened;

  @override
  Future<bool> open(Uri uri) async {
    opened = uri;
    return true;
  }
}

UserModel _user({String role = 'student', String? teacherLabel}) => UserModel(
  code: '20230001',
  firstName: 'Ana',
  lastName: 'Torres',
  email: 'ana@aloe.ulima.edu.pe',
  role: role,
  teacherLabel: teacherLabel,
  currentCycle: '2026-1',
  setupComplete: true,
);

const _savedLink = SocialLinkDto(
  platform: 'linkedin',
  url: 'https://linkedin.com/in/ana',
);

void main() {
  test('switch off conserva y reenvia el enlace guardado', () async {
    final gateway = _FakeGateway(
      const NetworkingCardDto(optIn: true, links: [_savedLink]),
    );
    final controller = NetworkingController(gateway: gateway, user: _user());
    addTearDown(controller.onClose);

    await controller.load();
    controller.setOptIn(false);
    await controller.save();

    expect(gateway.lastUpdate?.optIn, isFalse);
    expect(gateway.lastUpdate?.link?.url, _savedLink.url);
  });

  test('quitar la red conserva visibilidad y envia links vacio', () async {
    final gateway = _FakeGateway(
      const NetworkingCardDto(optIn: true, links: [_savedLink]),
    );
    final controller = NetworkingController(gateway: gateway, user: _user());
    addTearDown(controller.onClose);

    await controller.load();
    controller.removeLink();
    await controller.save();

    expect(gateway.lastUpdate?.optIn, isTrue);
    expect(gateway.lastUpdate?.links, isEmpty);
  });

  test('un borrador valido llega al backend al guardar', () async {
    final gateway = _FakeGateway(
      const NetworkingCardDto(optIn: false, links: []),
    );
    final controller = NetworkingController(gateway: gateway, user: _user());
    addTearDown(controller.onClose);

    await controller.load();
    controller.startAddingLink();
    controller.setPlatform('github');
    controller.urlController.text = 'https://github.com/ana';
    await controller.save();

    expect(gateway.lastUpdate?.link?.url, 'https://github.com/ana');
  });

  test('no habilita guardar cuando no hay cambios', () async {
    final gateway = _FakeGateway(
      const NetworkingCardDto(optIn: true, links: [_savedLink]),
    );
    final controller = NetworkingController(gateway: gateway, user: _user());
    addTearDown(controller.onClose);

    await controller.load();

    expect(controller.hasUnsavedChanges, isFalse);
    expect(controller.canSave, isFalse);
  });

  test('una red guardada inicia en resumen hasta tocar editar', () async {
    final gateway = _FakeGateway(
      const NetworkingCardDto(optIn: true, links: [_savedLink]),
    );
    final controller = NetworkingController(gateway: gateway, user: _user());
    addTearDown(controller.onClose);

    await controller.load();

    expect(controller.hasLinkDraft.value, isTrue);
    expect(controller.isEditingLink.value, isFalse);

    controller.startEditingLink();

    expect(controller.isEditingLink.value, isTrue);
  });

  test('guarda carnet visible aunque no tenga red', () async {
    final gateway = _FakeGateway(
      const NetworkingCardDto(optIn: false, links: []),
    );
    final controller = NetworkingController(gateway: gateway, user: _user());
    addTearDown(controller.onClose);

    await controller.load();
    controller.setOptIn(true);
    await controller.save();

    expect(gateway.lastUpdate?.optIn, isTrue);
    expect(gateway.lastUpdate?.links, isEmpty);
  });

  test('abre el enlace que se muestra en la vista previa', () async {
    final gateway = _FakeGateway(
      const NetworkingCardDto(optIn: true, links: [_savedLink]),
    );
    final launcher = _FakeLauncher();
    final controller = NetworkingController(
      gateway: gateway,
      user: _user(),
      linkLauncher: launcher,
    );
    addTearDown(controller.onClose);

    await controller.load();
    controller.urlController.text = 'https://example.com/borrador';
    await controller.openPreviewLink();

    expect(launcher.opened.toString(), 'https://example.com/borrador');
  });

  test('presenta roles especificos de carnet sin exponer roles academicos', () {
    final gateway = _FakeGateway(
      const NetworkingCardDto(optIn: false, links: []),
    );
    final student = NetworkingController(gateway: gateway, user: _user());
    final teacher = NetworkingController(
      gateway: gateway,
      user: _user(role: 'teacher', teacherLabel: 'Profesor'),
    );
    final jp = NetworkingController(
      gateway: gateway,
      user: _user(role: 'teacher', teacherLabel: 'Jefe de Práctica'),
    );
    addTearDown(student.onClose);
    addTearDown(teacher.onClose);
    addTearDown(jp.onClose);

    expect(student.roleLabel, 'Alumno');
    expect(teacher.roleLabel, 'Docente');
    expect(jp.roleLabel, 'Jefe de Práctica');
  });

  test('muestra carrera y metadata de rol en el carnet', () {
    final gateway = _FakeGateway(
      const NetworkingCardDto(optIn: false, links: []),
    );
    final student = NetworkingController(
      gateway: gateway,
      user: _user(),
      careerLabel: 'Ingeniería de Sistemas',
    );
    final teacher = NetworkingController(
      gateway: gateway,
      user: _user(role: 'teacher', teacherLabel: 'Profesor'),
      careerLabel: 'Ingeniería de Sistemas',
    );
    final jp = NetworkingController(
      gateway: gateway,
      user: _user(role: 'teacher', teacherLabel: 'Jefe de Práctica'),
    );
    addTearDown(student.onClose);
    addTearDown(teacher.onClose);
    addTearDown(jp.onClose);

    expect(student.primaryDetail, 'Ingeniería de Sistemas');
    expect(student.secondaryDetail, '20230001 · Alumno');
    expect(teacher.primaryDetail, '');
    expect(teacher.secondaryDetail, '20230001 · Docente');
    expect(jp.primaryDetail, '');
    expect(jp.secondaryDetail, '20230001 · Jefe de Práctica');
  });
}
