import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'academic_hierarchy.dart';
import 'academic_context_provider.dart';

class AcademicContextBar extends ConsumerWidget {
  const AcademicContextBar({
    super.key,
    this.allowGlobalView = true,
    this.onContextChanged,
  });

  final bool allowGlobalView;
  final VoidCallback? onContextChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final academicCtx = ref.watch(academicContextProvider);
    final notifier = ref.read(academicContextProvider.notifier);

    final currentSystem = academicCtx.system;
    final availableClasses = AcademicHierarchy.classesForSystem(currentSystem);
    final selectedClass = academicCtx.selectedClass;
    final allowedSeries = selectedClass?.allowedSeries ?? const <String>[];
    final selectedSeries = academicCtx.series;
    final selectedSubject = academicCtx.subject;
    final availableSubjects = AcademicHierarchy.getSubjectsFor(
      system: currentSystem,
      classLevel: selectedClass,
      series: selectedSeries,
    );

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF0D1B2A),
            const Color(0xFF1B263B).withValues(alpha: 0.95),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: selectedClass != null
              ? const Color(0xFFD4AF37).withValues(alpha: 0.6)
              : Colors.white12,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Active Academic Breadcrumb & Status Pill
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFD4AF37).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: const Color(0xFFD4AF37),
                    width: 0.8,
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.school, size: 14, color: Color(0xFFD4AF37)),
                    SizedBox(width: 5),
                    Text(
                      'CADRE ACADÉMIQUE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                        color: Color(0xFFD4AF37),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  academicCtx.breadcrumb,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (selectedClass == null && !academicCtx.showAllClasses)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade900.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: Colors.amber.shade600,
                      width: 0.8,
                    ),
                  ),
                  child: const Text(
                    '⚠️ Choisir une classe pour créer/publier',
                    style: TextStyle(fontSize: 11, color: Colors.amberAccent),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: Colors.white10),
          const SizedBox(height: 10),

          // Row 2: Selectors: Système -> Classe -> Série -> Matière -> Vue Globale
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // 1. Système d'enseignement
              _SelectorContainer(
                label: 'Système',
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<StudioEducationSystem>(
                    value: currentSystem,
                    isDense: true,
                    dropdownColor: const Color(0xFF1E2A38),
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    items: StudioEducationSystem.values.map((s) {
                      return DropdownMenuItem(
                        value: s,
                        child: Text(s.shortLabel),
                      );
                    }).toList(),
                    onChanged: (newSys) {
                      if (newSys != null) {
                        notifier.setSystem(newSys);
                        onContextChanged?.call();
                      }
                    },
                  ),
                ),
              ),

              // 2. Classe (Cameroon non-alphabetical canonical order)
              _SelectorContainer(
                label: 'Classe',
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String?>(
                    value: selectedClass?.id,
                    hint: const Text(
                      'Choisir classe',
                      style: TextStyle(color: Colors.white54, fontSize: 13),
                    ),
                    isDense: true,
                    dropdownColor: const Color(0xFF1E2A38),
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text(
                          '— Choisir une classe —',
                          style: TextStyle(color: Colors.white54),
                        ),
                      ),
                      ...availableClasses.map((c) {
                        return DropdownMenuItem<String?>(
                          value: c.id,
                          child: Text(
                            c.label,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        );
                      }),
                    ],
                    onChanged: (classId) {
                      notifier.setClassById(classId);
                      onContextChanged?.call();
                    },
                  ),
                ),
              ),

              // 3. Série / Filière (visible only if class has series)
              if (selectedClass != null && selectedClass.hasSeries)
                _SelectorContainer(
                  label: currentSystem == StudioEducationSystem.anglophone
                      ? 'Stream'
                      : 'Série',
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String?>(
                      value: selectedSeries,
                      hint: const Text(
                        'Toutes séries',
                        style: TextStyle(color: Colors.white54, fontSize: 13),
                      ),
                      isDense: true,
                      dropdownColor: const Color(0xFF1E2A38),
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text(
                            'Toutes séries',
                            style: TextStyle(color: Colors.white54),
                          ),
                        ),
                        ...allowedSeries.map((s) {
                          return DropdownMenuItem<String?>(
                            value: s,
                            child: Text(
                              'Série $s',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        }),
                      ],
                      onChanged: (s) {
                        notifier.setSeries(s);
                        onContextChanged?.call();
                      },
                    ),
                  ),
                ),

              // 4. Matière (Class-aware canonical catalog)
              _SelectorContainer(
                label: 'Matière',
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String?>(
                    value:
                        (selectedSubject != null &&
                            availableSubjects.any(
                              (s) => s.id == selectedSubject.id,
                            ))
                        ? selectedSubject.id
                        : null,
                    hint: const Text(
                      'Toutes matières',
                      style: TextStyle(color: Colors.white54, fontSize: 13),
                    ),
                    isDense: true,
                    dropdownColor: const Color(0xFF1E2A38),
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text(
                          'Toutes matières',
                          style: TextStyle(color: Colors.white54),
                        ),
                      ),
                      ...availableSubjects.map((subj) {
                        return DropdownMenuItem<String?>(
                          value: subj.id,
                          child: Text(subj.name),
                        );
                      }),
                    ],
                    onChanged: (subjId) {
                      notifier.setSubjectById(subjId);
                      onContextChanged?.call();
                    },
                  ),
                ),
              ),

              // 5. Vue Globale (SuperAdmin Overview)
              if (allowGlobalView)
                InkWell(
                  onTap: () {
                    notifier.toggleShowAllClasses(!academicCtx.showAllClasses);
                    onContextChanged?.call();
                  },
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: academicCtx.showAllClasses
                          ? const Color(0xFFD4AF37).withValues(alpha: 0.2)
                          : Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: academicCtx.showAllClasses
                            ? const Color(0xFFD4AF37)
                            : Colors.white12,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          academicCtx.showAllClasses
                              ? Icons.visibility
                              : Icons.visibility_off_outlined,
                          size: 14,
                          color: academicCtx.showAllClasses
                              ? const Color(0xFFD4AF37)
                              : Colors.white54,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Toutes les classes',
                          style: TextStyle(
                            fontSize: 12,
                            color: academicCtx.showAllClasses
                                ? const Color(0xFFD4AF37)
                                : Colors.white70,
                            fontWeight: academicCtx.showAllClasses
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SelectorContainer extends StatelessWidget {
  const _SelectorContainer({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF142132),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 11,
              color: Colors.white54,
              fontWeight: FontWeight.w600,
            ),
          ),
          child,
        ],
      ),
    );
  }
}
