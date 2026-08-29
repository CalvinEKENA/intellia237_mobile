import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/network_status.dart';

class NetworkStatusBanner extends ConsumerWidget {
  const NetworkStatusBanner({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offline = ref.watch(isOfflineProvider);
    return Stack(
      children: [
        child,
        Positioned(
          top: MediaQuery.paddingOf(context).top,
          left: 12,
          right: 12,
          child: IgnorePointer(
            ignoring: !offline,
            child: AnimatedSlide(
              offset: offline ? Offset.zero : const Offset(0, -1.6),
              duration: const Duration(milliseconds: 220),
              child: AnimatedOpacity(
                opacity: offline ? 1 : 0,
                duration: const Duration(milliseconds: 180),
                child: Material(
                  color: const Color(0xFF3A2A00),
                  elevation: 4,
                  borderRadius: BorderRadius.circular(14),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.cloud_off_rounded,
                          color: Color(0xFFFFD18B),
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Aucun réseau détecté — les contenus déjà chargés restent accessibles.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
