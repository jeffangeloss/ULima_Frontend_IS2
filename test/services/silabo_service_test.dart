// test/services/silabo_service_test.dart
// HU21: SilaboService descarga el PDF del sílabo SIN tocar la red real
// (MockClient de package:http/testing). Cubre el hallazgo clave de los
// permisos mixtos de Drive: un 200 con HTML de login NO es un sílabo
// accesible; solo un cuerpo con firma %PDF pasa al visor.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ulima_plus/domain/silabo/silabo_link.dart';
import 'package:ulima_plus/services/silabo_service.dart';

/// PDF mínimo válido para los tests (empieza con la firma %PDF).
final Uint8List _pdfBytes =
    Uint8List.fromList(utf8.encode('%PDF-1.4\n1 0 obj\n<<>>\nendobj\n%%EOF'));

const String _htmlLogin =
    '<!DOCTYPE html><html><head><title>Google Accounts</title></head>'
    '<body>Sign in to continue</body></html>';

final SilaboLink _link = SilaboLink.tryParse(
  'https://drive.google.com/file/d/1BuUpjrmbC-u0pWRZRTW6MHtRgI-RkZcU/view',
)!;

void main() {
  late Directory tempDir;
  late int requestCount;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('silabo_service_test');
    requestCount = 0;
  });

  tearDown(() async {
    if (tempDir.existsSync()) await tempDir.delete(recursive: true);
  });

  SilaboService buildService(http.Response Function(http.Request) handler) {
    return SilaboService(
      httpClientFactory: () => MockClient((request) async {
        requestCount++;
        return handler(request);
      }),
      cacheDirProvider: () async => tempDir,
    );
  }

  test('200 con binario %PDF devuelve los bytes y pide la URL de descarga',
      () async {
    late Uri requestedUri;
    final service = buildService((request) {
      requestedUri = request.url;
      return http.Response.bytes(_pdfBytes, 200);
    });

    final bytes = await service.obtenerPdf(_link);

    expect(SilaboService.esFirmaPdf(bytes), isTrue);
    expect(bytes, equals(_pdfBytes));
    expect(requestedUri.toString(), _link.downloadUrl);
  });

  test('reapertura usa la caché por fileId (no vuelve a llamar a la red)',
      () async {
    final service = buildService((_) => http.Response.bytes(_pdfBytes, 200));

    final primera = await service.obtenerPdf(_link);
    final segunda = await service.obtenerPdf(_link);

    expect(primera, equals(_pdfBytes));
    expect(segunda, equals(_pdfBytes));
    expect(requestCount, 1);
    expect(
      File('${tempDir.path}/silabos/${_link.fileId}.pdf').existsSync(),
      isTrue,
    );
  });

  test('forzarDescarga ignora la caché (botón Reintentar)', () async {
    final service = buildService((_) => http.Response.bytes(_pdfBytes, 200));

    await service.obtenerPdf(_link);
    await service.obtenerPdf(_link, forzarDescarga: true);

    expect(requestCount, 2);
  });

  test(
      '200 con HTML de login de Google (permisos mixtos) '
      '→ SilaboNoAccesibleException', () async {
    final service = buildService(
      (_) => http.Response(
        _htmlLogin,
        200,
        headers: {'content-type': 'text/html; charset=utf-8'},
      ),
    );

    await expectLater(
      service.obtenerPdf(_link),
      throwsA(isA<SilaboNoAccesibleException>()),
    );
    // La respuesta inválida NO debe quedar cacheada como PDF.
    expect(
      File('${tempDir.path}/silabos/${_link.fileId}.pdf').existsSync(),
      isFalse,
    );
  });

  test('HTTP 404 → SilaboDescargaException', () async {
    final service = buildService((_) => http.Response('Not Found', 404));

    await expectLater(
      service.obtenerPdf(_link),
      throwsA(isA<SilaboDescargaException>()),
    );
  });

  test('falla de red (ClientException) → SilaboDescargaException', () async {
    final service = SilaboService(
      httpClientFactory: () => MockClient((_) async {
        throw http.ClientException('Connection refused');
      }),
      cacheDirProvider: () async => tempDir,
    );

    await expectLater(
      service.obtenerPdf(_link),
      throwsA(isA<SilaboDescargaException>()),
    );
  });

  test('cuerpo de más de 25MB → SilaboDemasiadoGrandeException', () async {
    final huge = Uint8List(SilaboService.maxPdfBytes + 1);
    huge.setRange(0, 4, utf8.encode('%PDF'));
    final service = buildService((_) => http.Response.bytes(huge, 200));

    await expectLater(
      service.obtenerPdf(_link),
      throwsA(isA<SilaboDemasiadoGrandeException>()),
    );
  });

  test('caché corrupta (sin firma %PDF) se descarta y se re-descarga',
      () async {
    final cacheFile = File('${tempDir.path}/silabos/${_link.fileId}.pdf');
    cacheFile.createSync(recursive: true);
    cacheFile.writeAsStringSync(_htmlLogin);

    final service = buildService((_) => http.Response.bytes(_pdfBytes, 200));

    final bytes = await service.obtenerPdf(_link);

    expect(bytes, equals(_pdfBytes));
    expect(requestCount, 1);
    // La caché queda reparada con el PDF válido.
    expect(SilaboService.esFirmaPdf(cacheFile.readAsBytesSync()), isTrue);
  });

  test('esFirmaPdf distingue PDF de HTML/vacío', () {
    expect(SilaboService.esFirmaPdf(_pdfBytes), isTrue);
    expect(SilaboService.esFirmaPdf(utf8.encode(_htmlLogin)), isFalse);
    expect(SilaboService.esFirmaPdf([]), isFalse);
    expect(SilaboService.esFirmaPdf(utf8.encode('%PD')), isFalse);
  });
}
