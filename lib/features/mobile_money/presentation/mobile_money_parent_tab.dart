import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/design_tokens.dart';
import '../../../core/widgets/intellia_state_view.dart';
import '../application/mobile_money_providers.dart';
import '../data/mobile_money_repository.dart';
import '../domain/mobile_money_models.dart';

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
      loading: () => const IntelliaStateView(
        kind: IntelliaStateKind.loading,
        title: 'Chargement de l’offre',
      ),
      error: (error, stackTrace) => IntelliaStateView(
        kind: IntelliaStateKind.errorRetryable,
        title: 'Service indisponible',
        message: error is MobileMoneyException
            ? error.message
            : 'Impossible de vérifier l’offre pour le moment.',
        primaryLabel: 'Réessayer',
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
          'Abonnement',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: IntelliaSpacing.xs),
        Text(
          'Paiement Mobile Money déclaré puis vérifié manuellement par votre établissement.',
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
            'Mes demandes',
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
      return const _UnavailableOffer(
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
                'Accès pendant ${offer.durationDays} jours après validation',
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
                  '1. Effectuez le transfert',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: IntelliaSpacing.sm),
                DropdownButtonFormField<String>(
                  initialValue: operator.code,
                  decoration: const InputDecoration(
                    labelText: 'Opérateur',
                    prefixIcon: Icon(Icons.sim_card_outlined),
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
                  subtitle: const Text('Numéro bénéficiaire configuré'),
                  trailing: IconButton(
                    tooltip: 'Copier le numéro',
                    onPressed: () async {
                      await Clipboard.setData(
                        ClipboardData(text: operator.recipientPhone),
                      );
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Numéro copié.')),
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
                  child: const Text(
                    'Intellia237 ne déclenche aucun débit. Réalisez vous-même le transfert dans l’application de votre opérateur et vérifiez le numéro avant de confirmer.',
                  ),
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
                  '2. Envoyez la preuve de transfert',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: IntelliaSpacing.sm),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  autofillHints: const [AutofillHints.telephoneNumber],
                  decoration: const InputDecoration(
                    labelText: 'Numéro ayant effectué le transfert',
                    hintText: '6XX XXX XXX',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
                const SizedBox(height: IntelliaSpacing.sm),
                TextField(
                  controller: _referenceController,
                  textCapitalization: TextCapitalization.characters,
                  autocorrect: false,
                  decoration: const InputDecoration(
                    labelText: 'Référence de transaction',
                    prefixIcon: Icon(Icons.receipt_long_outlined),
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
                        ? 'Envoi en cours…'
                        : 'Transmettre pour vérification',
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
        const SnackBar(
          content: Text('Saisissez le téléphone et la référence du transfert.'),
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirmer la déclaration'),
        content: Text(
          'Vous déclarez avoir transféré ${formatXaf(offer.amountXaf)} via ${operator.label} vers ${operator.recipientPhone}. Aucune somme ne sera débitée par Intellia237.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Confirmer'),
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
        const SnackBar(
          content: Text(
            'Demande transmise. L’accès sera activé uniquement après vérification.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error is MobileMoneyException
                ? error.message
                : 'Envoi impossible pour le moment.',
          ),
        ),
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
        'Aucun établissement validé n’est encore lié à ce compte parent.',
      MobileMoneyAvailability.multipleSchools =>
        'Plusieurs établissements sont liés. Contactez l’assistance pour choisir celui qui facturera l’accès.',
      _ =>
        'Votre établissement n’a pas encore publié d’offre Mobile Money active.',
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
              'Offre indisponible',
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
                    request.status.label,
                    style: TextStyle(color: color, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: IntelliaSpacing.xs),
            Text('${formatXaf(request.amountXaf)} • ${request.operatorLabel}'),
            Text('Référence ${request.referenceHint}'),
            if (request.reviewNote case final note?) ...[
              const SizedBox(height: IntelliaSpacing.xs),
              Text('Note de l’établissement : $note'),
            ],
          ],
        ),
      ),
    );
  }
}
