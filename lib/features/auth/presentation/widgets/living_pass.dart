import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../../../../core/localization/localization_extensions.dart';
import '../../domain/app_role.dart';
import 'auth_experience_scaffold.dart';
import 'intellia_237_membrane.dart';

String passRoleLabel(BuildContext context, AppRole? role) => switch (role) {
  AppRole.student => context.l10n.studentRole,
  AppRole.parent => context.l10n.parentRole,
  AppRole.teacher => context.l10n.teacherRole,
  AppRole.admin => context.l10n.adminRole,
  null => context.l10n.passYourSpace,
};

TextStyle passDisplay({double size = 48, Color? color}) => TextStyle(
  fontFamily: 'BarlowCondensed',
  fontSize: size,
  fontWeight: FontWeight.w800,
  height: 0.98,
  letterSpacing: -0.25,
  color: color ?? AuthExperienceColors.textPrimary,
);

/// One physical object across entry, profile creation and the home header.
/// Decorative engraving contains no identifier, secret or biometric data.
/// Whether the Pass has to make room for the form.
///
/// `Scaffold(resizeToAvoidBottomInset: true)` consumes the keyboard inset
/// before the Pass can see it, so the card's own `viewInsets` check never
/// fires under a scaffold. The decision is therefore taken where the
/// remaining height is actually known, and carried down.
class PassRoom extends InheritedWidget {
  const PassRoom({required this.tight, required super.child, super.key});

  final bool tight;

  /// Below this, the full card would leave too little room to type.
  static const threshold = 620.0;

  static bool of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<PassRoom>()?.tight ?? false;

  @override
  bool updateShouldNotify(PassRoom oldWidget) => tight != oldWidget.tight;
}

class LivingPass extends StatelessWidget {
  const LivingPass({
    this.role,
    this.name,
    this.detail,
    this.companionAsset,
    this.phase,
    this.progress = 0,
    this.verified = false,
    this.compact = false,
    this.heroEnabled = true,
    super.key,
  });

  static const heroTag = 'intellia-living-pass';
  final AppRole? role;
  final String? name;
  final String? detail;
  final String? companionAsset;
  final String? phase;
  final double progress;
  final bool verified;
  final bool compact;
  final bool heroEnabled;

  @override
  Widget build(BuildContext context) {
    final small =
        compact ||
        PassRoom.of(context) ||
        MediaQuery.viewInsetsOf(context).bottom > 0;
    final reduced = MediaQuery.disableAnimationsOf(context);
    final surface = _PassSurface(
      name: name?.trim().isNotEmpty == true ? name!.trim() : null,
      role: passRoleLabel(context, role),
      roleChosen: role != null,
      detail: detail,
      asset: companionAsset,
      phase:
          phase ??
          (verified
              ? context.l10n.passPassReady
              : context.l10n.passTakingShape),
      emptyName: context.l10n.passAPlaceForYou,
      readyLabel: context.l10n.passPassReady,
      progress: progress.clamp(0, 1),
      verified: verified,
      expansion: small ? 0 : 1,
    );
    final card = heroEnabled
        ? Hero(
            tag: heroTag,
            createRectTween: (begin, end) =>
                MaterialRectArcTween(begin: begin, end: end),
            flightShuttleBuilder: (_, animation, direction, from, to) {
              final source = (from.widget as Hero).child as _PassSurface;
              final target = (to.widget as Hero).child as _PassSurface;
              return AnimatedBuilder(
                animation: animation,
                builder: (context, _) {
                  final raw = direction == HeroFlightDirection.push
                      ? animation.value
                      : 1 - animation.value;
                  final t = Curves.easeInOutCubic.transform(raw);
                  return target.withExpansion(
                    lerpDouble(source.expansion, target.expansion, t)!,
                  );
                },
              );
            },
            child: surface,
          )
        : surface;
    if (reduced) return card;
    return AnimatedSize(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeInOutCubic,
      alignment: Alignment.topCenter,
      child: card,
    );
  }
}

class _PassSurface extends StatelessWidget {
  const _PassSurface({
    required this.name,
    required this.role,
    required this.roleChosen,
    required this.detail,
    required this.asset,
    required this.phase,
    required this.emptyName,
    required this.readyLabel,
    required this.progress,
    required this.verified,
    required this.expansion,
  });

