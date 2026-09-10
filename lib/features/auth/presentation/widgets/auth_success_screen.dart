import 'package:flutter/material.dart';

import '../../../../core/localization/localization_extensions.dart';
import '../../domain/app_role.dart';
import 'auth_controls.dart';
import 'auth_experience_scaffold.dart';
import 'living_pass.dart';

/// The completed PASS is the source of the shared-element flight into home.
/// Navigation starts on the tap; the destination owns the entire transition.
class AuthSuccessScreen extends StatefulWidget {
  const AuthSuccessScreen({
    required this.firstName,
    required this.companionName,
    required this.companionAsset,
    required this.onContinue,
    super.key,
  });

  final String firstName;
  final String companionName;
  final String companionAsset;
  final VoidCallback onContinue;

  @override
  State<AuthSuccessScreen> createState() => _AuthSuccessScreenState();
}

class _AuthSuccessScreenState extends State<AuthSuccessScreen> {
  bool _opening = false;

  void _continue() {
    if (_opening) return;
    setState(() => _opening = true);
    widget.onContinue();
  }

  @override
  Widget build(BuildContext context) => AuthExperienceScaffold(
    showBackButton: false,
    child: LayoutBuilder(
      builder: (context, constraints) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 32),
          AuthHeader(
            showBrand: false,
            eyebrow: context.l10n.passRegistrationComplete,
            title: context.l10n.passYourPlaceIsReady,
            subtitle: '',
            titleWidget: Text(
              context.l10n.passYourPlaceIsReady,
              style: passDisplay(size: constraints.maxWidth < 330 ? 64 : 82),
            ),
          ),
          const SizedBox(height: 32),
          LivingPass(
            role: AppRole.student,
            name: widget.firstName,
            detail: context.l10n.passWithCompanion(widget.companionName),
            companionAsset: widget.companionAsset,
            progress: 1,
            verified: true,
          ),
          const SizedBox(height: 28),
          Text(
            context.l10n.welcomeName(widget.firstName),
            style: passDisplay(size: 31),
          ),
          const SizedBox(height: 10),
          Text(
            context.l10n.accountReadyWithCompanion(widget.companionName),
            style: const TextStyle(
              fontFamily: 'CampaignBody',
              fontSize: 14,
              height: 1.5,
              color: AuthExperienceColors.textSecondary,
            ),
          ),
          const SizedBox(height: 28),
          AuthPrimaryButton(
            label: context.l10n.discoverIntellia,
            onTap: _opening ? null : _continue,
            icon: Icons.north_east_rounded,
          ),
          const SizedBox(height: 24),
        ],
      ),
    ),
  );
}
