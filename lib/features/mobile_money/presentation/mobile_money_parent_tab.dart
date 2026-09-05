import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/design_tokens.dart';
import '../../../core/localization/localization_extensions.dart';
import '../../../core/widgets/intellia_state_view.dart';
import '../application/mobile_money_providers.dart';
import '../data/mobile_money_repository.dart';
import '../domain/mobile_money_models.dart';
import 'mobile_money_localization.dart';

class MobileMoneyParentTab extends ConsumerStatefulWidget {
  const MobileMoneyParentTab({super.key});

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

  @override
  void initState() {
    super.initState();
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

  void _resetIdempotencyKey() {
    _clientRequestId = null;
  }

  @override
  Widget build(BuildContext context) {
    final overview = ref.watch(parentMobileMoneyOverviewProvider);
    return overview.when(
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
      data: (data) => _buildOverview(context, data),
    );
  }

  Widget _buildOverview(BuildContext context, MobileMoneyOverview overview) {
    final offer = overview.offer;
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
        if (offer == null)
          _UnavailableOffer(availability: overview.availability)
        else
          _buildOfferForm(context, offer),
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

  Widget _buildOfferForm(BuildContext context, MobileMoneyOffer offer) {
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
                      : () => _confirmAndSubmit(offer, operator),
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
    MobileMoneyOperator operator,
  ) async {
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
