import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/design_tokens.dart';
import '../../../core/localization/localization_extensions.dart';
import '../../../core/widgets/intellia_state_view.dart';
import '../../parent/application/parent_providers.dart';
import '../application/mobile_money_providers.dart';
import '../data/mobile_money_repository.dart';
import '../domain/mobile_money_models.dart';
import 'mobile_money_localization.dart';

/// Paiement d'un abonnement, enfant par enfant.
///
/// Registre de décisions (mission famille, enfants dans plusieurs écoles) :
/// le serveur devinait l'école du parent et refusait tout paiement dès que
/// ses enfants étaient dans deux écoles. Le parent choisit désormais l'enfant ;
/// l'enfant désigne l'école, donc l'offre, et l'écran dit explicitement quels
/// enfants le paiement couvre.
class MobileMoneyParentTab extends ConsumerStatefulWidget {
  const MobileMoneyParentTab({this.initialChildId, super.key});

  /// Enfant présélectionné (action « Abonnement » d'une carte enfant).
  final String? initialChildId;

  @override
  ConsumerState<MobileMoneyParentTab> createState() =>
      _MobileMoneyParentTabState();
}

class _MobileMoneyParentTabState extends ConsumerState<MobileMoneyParentTab> {
  final _phoneController = TextEditingController();
  final _referenceController = TextEditingController();
  String? _operatorCode;
  String? _clientRequestId;
  bool _submitting = false;
  String? _childId;

  @override
  void initState() {
    super.initState();
    _childId = widget.initialChildId;
    _phoneController.addListener(_resetIdempotencyKey);
    _referenceController.addListener(_resetIdempotencyKey);
  }

  @override
  void dispose() {
    _phoneController
      ..removeListener(_resetIdempotencyKey)
      ..dispose();
    _referenceController
      ..removeListener(_resetIdempotencyKey)
      ..dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant MobileMoneyParentTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    final initial = widget.initialChildId;
    if (initial != null && initial != oldWidget.initialChildId) {
      _selectChild(initial);
    }
  }

  void _resetIdempotencyKey() {
    _clientRequestId = null;
  }

  void _selectChild(String studentId) {
    setState(() {
      _childId = studentId;
      _operatorCode = null;
      _clientRequestId = null;
    });
  }

  Widget _async(
    AsyncValue<MobileMoneyOverview> value,
    Widget Function(MobileMoneyOverview) data,
  ) => value.when(
    loading: () => IntelliaStateView(
      kind: IntelliaStateKind.loading,
      title: context.l10n.loadingOffer,
    ),
    error: (error, stackTrace) => IntelliaStateView(
      kind: IntelliaStateKind.errorRetryable,
      title: context.l10n.serviceUnavailable,
      message: mobileMoneyErrorMessage(context, error),
      primaryLabel: context.l10n.retryLabel,
      onPrimary: () => ref.invalidate(parentMobileMoneyOverviewProvider),
    ),
    data: data,
  );

  @override
  Widget build(BuildContext context) {
    return _async(ref.watch(parentMobileMoneyOverviewProvider(null)), (family) {
      // Serveur antérieur : pas de bénéficiaire explicite, comportement
      // historique.
      if (!family.supportsBeneficiary) return _buildOverview(context, family);
      final children = family.children;
      final chosen = children.any((child) => child.studentId == _childId)
          ? _childId
          : children.length == 1
          ? children.first.studentId
          : null;
      if (chosen == null) {
        return _buildOverview(context, family, children: children);
      }
      return _async(
        ref.watch(parentMobileMoneyOverviewProvider(chosen)),
        (overview) => _buildOverview(
          context,
          overview,
          children: children,
          beneficiaryId: chosen,
        ),
      );
    });
  }

