import 'package:flutter/widgets.dart';
import 'package:google_sign_in_web/web_only.dart' as gsi_web;

/// Renderiza el botón oficial de Google (GIS) para web. Al hacer clic,
/// dispara el flujo de Google y emite la cuenta vía
/// `GoogleSignIn.onCurrentUserChanged` (lo escucha el LoginController).
Widget googleSignInButton() => gsi_web.renderButton();
