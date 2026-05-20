import 'package:flutter/material.dart';

class ContactoCard
    extends StatelessWidget {

  final String nombre;
  final String rol;

  const ContactoCard({
    super.key,
    required this.nombre,
    required this.rol,
  });

  @override
  Widget build(
    BuildContext context,
  ) {

    final colors =
        Theme.of(context)
            .colorScheme;

    // Inicial nombre
    final inicial =
        nombre[0]
            .toUpperCase();

    return Container(

      width: double.infinity,

      padding:
          const EdgeInsets.all(16),

      decoration: BoxDecoration(

        // MISMO ESTILO
        // QUE TUS DEMÁS CARDS
        color: colors.surface,

        borderRadius:
            BorderRadius.circular(18),

        border: Border.all(
          color: colors.outline,
          width: 0.5,
        ),
      ),

      child: Row(

        children: [

          // Avatar
          Container(

            width: 72,
            height: 72,

            decoration: BoxDecoration(

              color:
                  colors.surfaceContainerHighest,

              shape:
                  BoxShape.circle,
            ),

            child: Center(

              child: Text(

                inicial,

                style: TextStyle(

                  color:
                      colors.onSurface,

                  fontSize: 30,

                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ),
          ),

          const SizedBox(width: 18),

          // Información
          Expanded(

            child: Column(

              crossAxisAlignment:
                  CrossAxisAlignment.start,

              mainAxisAlignment:
                  MainAxisAlignment.center,

              children: [

                // Nombre
                Text(

                  nombre.toUpperCase(),

                  style: TextStyle(

                    color:
                        colors.primary,

                    fontSize: 16,

                    fontWeight:
                        FontWeight.w700,
                  ),
                ),

                // Rol
                if (
                    rol ==
                        'delegado' ||
                    rol ==
                        'subdelegado'
                )

                  Padding(

                    padding:
                        const EdgeInsets.only(
                      top: 4,
                    ),

                    child: Text(

                      rol == 'delegado'
                          ? 'Delegado'
                          : 'Subdelegado',

                      style: const TextStyle(

                        color:
                            Color.fromARGB(
                              255,
                              255,
                              119,
                              65,
                            ),

                        fontSize: 14,

                        fontWeight:
                            FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}