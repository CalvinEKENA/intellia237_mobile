import 'package:flutter/material.dart';
import '../../app/theme/design_tokens.dart';

class IntelliaTextField extends StatelessWidget {
  const IntelliaTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.prefixIcon,
    this.suffixIcon,
    this.keyboardType,
    this.obscureText = false,
    this.validator,
    this.onChanged,
    this.textInputAction = TextInputAction.next,
    this.autofocus = false,
    this.enabled = true,
  });

  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final TextInputAction textInputAction;
  final bool autofocus;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: isDark
                  ? IntelliaColors.textSecondaryDark
                  : IntelliaColors.textSecondary,
            ),
          ),
          const SizedBox(height: IntelliaSpacing.xs),
        ],
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          validator: validator,
          onChanged: onChanged,
          textInputAction: textInputAction,
          autofocus: autofocus,
          enabled: enabled,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: isDark
                ? IntelliaColors.textPrimaryDark
                : IntelliaColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: prefixIcon != null
                ? Icon(
                    prefixIcon,
                    size: 20,
                    color: isDark
                        ? IntelliaColors.textTertiary
                        : IntelliaColors.textSecondary,
                  )
                : null,
            suffixIcon: suffixIcon,
            errorMaxLines: 2,
          ),
        ),
      ],
    );
  }
}

class IntelliaPasswordField extends StatefulWidget {
  const IntelliaPasswordField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.validator,
    this.onChanged,
    this.textInputAction = TextInputAction.done,
    this.enabled = true,
  });

  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final TextInputAction textInputAction;
  final bool enabled;

  @override
  State<IntelliaPasswordField> createState() => _IntelliaPasswordFieldState();
}

class _IntelliaPasswordFieldState extends State<IntelliaPasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return IntelliaTextField(
      controller: widget.controller,
      label: widget.label,
      hint: widget.hint ?? '••••••••',
      prefixIcon: Icons.lock_rounded,
      obscureText: _obscure,
      validator: widget.validator,
      onChanged: widget.onChanged,
      textInputAction: widget.textInputAction,
      enabled: widget.enabled,
      suffixIcon: GestureDetector(
        onTap: () => setState(() => _obscure = !_obscure),
        child: Icon(
          _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          size: 20,
          color: isDark
              ? IntelliaColors.textTertiary
              : IntelliaColors.textSecondary,
        ),
      ),
    );
  }
}
