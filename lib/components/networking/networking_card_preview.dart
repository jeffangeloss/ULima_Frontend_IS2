import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../models/networking_model.dart';
import 'networking_platform_presentation.dart';

class NetworkingCardPreview extends StatelessWidget {
  const NetworkingCardPreview({
    super.key,
    required this.fullName,
    required this.primaryDetail,
    required this.secondaryDetail,
    required this.optIn,
    required this.link,
    required this.onOpenLink,
  });

  final String fullName;
  final String primaryDetail;
  final String secondaryDetail;
  final bool optIn;
  final SocialLinkDto? link;
  final VoidCallback onOpenLink;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 320,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFF7A1A), Color(0xFFD94E00)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF6600).withValues(alpha: 0.22),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            right: -74,
            top: -80,
            child: _DecorativeCircle(
              size: 210,
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          Positioned(
            left: -86,
            bottom: -105,
            child: _DecorativeCircle(
              size: 250,
              color: const Color(0xFF8D2D00).withValues(alpha: 0.18),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: SvgPicture.asset(
                        'assets/images/Universidad_de_Lima_logo.svg',
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'UNIVERSIDAD\nDE LIMA',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          height: 1.05,
                          letterSpacing: 0.8,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.17),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.34),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            optIn
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: Colors.white,
                            size: 14,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            optIn ? 'Visible' : 'Oculto',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                const Text(
                  'CARNET DE NETWORKING',
                  style: TextStyle(
                    color: Color(0xFFFFE2D1),
                    fontSize: 11,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  fullName.isEmpty ? 'Usuario ULima' : fullName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    height: 1.08,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                if (primaryDetail.isNotEmpty)
                  Text(
                    primaryDetail,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFFFE9DD),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                if (secondaryDetail.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    secondaryDetail,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFFFD4BC),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                Divider(color: Colors.white.withValues(alpha: 0.34)),
                const SizedBox(height: 6),
                if (link == null)
                  const Row(
                    children: [
                      Icon(
                        Icons.add_link_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          'Agrega una red para compartir tu carnet',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onOpenLink,
                      borderRadius: BorderRadius.circular(14),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 7),
                        child: Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(11),
                              ),
                              child: Icon(
                                networkingPlatformIcon(link!.platform),
                                color: const Color(0xFFD94E00),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 11),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    link!.label ??
                                        networkingPlatformLabel(link!.platform),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const Text(
                                    'Probar enlace',
                                    style: TextStyle(
                                      color: Color(0xFFFFE2D1),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.open_in_new_rounded,
                              color: Colors.white,
                              size: 19,
                            ),
                          ],
                        ),
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

class _DecorativeCircle extends StatelessWidget {
  const _DecorativeCircle({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}
