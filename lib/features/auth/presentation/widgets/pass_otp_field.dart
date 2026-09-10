import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'auth_experience_scaffold.dart';
import 'living_pass.dart';

/// Six visual slots backed by one native input for paste, autofill and access.
/// Autofill and typing complete once; explicit actions remain available to retry.
class PassOtpField extends StatefulWidget {
  const PassOtpField({
    required this.controller,
    required this.focusNode,
    required this.label,
    required this.onSubmit,
    this.enabled = true,
    this.fieldKey,
    super.key,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String label;
  final VoidCallback onSubmit;
  final bool enabled;
  final Key? fieldKey;

  @override
  State<PassOtpField> createState() => _PassOtpFieldState();
}

class _PassOtpFieldState extends State<PassOtpField> {
  String? _autoSubmittedCode;

  void _onChanged(String value) {
    if (value.length < 6) {
      _autoSubmittedCode = null;
    } else if (widget.enabled && value != _autoSubmittedCode) {
      _autoSubmittedCode = value;
      widget.onSubmit();
    }
  }

  @override
  void didUpdateWidget(covariant PassOtpField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) _autoSubmittedCode = null;
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final focusNode = widget.focusNode;
    final enabled = widget.enabled;
    final label = widget.label;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ExcludeSemantics(
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'CampaignBody',
              color: AuthExperienceColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            const gap = 7.0;
            final slotWidth = (constraints.maxWidth - gap * 5) / 6;
            final slotHeight = math.max(
              64.0,
              MediaQuery.textScalerOf(context).scale(32) + 22,
            );
            return SizedBox(
              height: slotHeight,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  IgnorePointer(
                    child: ExcludeSemantics(
                      child: AnimatedBuilder(
                        animation: Listenable.merge([controller, focusNode]),
                        builder: (context, _) {
                          final code = controller.text;
                          final activeIndex = controller.selection.isValid
                              ? controller.selection.extentOffset.clamp(0, 5)
                              : code.length.clamp(0, 5);
                          return Row(
                            children: [
                              for (var index = 0; index < 6; index++) ...[
                                if (index > 0) const SizedBox(width: gap),
                                Expanded(
                                  child: DecoratedBox(
                                    key: ValueKey('pass-otp-slot-$index'),
                                    decoration: BoxDecoration(
                                      color: index < code.length
                                          ? AuthExperienceColors.surface
                                          : AuthExperienceColors.surfaceSoft,
                                      borderRadius: BorderRadius.circular(9),
                                      border: Border.all(
                                        color:
                                            enabled &&
                                                focusNode.hasFocus &&
                                                index == activeIndex
                                            ? AuthExperienceColors.indigo
                                            : AuthExperienceColors.border,
                                        width:
                                            enabled &&
                                                focusNode.hasFocus &&
                                                index == activeIndex
                                            ? 2
                                            : 1,
                                      ),
                                    ),
                                    child: Center(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 3,
                                        ),
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(
                                            index < code.length
                                                ? code[index]
                                                : '·',
                                            style: passDisplay(
                                              size: 36,
                                              color: index < code.length
                                                  ? AuthExperienceColors
                                                        .textPrimary
                                                  : AuthExperienceColors
                                                        .textTertiary,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                  Semantics(
                    label: label,
                    child: TextFormField(
                      key: widget.fieldKey,
                      controller: controller,
                      focusNode: focusNode,
                      enabled: enabled,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.oneTimeCode],
                      enableSuggestions: false,
                      autocorrect: false,
                      maxLength: 6,
                      maxLengthEnforcement: MaxLengthEnforcement.enforced,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: _onChanged,
                      onFieldSubmitted: (_) {
                        if (enabled) widget.onSubmit();
                      },
                      showCursor: false,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.transparent,
                        fontSize: 22,
                        letterSpacing: math.max(0, slotWidth + gap - 14),
                      ),
                      decoration: InputDecoration(
                        filled: false,
                        counterText: '',
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                          vertical: math.max(12, (slotHeight - 26) / 2),
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
