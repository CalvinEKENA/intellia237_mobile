import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../core/theme/studio_theme.dart';
import '../../../core/widgets/studio_badge.dart';

enum ServiceProbeStatus { checking, reachable, unreachable, unknown }

class ServiceHealthProbe {
  final String serviceName;
  final String targetUrl;
  final ServiceProbeStatus status;
  final int? latencyMs;
  final String details;

  const ServiceHealthProbe({
    required this.serviceName,
    required this.targetUrl,
    required this.status,
    this.latencyMs,
    required this.details,
  });
}

final connectivityHealthProvider =
    StateNotifierProvider<ConnectivityHealthNotifier, List<ServiceHealthProbe>>(
      (ref) {
        return ConnectivityHealthNotifier();
      },
    );

class ConnectivityHealthNotifier
    extends StateNotifier<List<ServiceHealthProbe>> {
  ConnectivityHealthNotifier()
    : super([
        const ServiceHealthProbe(
          serviceName: 'Firebase Authentication REST API',
          targetUrl: 'https://identitytoolkit.googleapis.com',
          status: ServiceProbeStatus.checking,
          details: 'Vérification du service d\'authentification...',
        ),
        const ServiceHealthProbe(
          serviceName: 'Cloud Firestore REST Gateway',
          targetUrl: 'https://firestore.googleapis.com',
          status: ServiceProbeStatus.checking,
          details: 'Vérification de la passerelle Firestore...',
        ),
        const ServiceHealthProbe(
          serviceName: 'Control Plane Functions (europe-west1)',
          targetUrl: 'https://europe-west1-edunova-aabd1.cloudfunctions.net',
          status: ServiceProbeStatus.checking,
          details: 'Vérification du point d\'accès Cloud Functions...',
        ),
        const ServiceHealthProbe(
          serviceName: 'Cloud Storage Bucket (Assets Éducatifs)',
          targetUrl: 'https://storage.googleapis.com',
          status: ServiceProbeStatus.checking,
          details: 'Vérification de la disponibilité du bucket...',
        ),
      ]) {
    runProbes();
  }

  Future<void> runProbes() async {
    final updated = <ServiceHealthProbe>[];

    for (final probe in state) {
      final sw = Stopwatch()..start();
      try {
        final uri = Uri.parse(probe.targetUrl);
        final response = await http
            .get(uri)
            .timeout(const Duration(seconds: 4));
        sw.stop();
        final latency = sw.elapsedMilliseconds;

        // Even if 404 or 403, the endpoint is reachable at network level
        final isReachable =
            response.statusCode > 0 && response.statusCode < 500;
        updated.add(
          ServiceHealthProbe(
            serviceName: probe.serviceName,
            targetUrl: probe.targetUrl,
            status: isReachable
                ? ServiceProbeStatus.reachable
                : ServiceProbeStatus.unknown,
            latencyMs: latency,
            details: isReachable
                ? 'Point d\'accès joignable (HTTP ${response.statusCode})'
                : 'Réponse anormale (HTTP ${response.statusCode})',
          ),
        );
      } on SocketException catch (e) {
        sw.stop();
        updated.add(
          ServiceHealthProbe(
            serviceName: probe.serviceName,
            targetUrl: probe.targetUrl,
            status: ServiceProbeStatus.unreachable,
            latencyMs: sw.elapsedMilliseconds,
            details:
                'Erreur réseau socket : ${e.osError?.message ?? e.message}',
          ),
        );
      } on TimeoutException {
        sw.stop();
        updated.add(
          ServiceHealthProbe(
            serviceName: probe.serviceName,
            targetUrl: probe.targetUrl,
            status: ServiceProbeStatus.unreachable,
            latencyMs: sw.elapsedMilliseconds,
            details: 'Délai d\'attente dépassé (> 4s)',
          ),
        );
      } catch (e) {
        sw.stop();
        updated.add(
          ServiceHealthProbe(
            serviceName: probe.serviceName,
            targetUrl: probe.targetUrl,
            status: ServiceProbeStatus.unknown,
            latencyMs: sw.elapsedMilliseconds,
            details: 'Erreur de sonde: $e',
          ),
        );
      }
    }

    state = updated;
  }
}

class SystemHealthScreen extends ConsumerWidget {
  const SystemHealthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final probes = ref.watch(connectivityHealthProvider);
    final allReachable = probes.every(
      (p) => p.status == ServiceProbeStatus.reachable,
    );
    final hasUnreachable = probes.any(
      (p) => p.status == ServiceProbeStatus.unreachable,
    );

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Santé de Connectivité & Configuration',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Mesure objective de latence et joignabilité des services cloud (Production edunova-aabd1).',
                      style: TextStyle(color: StudioColors.textSecondaryLight),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Relancer les sondes',
                icon: const Icon(Icons.refresh_rounded),
                onPressed: () =>
                    ref.read(connectivityHealthProvider.notifier).runProbes(),
              ),
              const SizedBox(width: 8),
              StudioBadge(
                label: allReachable
                    ? 'POINTS D\'ACCÈS JOIGNABLES'
                    : (hasUnreachable
                          ? 'CONNECTIVITÉ DÉGRADÉE'
                          : 'VÉRIFICATION EN COURS'),
                variant: allReachable
                    ? StudioBadgeVariant.success
                    : (hasUnreachable
                          ? StudioBadgeVariant.error
                          : StudioBadgeVariant.warning),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: StudioColors.navyPrimary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: StudioColors.navyPrimary.withValues(alpha: 0.2),
              ),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: StudioColors.navyPrimary,
                  size: 20,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Transparence d\'Infrastructure : La joignabilité HTTP mesure l\'accessibilité réseau client-serveur et la latence aller-retour réelle. Elle ne remplace pas le monitoring interne des métriques Google Cloud.',
                    style: TextStyle(
                      fontSize: 12,
                      color: StudioColors.navyPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.separated(
              itemCount: probes.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (ctx, idx) {
                final probe = probes[idx];
                return Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: StudioColors.borderLight),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          probe.status == ServiceProbeStatus.reachable
                              ? Icons.check_circle_rounded
                              : (probe.status == ServiceProbeStatus.checking
                                    ? Icons.hourglass_top_rounded
                                    : Icons.cancel_rounded),
                          color: probe.status == ServiceProbeStatus.reachable
                              ? StudioColors.success
                              : (probe.status == ServiceProbeStatus.checking
                                    ? StudioColors.warning
                                    : StudioColors.error),
                          size: 24,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                probe.serviceName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${probe.details} • Latence : ${probe.latencyMs != null ? "${probe.latencyMs} ms" : "—"}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: StudioColors.textSecondaryLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                        StudioBadge(
                          label: probe.status == ServiceProbeStatus.reachable
                              ? 'JOIGNABLE'
                              : (probe.status == ServiceProbeStatus.checking
                                    ? 'SONDE...'
                                    : 'INACCESSIBLE'),
                          variant: probe.status == ServiceProbeStatus.reachable
                              ? StudioBadgeVariant.success
                              : (probe.status == ServiceProbeStatus.checking
                                    ? StudioBadgeVariant.warning
                                    : StudioBadgeVariant.error),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
