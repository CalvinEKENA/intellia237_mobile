import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/widgets/intellia_pressable.dart';
import 'auth_experience_scaffold.dart';

class AuthAnimatedField extends StatefulWidget {
  const AuthAnimatedField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.validator,
    this.keyboardType,
    this.textInputAction,
    this.onFieldSubmitted,
    this.focusNode,
    this.enabled = true,
    this.isPassword = false,
    this.autofillHints,
    super.key,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onFieldSubmitted;
  final FocusNode? focusNode;
  final bool enabled;
  final bool isPassword;
  final Iterable<String>? autofillHints;

  @override
  State<AuthAnimatedField> createState() => _AuthAnimatedFieldState();
}

class _AuthAnimatedFieldState extends State<AuthAnimatedField> {
  late bool _obscure = widget.isPassword;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      enabled: widget.enabled,
      obscureText: _obscure,
      validator: widget.validator,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      onFieldSubmitted: widget.onFieldSubmitted,
      autofillHints: widget.autofillHints,
      autocorrect: !widget.isPassword,
      enableSuggestions: !widget.isPassword,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      cursorColor: AuthExperienceColors.gold,
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        labelStyle: const TextStyle(color: AuthExperienceColors.textSecondary),
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.32)),
        prefixIcon: Icon(widget.icon, color: Colors.white70, size: 20),
        suffixIcon: widget.isPassword
            ? IconButton(
                tooltip: _obscure
                    ? 'Afficher le mot de passe'
                    : 'Masquer le mot de passe',
                onPressed: () => setState(() => _obscure = !_obscure),
                icon: Icon(
                  _obscure
                      ? Icons.visibility_rounded
                      : Icons.visibility_off_rounded,
                  color: Colors.white60,
                  size: 20,
                ),
              )
            : null,
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.06),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 17,
        ),
        enabledBorder: _border(Colors.white.withValues(alpha: 0.13)),
        focusedBorder: _border(AuthExperienceColors.indigo, width: 1.6),
        errorBorder: _border(AuthExperienceColors.error),
        focusedErrorBorder: _border(AuthExperienceColors.error, width: 1.6),
        disabledBorder: _border(Colors.white.withValues(alpha: 0.06)),
        errorStyle: const TextStyle(
          color: Color(0xFFFF8D86),
          fontSize: 12,
          height: 1.25,
        ),
      ),
    );
  }

  OutlineInputBorder _border(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}

class AuthPrimaryButton extends StatelessWidget {
  const AuthPrimaryButton({
    required this.label,
    required this.onTap,
    this.isLoading = false,
    this.icon = Icons.arrow_forward_rounded,
    super.key,
  });

  final String label;
  final VoidCallback? onTap;
  final bool isLoading;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: onTap != null && !isLoading,
      label: label,
      child: IntelliaPressable(
        onTap: isLoading ? null : onTap,
        scaleFactor: 0.97,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          constraints: const BoxConstraints(minHeight: 54),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: onTap == null
                ? LinearGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.10),
                      Colors.white.withValues(alpha: 0.06),
                    ],
                  )
                : const LinearGradient(
                    colors: [
                      AuthExperienceColors.indigo,
                      AuthExperienceColors.purple,
                    ],
                  ),
            boxShadow: onTap == null
                ? null
                : [
                    BoxShadow(
                      color: AuthExperienceColors.purple.withValues(alpha: 0.3),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: Colors.white,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          label,
                          maxLines: 2,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Icon(icon, color: Colors.white, size: 20),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class AuthConsentTile extends StatelessWidget {
  const AuthConsentTile({
    required this.value,
    required this.label,
    required this.onChanged,
    super.key,
  });

  final bool value;
  final String label;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      checked: value,
      label: label,
      child: IntelliaPressable(
        onTap: () {
          HapticFeedback.selectionClick();
          onChanged(!value);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  color: value
                      ? AuthExperienceColors.indigo
                      : Colors.white.withValues(alpha: 0.05),
                  border: Border.all(
                    color: value
                        ? AuthExperienceColors.indigo
                        : Colors.white.withValues(alpha: 0.22),
                  ),
                ),
                child: value
                    ? const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 16,
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: AuthExperienceColors.textSecondary,
                    fontSize: 13,
                    height: 1.4,
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

class AuthErrorBanner extends StatelessWidget {
  const AuthErrorBanner({
    required this.message,
    this.onRetry,
    this.onDismiss,
    super.key,
  });

  final String message;
  final VoidCallback? onRetry;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: 'Erreur. $message',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AuthExperienceColors.error.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AuthExperienceColors.error.withValues(alpha: 0.45),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Color(0xFFFF8D86),
              size: 21,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  if (onRetry != null) ...[
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: onRetry,
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFFFFB0AB),
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 36),
                      ),
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('Réessayer'),
                    ),
                  ],
                ],
              ),
            ),
            if (onDismiss != null)
              IconButton(
                tooltip: 'Fermer',
                onPressed: onDismiss,
                icon: const Icon(
                  Icons.close_rounded,
                  color: Colors.white60,
                  size: 19,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
