import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ulima_plus/components/networking/networking_card_preview.dart';
import 'package:ulima_plus/models/networking_model.dart';

void main() {
  testWidgets('renderiza dentro de un scroll sin errores de flex', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: NetworkingCardPreview(
              fullName: 'Ana Torres',
              primaryDetail: 'Ingeniería de Sistemas',
              secondaryDetail: '20230001 · Alumno',
              optIn: true,
              link: const SocialLinkDto(
                platform: 'linkedin',
                url: 'https://linkedin.com/in/ana',
              ),
              onOpenLink: () {},
            ),
          ),
        ),
      ),
    );

    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('CARNET DE NETWORKING'), findsOneWidget);
    expect(find.text('Ana Torres'), findsOneWidget);
    expect(find.text('Ingeniería de Sistemas'), findsOneWidget);
    expect(find.text('Probar enlace'), findsOneWidget);
  });
}