  final String? name;
  final String role;
  final bool roleChosen;
  final String? detail;
  final String? asset;
  final String phase;
  final String emptyName;
  final String readyLabel;
  final double progress;
  final bool verified;
  final double expansion;

  _PassSurface withExpansion(double value) => _PassSurface(
    name: name,
    role: role,
    roleChosen: roleChosen,
    detail: detail,
    asset: asset,
    phase: phase,
    emptyName: emptyName,
    readyLabel: readyLabel,
    progress: progress,
    verified: verified,
    expansion: value,
  );

  @override
  Widget build(BuildContext context) {
    final e = expansion;
    final ink = AuthExperienceColors.textPrimary;
    return Material(
      color: AuthExperienceColors.surfaceSoft,
      borderRadius: BorderRadius.circular(lerpDouble(8, 16, e)!),
      clipBehavior: Clip.antiAlias,
      child: CustomPaint(
        foregroundPainter: _PassEngraving(progress: progress, expansion: e),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: lerpDouble(16, 22, e)!,
            vertical: lerpDouble(12, 20, e)!,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'INTELLIA PASS',
                        key: const ValueKey('living-pass-brand'),
                        style: passDisplay(
                          size: lerpDouble(18, 47, e)!,
                          color: e < 0.5 ? AuthExperienceColors.indigo : ink,
                        ),
                      ),
                    ),
                    SizedBox(height: lerpDouble(4, 21, e)!),
                    Text(
                      name ?? emptyName,
                      key: const ValueKey('living-pass-name'),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: passDisplay(size: lerpDouble(27, 31, e)!),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      [
                        if (roleChosen) role,
                        if (detail?.trim().isNotEmpty == true) detail!.trim(),
                        if (!roleChosen && detail?.trim().isNotEmpty != true)
                          'INTELLIA 237',
                      ].join('  ·  '),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'CampaignBody',
                        fontSize: 11,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                        color: AuthExperienceColors.textSecondary,
                      ),
                    ),
                    if (e > 0)
                      ClipRect(
                        child: Align(
                          heightFactor: e,
                          alignment: Alignment.topLeft,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 20),
                            child: Opacity(
                              opacity: e,
                              child: Text(
                                phase.toUpperCase(),
                                style: TextStyle(
                                  fontFamily: 'CampaignBody',
                                  fontSize: 9,
                                  letterSpacing: 1.5,
                                  fontWeight: FontWeight.w800,
                                  color: verified
                                      ? AuthExperienceColors.success
                                      : AuthExperienceColors.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(width: lerpDouble(10, 16, e)!),
              SizedBox(
                width: lerpDouble(42, 74, e)!,
                height: lerpDouble(52, 102, e)!,
                child: asset == null
                    ? ExcludeSemantics(
                        child: Intellia237Membrane(
                          progress: progress,
                          verified: verified,
                        ),
                      )
                    : Image.asset(
                        asset!,
                        fit: BoxFit.contain,
                        excludeFromSemantics: true,
                        errorBuilder: (_, _, _) => ExcludeSemantics(
                          child: Intellia237Membrane(
                            progress: progress,
                            verified: verified,
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PassEngraving extends CustomPainter {
  const _PassEngraving({required this.progress, required this.expansion});
  final double progress;
  final double expansion;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AuthExperienceColors.border
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    final border = RRect.fromRectAndRadius(
      (Offset.zero & size).deflate(0.5),
      Radius.circular(lerpDouble(8, 16, expansion)!),
    );
    canvas.drawRRect(border, paint);
    final inset = lerpDouble(16, 22, expansion)!;
    final start = Offset(inset, size.height - 5);
    final end = Offset(size.width - inset, size.height - 5);
    canvas.drawLine(start, end, paint..color = AuthExperienceColors.border);
    canvas.drawLine(
      start,
      Offset(lerpDouble(start.dx, end.dx, progress)!, end.dy),
      paint
        ..color = AuthExperienceColors.indigo
        ..strokeWidth = 2,
    );
    // Printed registration marks, deliberately matte and static while typing.
    for (var i = 0; i < 13; i++) {
      final x = size.width - inset - 3.0 * i;
      canvas.drawLine(
        Offset(x, 9),
        Offset(x, i % 3 == 0 ? 16 : 13),
        paint
          ..strokeWidth = 0.7
          ..color = AuthExperienceColors.textPrimary.withValues(alpha: 0.25),
      );
    }
  }

  @override
  bool shouldRepaint(_PassEngraving oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.expansion != expansion;
}
