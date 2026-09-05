import 'package:flutter/material.dart';

import '../../../core/localization/localization_extensions.dart';
import '../domain/admin_content_models.dart';
import '../domain/admin_models.dart';

String adminRoleLabel(BuildContext context, AdminRoleType role) =>
    switch (role) {
      AdminRoleType.student => context.l10n.studentRole,
      AdminRoleType.parent => context.l10n.parentRole,
      AdminRoleType.teacher => context.l10n.teacherRole,
      AdminRoleType.admin => context.l10n.administrationRole,
    };

String moderationStatusLabel(BuildContext context, ModerationStatus status) =>
    switch (status) {
      ModerationStatus.pending => context.l10n.pendingStatus,
      ModerationStatus.approved => context.l10n.approvedStatus,
      ModerationStatus.rejected => context.l10n.hiddenStatus,
    };

String adminClassLevelDisplay(BuildContext context, String value) =>
    switch (value) {
      '6eme' => '6e',
      '5eme' => '5e',
      '4eme' => '4e',
      '3eme' => '3e',
      'Premiere' => context.l10n.classPremiereDisplay,
      _ => value,
    };

String adminContentStatusLabel(BuildContext context, String status) =>
    switch (status) {
      'published' => context.l10n.publishedStatus,
      'ai_generated' => context.l10n.aiStatus,
      _ => context.l10n.draftStatus,
    };

String adminAudienceLabel(BuildContext context, String audience) =>
    switch (audience) {
      adminAudienceWholeSchool => context.l10n.audienceWholeSchool,
      adminAudienceStudents => context.l10n.studentsLabel,
      adminAudienceParents => context.l10n.parentsLabel,
      adminAudienceTeachers => context.l10n.teachersLabel,
      adminAudienceAdministration => context.l10n.administrationRole,
      _ => audience,
    };

String adminDifficultyLabel(BuildContext context, String difficulty) =>
    switch (difficulty) {
      adminDifficultyBeginner => context.l10n.beginnerDifficulty,
      adminDifficultyIntermediate => context.l10n.intermediateDifficulty,
      adminDifficultyAdvanced => context.l10n.advancedDifficulty,
      adminDifficultyExpert => context.l10n.expertDifficulty,
      _ => difficulty,
    };
