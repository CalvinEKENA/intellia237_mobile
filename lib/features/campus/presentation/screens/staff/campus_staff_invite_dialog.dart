import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/campus_providers.dart';
import '../../../domain/models/campus_roles.dart';
import '../../../domain/models/campus_staff.dart';
import '../../localization/campus_localizations.dart';
import '../../theme/campus_theme_tokens.dart';

class CampusStaffInviteDialog extends ConsumerStatefulWidget {
  const CampusStaffInviteDialog({super.key});

  @override
  ConsumerState<CampusStaffInviteDialog> createState() =>
      _CampusStaffInviteDialogState();
}

class _CampusStaffInviteDialogState
    extends ConsumerState<CampusStaffInviteDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController(text: '+237 ');
  final _emailController = TextEditingController();

  CampusRole _selectedRole = CampusRole.teacher;
  final List<String> _selectedSubjects = ['Mathématiques'];
  final List<String> _selectedClasses = ['Terminale C1'];

  bool _isReviewStep = false;
  bool _isSuccess = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = CampusLocalizations.of(context);
    final campusContext = ref.watch(campusContextProvider);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: CampusTokens.campusSurface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: CampusTokens.elevatedDialogShadow,
        ),
        child: _isSuccess
            ? _buildSuccessStep(context, l10n)
            : (_isReviewStep
                  ? _buildReviewStep(
                      context,
                      l10n,
                      campusContext.establishmentId,
                    )
                  : _buildFormStep(context, l10n)),
      ),
    );
  }

  Widget _buildFormStep(BuildContext context, CampusLocalizations l10n) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.addStaffTitle,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: CampusTokens.campusGraphite,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 18),
          // Full Name
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: l10n.staffFullNameLabel,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            validator: (v) => (v == null || v.trim().length < 2)
                ? 'Veuillez saisir un nom complet.'
                : null,
          ),
          const SizedBox(height: 14),
          // Phone
          TextFormField(
            controller: _phoneController,
            decoration: InputDecoration(
              labelText: l10n.staffPhoneLabel,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            validator: (v) => (v == null || v.trim().length < 9)
                ? 'Numéro de téléphone requis.'
                : null,
          ),
          const SizedBox(height: 14),
          // Optional Email
          TextFormField(
            controller: _emailController,
            decoration: InputDecoration(
              labelText: l10n.staffEmailLabel,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 14),
          // Role Selection
          DropdownButtonFormField<CampusRole>(
            initialValue: _selectedRole,
            decoration: InputDecoration(
              labelText: l10n.staffRoleLabel,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            items:
                [
                  CampusRole.teacher,
                  CampusRole.departmentHead,
                  CampusRole.pedagogicalLead,
                  CampusRole.schoolAdmin,
                  CampusRole.counsellor,
                ].map((r) {
                  return DropdownMenuItem(
                    value: r,
                    child: Text(l10n.roleLabel(r)),
                  );
                }).toList(),
            onChanged: (r) {
              if (r != null) setState(() => _selectedRole = r);
            },
          ),
          const SizedBox(height: 24),
          // Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.cancelLabel),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState?.validate() ?? false) {
                    setState(() => _isReviewStep = true);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: CampusTokens.campusBlueAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  l10n.isEnglish ? 'Review draft' : 'Vérifier l’invitation',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReviewStep(
    BuildContext context,
    CampusLocalizations l10n,
    String establishmentId,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.isEnglish
              ? 'Review invitation'
              : 'Récapitulatif de l’invitation',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: CampusTokens.campusGraphite,
          ),
        ),
        const SizedBox(height: 16),
        _reviewRow(l10n.staffFullNameLabel, _nameController.text.trim()),
        _reviewRow(l10n.staffPhoneLabel, _phoneController.text.trim()),
        if (_emailController.text.trim().isNotEmpty)
          _reviewRow(l10n.staffEmailLabel, _emailController.text.trim()),
        _reviewRow(l10n.staffRoleLabel, l10n.roleLabel(_selectedRole)),
        _reviewRow(l10n.staffSubjectsLabel, _selectedSubjects.join(', ')),
        _reviewRow(l10n.staffClassesLabel, _selectedClasses.join(', ')),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => setState(() => _isReviewStep = false),
              child: Text(l10n.isEnglish ? 'Back to edit' : 'Modifier'),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: () async {
                final draft = CampusStaffInvitationDraft(
                  fullName: _nameController.text.trim(),
                  phone: _phoneController.text.trim(),
                  email: _emailController.text.trim().isEmpty
                      ? null
                      : _emailController.text.trim(),
                  role: _selectedRole,
                  subjects: _selectedSubjects,
                  assignedClasses: _selectedClasses,
                );

                await ref
                    .read(campusRepositoryProvider)
                    .inviteStaffMember(
                      establishmentId: establishmentId,
                      draft: draft,
                    );

                ref.invalidate(campusStaffProvider);
                setState(() => _isSuccess = true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: CampusTokens.campusBlueAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(l10n.inviteLabel),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSuccessStep(BuildContext context, CampusLocalizations l10n) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Color(0xFFF0FDF4),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_circle_outline,
            size: 40,
            color: CampusTokens.masterySolid,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          l10n.invitationReadyTitle,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: CampusTokens.campusGraphite,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.invitationReadySubtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13,
            color: CampusTokens.campusGraphiteSecondary,
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          style: ElevatedButton.styleFrom(
            backgroundColor: CampusTokens.campusBlueAccent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(l10n.closeLabel),
        ),
      ],
    );
  }

  Widget _reviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: CampusTokens.campusGraphiteSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: CampusTokens.campusGraphite,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
