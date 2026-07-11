import 'package:flutter/widgets.dart';
import 'package:google_sign_in_web/web_only.dart' as gsi_web;

/// Renderiza el botón oficial de Google (GIS) para web. Al hacer clic,
/// dispara el flujo de Google y emite la cuenta vía
/// `GoogleSignIn.onCurrentUserChanged` (lo escucha el LoginController).
///
/// Se usa [_GoogleSignInButtonWeb] con una GlobalKey fija para que Flutter
/// no destruya y vuelva a crear el HtmlElementView que contiene el botón
/// nativo del SDK. Esto evita el warning de GIS:
/// "google.accounts.id.initialize() is called multiple times".
Widget googleSignInButton() => const _GoogleSignInButtonWeb();

class _GoogleSignInButtonWeb extends StatefulWidget {
  const _GoogleSignInButtonWeb();

  @override
  State<_GoogleSignInButtonWeb> createState() => _GoogleSignInButtonWebState();
}

class _GoogleSignInButtonWebState extends State<_GoogleSignInButtonWeb> {
  /// El widget de botón GIS se crea una sola vez y se reutiliza para que
  /// el SDK no llame a `initialize()` en cada rebuild.
  late final Widget _button;

  @override
  void initState() {
    super.initState();
    _button = gsi_web.renderButton();
  }

  @override
  Widget build(BuildContext context) => _button;
}
