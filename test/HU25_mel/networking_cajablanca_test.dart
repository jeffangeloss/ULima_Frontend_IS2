// test/HU25_mel/networking_cajablanca_test.dart
//
// CAJA BLANCA - HU25 NetworkingController.
// Caminos:
//   C1 load OK -> ready y estado persistido.
//   C2 setOptIn cambia hasUnsavedChanges.
//   C3 save visible sin link envia links [].
//   C4 link invalido no llama backend.
//   C5 openPreviewLink abre el link persistido.

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
  int updateCalls = 0;

  @override
  Future<NetworkingCardDto> fetchMine() async => card;

  @override
  Future<PublicNetworkingCardDto> fetchVisibleByUserId(int userId) async =>
      PublicNetworkingCardDto(
        owner: NetworkingOwnerDto(
          userId: userId,
          fullName: 'Ana Torres',
          primaryDetail: 'Ingenieria',
          secondaryDetail: '$userId - Alumno',
          roleLabel: 'Alumno',
        ),
        card: card,
      );

  @override
  Future<NetworkingCardDto> updateMine(NetworkingCardDto card) async {
    updateCalls++;
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

UserModel _user() => UserModel(
  code: '20230001',
  firstName: 'Ana',
  lastName: 'Torres',
  email: '20230001@aloe.ulima.edu.pe',
  role: 'student',
  currentCycle: '2026-1',
  setupComplete: true,
);

const _link = SocialLinkDto(platform: 'github', url: 'https://github.com/ana');

void main() {
  group('CAJA BLANCA · HU25 NetworkingController', () {
    test('C1: load OK deja status ready y sin cambios pendientes', () async {
      final controller = NetworkingController(
        gateway: _FakeGateway(
          const NetworkingCardDto(optIn: true, links: [_link]),
        ),
        user: _user(),
      );
      addTearDown(controller.onClose);

      await controller.load();

      expect(controller.status.value, NetworkingViewStatus.ready);
      expect(controller.hasUnsavedChanges, isFalse);
    });

    test('C2: cambiar optIn marca cambios pendientes', () async {
      final controller = NetworkingController(
        gateway: _FakeGateway(
          const NetworkingCardDto(optIn: true, links: [_link]),
        ),
        user: _user(),
      );
      addTearDown(controller.onClose);

      await controller.load();
      controller.setOptIn(false);

      expect(controller.hasUnsavedChanges, isTrue);
    });

    test('C3: guardar visible sin link envia links vacio', () async {
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

    test('C4: link invalido no llama backend y muestra mensaje', () async {
      final gateway = _FakeGateway(
        const NetworkingCardDto(optIn: false, links: []),
      );
      final controller = NetworkingController(gateway: gateway, user: _user());
      addTearDown(controller.onClose);

      await controller.load();
      controller.startAddingLink();
      controller.urlController.text = 'github.com/ana';
      await controller.save();

      expect(gateway.updateCalls, 0);
      expect(controller.saveMessage.value, contains('http'));
    });

    test('C5: abre el link persistido de preview', () async {
      final launcher = _FakeLauncher();
      final controller = NetworkingController(
        gateway: _FakeGateway(
          const NetworkingCardDto(optIn: true, links: [_link]),
        ),
        user: _user(),
        linkLauncher: launcher,
      );
      addTearDown(controller.onClose);

      await controller.load();
      await controller.openPreviewLink();

      expect(launcher.opened.toString(), _link.url);
    });
  });
}
