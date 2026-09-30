import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'academic_hierarchy.dart';

@immutable
class StudioAcademicContext {
  const StudioAcademicContext({
    this.system = StudioEducationSystem.francophone,
    this.selectedClass,
    this.series,
    this.subject,
    this.chapterId,
    this.showAllClasses = false,
  });

  final StudioEducationSystem system;
  final CanonicalClassLevel? selectedClass;
  final String? series;
  final CanonicalSubject? subject;
  final String? chapterId;
  final bool showAllClasses;

  /// Whether a valid primary academic target is selected for authoring/publishing
  bool get hasValidTarget => selectedClass != null && subject != null;

  /// Whether a class is explicitly selected
  bool get hasClass => selectedClass != null;

  /// Series must be specified if the selected class requires one
  bool get hasRequiredSeries =>
      selectedClass == null ||
      !selectedClass!.hasSeries ||
      (series != null && series!.isNotEmpty);

  /// Ready for publication validation check
  bool get isPublicationReady => hasValidTarget && hasRequiredSeries;

  /// Formatted breadcrumb path: e.g. "FRANCOPHONE › 3e › MATHÉMATIQUES"
  String get breadcrumb {
    final parts = <String>[system.shortLabel.toUpperCase()];
    if (selectedClass != null) {
      final classStr = selectedClass!.shortLabel;
      if (series != null && series!.isNotEmpty) {
        parts.add('$classStr ($series)'.toUpperCase());
      } else {
        parts.add(classStr.toUpperCase());
      }
    } else {
      parts.add(showAllClasses ? 'TOUTES CLASSES' : 'CHOISIR CLASSE');
    }

    if (subject != null) {
      parts.add(subject!.name.toUpperCase());
    }
    return parts.join(' › ');
  }

  /// Full destination descriptor for Publishing Center
  String get fullTargetDescription {
    if (selectedClass == null) {
      return showAllClasses
          ? '${system.shortLabel} (Vue globale — toutes les classes)'
          : 'Cible académique non définie';
    }
    final buffer = StringBuffer(
      '${system.shortLabel} • ${selectedClass!.label}',
    );
    if (series != null && series!.isNotEmpty) {
      buffer.write(' Série $series');
    }
    if (subject != null) {
      buffer.write(' • ${subject!.name}');
    }
    return buffer.toString();
  }

  StudioAcademicContext copyWith({
    StudioEducationSystem? system,
    CanonicalClassLevel? Function()? selectedClass,
    String? Function()? series,
    CanonicalSubject? Function()? subject,
    String? Function()? chapterId,
    bool? showAllClasses,
  }) {
    return StudioAcademicContext(
      system: system ?? this.system,
      selectedClass: selectedClass != null
          ? selectedClass()
          : this.selectedClass,
      series: series != null ? series() : this.series,
      subject: subject != null ? subject() : this.subject,
      chapterId: chapterId != null ? chapterId() : this.chapterId,
      showAllClasses: showAllClasses ?? this.showAllClasses,
    );
  }
}

class AcademicContextNotifier extends StateNotifier<StudioAcademicContext> {
  AcademicContextNotifier() : super(const StudioAcademicContext());

  void setSystem(StudioEducationSystem newSystem) {
    if (state.system == newSystem) return;
    // When changing system, reset class & series if current class belongs to previous system
    final currentClass = state.selectedClass;
    if (currentClass != null && currentClass.system != newSystem) {
      state = state.copyWith(
        system: newSystem,
        selectedClass: () => null,
        series: () => null,
      );
    } else {
      state = state.copyWith(system: newSystem);
    }
  }

  void setClass(CanonicalClassLevel? newClass) {
    if (newClass == null) {
      state = state.copyWith(selectedClass: () => null, series: () => null);
      return;
    }

    // Auto-update system if newClass belongs to different system
    final system = newClass.system;

    // Check if current series is allowed on the new class
    final validSeries =
        (state.series != null && newClass.allowedSeries.contains(state.series))
        ? state.series
        : (newClass.hasSeries ? newClass.allowedSeries.first : null);

    // Validate if current subject remains valid in the new academic class & series context
    final validSubjects = AcademicHierarchy.getSubjectsFor(
      system: system,
      classLevel: newClass,
      series: validSeries,
    );
    final validSubject =
        (state.subject != null &&
            validSubjects.any((s) => s.id == state.subject!.id))
        ? state.subject
        : null;

    state = state.copyWith(
      system: system,
      selectedClass: () => newClass,
      series: () => validSeries,
      subject: () => validSubject,
      showAllClasses: false,
    );
  }

  void setClassById(String? classId) {
    if (classId == null || classId.isEmpty) {
      setClass(null);
      return;
    }
    final resolved = AcademicHierarchy.resolveClass(classId);
    setClass(resolved);
  }

  void setClassByCatalogKey(String? catalogKey) => setClassById(catalogKey);

  void setSeries(String? series) {
    final currentClass = state.selectedClass;
    if (currentClass == null || !currentClass.hasSeries) {
      state = state.copyWith(series: () => null);
      return;
    }
    final targetSeries =
        (series != null && currentClass.allowedSeries.contains(series))
        ? series
        : null;

    // Validate if current subject remains valid with the updated series
    final validSubjects = AcademicHierarchy.getSubjectsFor(
      system: state.system,
      classLevel: currentClass,
      series: targetSeries,
    );
    final validSubject =
        (state.subject != null &&
            validSubjects.any((s) => s.id == state.subject!.id))
        ? state.subject
        : null;

    state = state.copyWith(
      series: () => targetSeries,
      subject: () => validSubject,
    );
  }

  void setSubject(CanonicalSubject? subject) {
    if (subject == null) {
      state = state.copyWith(subject: () => null);
      return;
    }
    if (state.selectedClass != null) {
      final validSubjects = AcademicHierarchy.getSubjectsFor(
        system: state.system,
        classLevel: state.selectedClass,
        series: state.series,
      );
      if (!validSubjects.any((s) => s.id == subject.id)) {
        // Disallow subjects not in the canonical curriculum for the current class
        return;
      }
    }
    state = state.copyWith(subject: () => subject);
  }

  void setSubjectById(String? subjectId) {
    if (subjectId == null || subjectId.isEmpty) {
      setSubject(null);
      return;
    }
    final resolved = AcademicHierarchy.resolveSubject(
      subjectId,
      system: state.system,
      classLevel: state.selectedClass,
      series: state.series,
    );
    setSubject(resolved);
  }

  void setChapterId(String? chapterId) {
    state = state.copyWith(chapterId: () => chapterId);
  }

  void toggleShowAllClasses(bool value) {
    state = state.copyWith(showAllClasses: value);
  }

  void reset() {
    state = const StudioAcademicContext();
  }
}

final academicContextProvider =
    StateNotifierProvider<AcademicContextNotifier, StudioAcademicContext>((
      ref,
    ) {
      return AcademicContextNotifier();
    });