  Widget _buildOverview(
    BuildContext context,
    MobileMoneyOverview overview, {
    List<MobileMoneyChild> children = const [],
    String? beneficiaryId,
  }) {
    final choosing = overview.supportsBeneficiary && beneficiaryId == null;
    final offer = choosing ? null : overview.offer;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        IntelliaSpacing.lg,
        IntelliaSpacing.lg,
        IntelliaSpacing.lg,
        132,
      ),
      children: [
        Text(
          context.l10n.subscriptionTitle,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: IntelliaSpacing.xs),
        Text(
          context.l10n.mobileMoneyParentDescription,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: IntelliaSpacing.md),
        if (children.length > 1) ...[
          Text(
            context.l10n.mobileMoneyChooseChild,
            key: const ValueKey('mobile-money-choose-child'),
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: IntelliaSpacing.xs),
          Wrap(
            spacing: IntelliaSpacing.xs,
            runSpacing: IntelliaSpacing.xs,
            children: [
              for (final child in children)
                ChoiceChip(
                  key: ValueKey('mobile-money-child-${child.studentId}'),
                  label: Text(child.firstName),
                  selected: child.studentId == beneficiaryId,
                  onSelected: (_) => _selectChild(child.studentId),
                ),
            ],
          ),
          const SizedBox(height: IntelliaSpacing.md),
        ],
        if (choosing)
          const SizedBox.shrink()
        else if (offer == null)
          _UnavailableOffer(availability: overview.availability)
        else ...[
          _OfferContext(
            beneficiaryId: beneficiaryId,
            overview: overview,
            children: children,
          ),
          _buildOfferForm(context, offer, beneficiaryId: beneficiaryId),
        ],
        if (overview.recentRequests.isNotEmpty) ...[
          const SizedBox(height: IntelliaSpacing.lg),
          Text(
            context.l10n.myPaymentRequests,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: IntelliaSpacing.sm),
          for (final request in overview.recentRequests) ...[
            _ParentRequestCard(request: request),
            const SizedBox(height: IntelliaSpacing.sm),
          ],
        ],
      ],
    );
  }

  Widget _buildOfferForm(
    BuildContext context,
    MobileMoneyOffer offer, {
    String? beneficiaryId,
  }) {
    final operator = offer.operators.cast<MobileMoneyOperator?>().firstWhere(
      (item) => item?.code == _operatorCode,
      orElse: () => offer.operators.isEmpty ? null : offer.operators.first,
    );
    if (operator == null) {
      return _UnavailableOffer(
        availability: MobileMoneyAvailability.notConfigured,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(IntelliaSpacing.lg),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0F766E), Color(0xFF2563EB)],
            ),
            borderRadius: BorderRadius.circular(IntelliaRadii.medium),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                offer.title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: IntelliaSpacing.xs),
              Text(
                offer.description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
              const SizedBox(height: IntelliaSpacing.md),
              Text(
                formatXaf(offer.amountXaf),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                context.l10n.accessDaysAfterApproval(offer.durationDays),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.88),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: IntelliaSpacing.md),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(IntelliaSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  context.l10n.mobileMoneyStepTransfer,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: IntelliaSpacing.sm),
                DropdownButtonFormField<String>(
                  initialValue: operator.code,
                  decoration: InputDecoration(
                    labelText: context.l10n.operatorLabel,
                    prefixIcon: const Icon(Icons.sim_card_outlined),
                  ),
                  items: [
                    for (final item in offer.operators)
                      DropdownMenuItem(
                        value: item.code,
                        child: Text(item.label),
                      ),
                  ],
                  onChanged: (value) => setState(() {
                    _operatorCode = value;
                    _clientRequestId = null;
                  }),
                ),
                const SizedBox(height: IntelliaSpacing.sm),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.phone_android_rounded),
                  title: Text(operator.recipientPhone),
                  subtitle: Text(context.l10n.recipientNumberConfigured),
                  trailing: IconButton(
                    tooltip: context.l10n.copyNumber,
                    onPressed: () async {
                      await Clipboard.setData(
                        ClipboardData(text: operator.recipientPhone),
                      );
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(context.l10n.numberCopied)),
                      );
                    },
                    icon: const Icon(Icons.copy_rounded),
                  ),
                ),
                if (operator.instructions case final instructions?) ...[
                  const SizedBox(height: IntelliaSpacing.xs),
                  Text(instructions),
                ],
                const SizedBox(height: IntelliaSpacing.sm),
                Container(
                  padding: const EdgeInsets.all(IntelliaSpacing.sm),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primaryContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(IntelliaRadii.small),
                  ),
                  child: Text(context.l10n.mobileMoneyNoDebitNotice),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: IntelliaSpacing.sm),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(IntelliaSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  context.l10n.mobileMoneyStepProof,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: IntelliaSpacing.sm),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  autofillHints: const [AutofillHints.telephoneNumber],
                  decoration: InputDecoration(
                    labelText: context.l10n.payerPhoneLabel,
                    hintText: '6XX XXX XXX',
                    prefixIcon: const Icon(Icons.phone_outlined),
                  ),
                ),
                const SizedBox(height: IntelliaSpacing.sm),
                TextField(
                  controller: _referenceController,
                  textCapitalization: TextCapitalization.characters,
                  autocorrect: false,
                  decoration: InputDecoration(
                    labelText: context.l10n.transactionReferenceLabel,
                    prefixIcon: const Icon(Icons.receipt_long_outlined),
                  ),
                ),
                const SizedBox(height: IntelliaSpacing.md),
                FilledButton.icon(
                  onPressed: _submitting
                      ? null
                      : () => _confirmAndSubmit(
                          offer,
                          operator,
                          beneficiaryId: beneficiaryId,
                        ),
                  icon: _submitting
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.verified_user_outlined),
                  label: Text(
                    _submitting
                        ? context.l10n.sendingLabel
                        : context.l10n.submitForReview,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmAndSubmit(
    MobileMoneyOffer offer,
    MobileMoneyOperator operator, {
    String? beneficiaryId,
  }) async {
    final phone = _phoneController.text.trim();
    final reference = _referenceController.text.trim();
    if (phone.isEmpty || reference.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.enterTransferDetails)),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.confirmDeclarationTitle),
        content: Text(
          context.l10n.confirmTransferDeclaration(
            formatXaf(offer.amountXaf),
            operator.label,
            operator.recipientPhone,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(context.l10n.cancelLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(context.l10n.confirmLabel),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _submitting = true);
    _clientRequestId ??= newMobileMoneyRequestId();
    try {
      await ref
          .read(mobileMoneyActionsProvider)
          .submit(
            beneficiaryStudentId: beneficiaryId,
            offer: offer,
            operator: operator,
            payerPhone: phone,
            transactionReference: reference,
            clientRequestId: _clientRequestId!,
          );
      if (!mounted) return;
      _referenceController.clear();
      _clientRequestId = null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.paymentRequestSubmitted)),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mobileMoneyErrorMessage(context, error))),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}

