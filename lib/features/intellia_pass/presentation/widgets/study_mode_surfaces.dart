import 'package:flutter/material.dart';

import '../../../../core/localization/localization_extensions.dart';

class StudyDurationSelector extends StatelessWidget {
  const StudyDurationSelector({
    required this.onSelected,
    this.durations = const [
      Duration(minutes: 20),
      Duration(minutes: 30),
      Duration(minutes: 45),
      Duration(minutes: 60),
    ],
    super.key,
  });

  final List<Duration> durations;
  final ValueChanged<Duration> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.studyModeTitle,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 6),
        Text(l10n.studyModeFamilyCopy),
        const SizedBox(height: 16),
        Text(l10n.studyModeDuration),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final duration in durations)
              OutlinedButton(
                key: ValueKey('study-duration-${duration.inMinutes}'),
                onPressed: () => onSelected(duration),
                child: Text('${duration.inMinutes} min'),
              ),
          ],
        ),
      ],
    );
  }
}

class StudyModeCompleteSurface extends StatelessWidget {
  const StudyModeCompleteSurface({required this.onReclaim, super.key});

  final VoidCallback onReclaim;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return PopScope<Object?>(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.task_alt_rounded, size: 56),
                  const SizedBox(height: 18),
                  Text(
                    l10n.studyModeComplete,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 10),
                  Text(l10n.studyModeCompleteBody, textAlign: TextAlign.center),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    key: const ValueKey('study-mode-reclaim'),
                    onPressed: onReclaim,
                    icon: const Icon(Icons.lock_person_outlined),
                    label: Text(l10n.reclaimDevice),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
