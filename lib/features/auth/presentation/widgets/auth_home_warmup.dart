import 'package:flutter/widgets.dart';

import '../../application/auth_home_video.dart';

/// Prépare le clip de la traversée Authentification → Home dès qu'un écran
/// d'accès est affiché : à la validation, il n'y a plus qu'à le lancer.
///
/// Ne dessine rien. Mouvement réduit : aucune préparation, la transition
/// native (sans mouvement) s'applique.
class AuthHomeWarmup extends StatefulWidget {
  const AuthHomeWarmup({super.key});

  @override
  State<AuthHomeWarmup> createState() => _AuthHomeWarmupState();
}

class _AuthHomeWarmupState extends State<AuthHomeWarmup> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!MediaQuery.disableAnimationsOf(context)) AuthHomeVideoWarmup.start();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
