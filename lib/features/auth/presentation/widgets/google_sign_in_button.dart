import 'package:flutter/material.dart';

/// Official Google "G" Logo CustomPainter.
///
/// Implemented strictly according to Google Identity Branding Guidelines:
/// - Exact 4-color palette: Blue (#4285F4), Red (#EA4335), Yellow (#FBBC05), Green (#34A853).
/// - Exact geometry with horizontal bar, circular arc, and sharp corner cuts.
/// - Never distorted, recoloured, or placed on low-contrast backgrounds.
class GoogleGLogoPainter extends CustomPainter {
  const GoogleGLogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    // Standard coordinates based on 24x24 Google G grid
    final double scale = size.width / 24.0;
    canvas.save();
    canvas.scale(scale, scale);

    // Blue #4285F4
    final bluePaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;
    final bluePath = Path()
      ..moveTo(23.745, 12.27)
      ..cubicTo(23.745, 11.48, 23.675, 10.73, 23.55, 10.0)
      ..lineTo(12.0, 10.0)
      ..lineTo(12.0, 14.51)
      ..lineTo(18.6, 14.51)
      ..cubicTo(18.315, 15.99, 17.45, 17.24, 16.16, 18.09)
      ..lineTo(20.095, 21.13)
      ..cubicTo(22.395, 19.01, 23.745, 15.92, 23.745, 12.27)
      ..close();
    canvas.drawPath(bluePath, bluePaint);

    // Green #34A853
    final greenPaint = Paint()
      ..color = const Color(0xFF34A853)
      ..style = PaintingStyle.fill;
    final greenPath = Path()
      ..moveTo(12.0, 24.0)
      ..cubicTo(15.24, 24.0, 17.96, 22.93, 19.97, 21.07)
      ..lineTo(16.035, 18.03)
      ..cubicTo(14.95, 18.76, 13.59, 19.23, 12.0, 19.23)
      ..cubicTo(8.87, 19.23, 6.22, 17.14, 5.27, 14.33)
      ..lineTo(1.2, 17.47)
      ..cubicTo(3.26, 21.52, 7.34, 24.0, 12.0, 24.0)
      ..close();
    canvas.drawPath(greenPath, greenPaint);

    // Yellow #FBBC05
    final yellowPaint = Paint()
      ..color = const Color(0xFFFBBC05)
      ..style = PaintingStyle.fill;
    final yellowPath = Path()
      ..moveTo(5.27, 14.33)
      ..cubicTo(5.03, 13.6, 4.89, 12.82, 4.89, 12.0)
      ..cubicTo(4.89, 11.18, 5.03, 10.4, 5.27, 9.67)
      ..lineTo(1.2, 6.53)
      ..cubicTo(0.44, 8.04, 0.0, 9.97, 0.0, 12.0)
      ..cubicTo(0.0, 14.03, 0.44, 15.96, 1.2, 17.47)
      ..lineTo(5.27, 14.33)
      ..close();
    canvas.drawPath(yellowPath, yellowPaint);

    // Red #EA4335
    final redPaint = Paint()
      ..color = const Color(0xFFEA4335)
      ..style = PaintingStyle.fill;
    final redPath = Path()
      ..moveTo(12.0, 4.77)
      ..cubicTo(13.77, 4.77, 15.35, 5.38, 16.6, 6.57)
      ..lineTo(20.06, 3.11)
      ..cubicTo(17.95, 1.18, 15.23, 0.0, 12.0, 0.0)
      ..cubicTo(7.34, 0.0, 3.26, 2.48, 1.2, 6.53)
      ..lineTo(5.27, 9.67)
      ..cubicTo(6.22, 6.86, 8.87, 4.77, 12.0, 4.77)
      ..close();
    canvas.drawPath(redPath, redPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Official compliant Google Sign-In button for Intellia237.
///
/// Complies with:
/// 1. Google Identity Branding Guidelines:
///    - Official 4-color Google "G" logo
///    - Standard label "Continuer avec Google"
///    - High contrast background with standard subtle border
/// 2. Mobile Accessibility:
///    - $\ge 48$dp touch target height (standard 52dp)
///    - Full TalkBack / VoiceOver semantic labeling
///    - Supports large text scales (textScaleFactor / TextScaler up to 2.0) without overflowing
/// 3. Intellia237 Design System:
///    - Smooth rounded corners (16dp) matching Intellia action buttons
///    - Clear loading and disabled states
class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
    this.label = 'Continuer avec Google',
  });

  final VoidCallback? onPressed;
  final bool isLoading;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final backgroundColor = isDark ? const Color(0xFF1F1F1F) : Colors.white;
    final textColor = isDark
        ? const Color(0xFFE3E3E3)
        : const Color(0xFF1F1F1F);
    final borderColor = isDark
        ? const Color(0xFF444746)
        : const Color(0xFFDADCE0);

    return Semantics(
      button: true,
      enabled: onPressed != null && !isLoading,
      label: isLoading ? 'Connexion Google en cours' : label,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: 52,
          minWidth: double.infinity,
        ),
        child: OutlinedButton(
          key: const Key('google-signin-button'),
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            backgroundColor: backgroundColor,
            foregroundColor: textColor,
            elevation: 0,
            side: BorderSide(color: borderColor, width: 1.2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: isLoading
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isDark
                            ? const Color(0xFFD4AF37)
                            : const Color(0xFF003366),
                      ),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      const CustomPaint(
                        size: Size(22, 22),
                        painter: GoogleGLogoPainter(),
                      ),
                      const SizedBox(width: 14),
                      Flexible(
                        child: Text(
                          label,
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.1,
                            color: textColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