/// L'école de l'enfant choisi et les enfants que le paiement couvre, dits
/// avant de payer.
class _OfferContext extends ConsumerWidget {
  const _OfferContext({
    required this.beneficiaryId,
    required this.overview,
    required this.children,
  });

  final String? beneficiaryId;
  final MobileMoneyOverview overview;
  final List<MobileMoneyChild> children;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = beneficiaryId;
    if (id == null) return const SizedBox.shrink();
    final school = ref
        .watch(parentChildByIdProvider(id))
        .value
        ?.establishmentName
        ?.trim();
    final covered = [
      for (final child in children)
        if (overview.coveredStudentIds.contains(child.studentId))
          child.firstName,
    ];
    return Padding(
      padding: const EdgeInsets.only(bottom: IntelliaSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (school != null && school.isNotEmpty)
            Text(
              context.l10n.mobileMoneyOfferOfSchool(school),
              key: const ValueKey('mobile-money-offer-school'),
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
          if (covered.isNotEmpty)
            Text(
              context.l10n.mobileMoneyCoversChildren(covered.join(', ')),
              key: const ValueKey('mobile-money-covered-children'),
            ),
        ],
      ),
    );
  }
}

class _UnavailableOffer extends StatelessWidget {
  const _UnavailableOffer({required this.availability});

  final MobileMoneyAvailability availability;

  @override
  Widget build(BuildContext context) {
    final message = switch (availability) {
      MobileMoneyAvailability.schoolNotLinked =>
        context.l10n.noValidatedSchoolLinked,
      MobileMoneyAvailability.multipleSchools =>
        context.l10n.multipleSchoolsLinked,
      _ => context.l10n.noActiveMobileMoneyOffer,
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(IntelliaSpacing.lg),
        child: Column(
          children: [
            Icon(
              Icons.hourglass_empty_rounded,
              size: 40,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: IntelliaSpacing.sm),
            Text(
              context.l10n.offerUnavailable,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: IntelliaSpacing.xs),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _ParentRequestCard extends StatelessWidget {
  const _ParentRequestCard({required this.request});

  final ParentPaymentStatus request;

  @override
  Widget build(BuildContext context) {
    final color = switch (request.status) {
      MobileMoneyPaymentStatus.pending => const Color(0xFFD97706),
      MobileMoneyPaymentStatus.approved => const Color(0xFF15803D),
      MobileMoneyPaymentStatus.rejected => const Color(0xFFB91C1C),
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(IntelliaSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    request.offerTitle,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: IntelliaSpacing.sm,
                    vertical: IntelliaSpacing.xxs,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    mobileMoneyStatusLabel(context, request.status),
                    style: TextStyle(color: color, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: IntelliaSpacing.xs),
            Text('${formatXaf(request.amountXaf)} • ${request.operatorLabel}'),
            Text(context.l10n.referenceValue(request.referenceHint)),
            if (request.reviewNote case final note?) ...[
              const SizedBox(height: IntelliaSpacing.xs),
              Text(context.l10n.schoolNote(note)),
            ],
          ],
        ),
      ),
    );
  }
}
