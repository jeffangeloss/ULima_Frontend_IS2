import 'package:flutter/widgets.dart';

/// Stub para plataformas no-web: en móvil se usa el botón propio que llama a
/// `GoogleSignIn.signIn()`, así que aquí no se renderiza nada.
Widget googleSignInButton() => const SizedBox.shrink();
