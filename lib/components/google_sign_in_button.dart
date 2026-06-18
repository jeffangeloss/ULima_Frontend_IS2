import 'package:flutter/widgets.dart';

// Import condicional: en web usa el botón oficial de Google (GIS);
// en móvil/escritorio usa el stub (no se renderiza, se usa el botón propio).
import 'google_sign_in_button_stub.dart'
    if (dart.library.html) 'google_sign_in_button_web.dart' as platform;

/// Botón oficial de Google Identity Services. Solo se renderiza en web
/// (en `google_sign_in` 6.x, `signIn()` no funciona en web → se requiere
/// `renderButton`). En móvil devuelve un widget vacío.
Widget googleSignInButton() => platform.googleSignInButton();
