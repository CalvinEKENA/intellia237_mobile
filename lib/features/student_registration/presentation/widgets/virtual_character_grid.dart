import 'package:flutter/material.dart';

import '../../../../app/theme/design_tokens.dart';
import '../../domain/virtual_character_option.dart';

class VirtualCharacterGrid extends StatelessWidget {
  const VirtualCharacterGrid({
    required this.options,
    required this.selectedId,
    required this.onSelected,
    super.key,
  });

  final List<VirtualCharacterOption> options;
  final String? selectedId;
  final ValueChanged<VirtualCharacterOption> onSelected;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: options.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppSpacing.sm,
        mainAxisSpacing: AppSpacing.sm,
        mainAxisExtent: 160,
      ),
      itemBuilder: (context, index) {
        final option = options[index];
        final visual = _visuals[option.id] ?? _CharacterVisual.fallback;
        final isSelected = option.id == selectedId;

        return AnimatedContainer(
          duration: AppMotion.fast,
          curve: AppMotion.emphasizedDecelerate,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                visual.color.withValues(alpha: 0.2),
                visual.color.withValues(alpha: 0.06),
              ],
            ),
            border: Border.all(
              color: isSelected
                  ? visual.color
                  : Theme.of(
                      context,
                    ).colorScheme.outline.withValues(alpha: 0.25),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.md),
            onTap: () => onSelected(option),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: visual.color.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(visual.icon, color: visual.color),
                      ),
                      const Spacer(),
                      if (isSelected)
                        Icon(Icons.check_circle_rounded, color: visual.color),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    option.name,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    option.tagline,
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CharacterVisual {
  const _CharacterVisual({required this.color, required this.icon});

  final Color color;
  final IconData icon;

  static const fallback = _CharacterVisual(
    color: AppColors.brand,
    icon: Icons.psychology_alt_rounded,
  );
}

const _visuals = <String, _CharacterVisual>{
  'nova': _CharacterVisual(
    color: Color(0xFF1451E1),
    icon: Icons.auto_awesome_rounded,
  ),
  'kibo': _CharacterVisual(
    color: Color(0xFF0F766E),
    icon: Icons.favorite_rounded,
  ),
  'zuri': _CharacterVisual(color: Color(0xFF7C3AED), icon: Icons.bolt_rounded),
  'atlas': _CharacterVisual(
    color: Color(0xFFBE123C),
    icon: Icons.route_rounded,
  ),
};
