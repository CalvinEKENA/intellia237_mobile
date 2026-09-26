import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/application/auth_controller.dart';
import '../../features/control_plane/api_contracts.dart';
import '../../features/control_plane/control_plane_client.dart';
import '../../features/control_plane/real_control_plane_api.dart';
import 'firestore_rest_client.dart';

final firestoreRestClientProvider = Provider<FirestoreRestClient>((ref) {
  return FirestoreRestClient(
    sessionProvider: () => ref.read(authSessionProvider).asData?.value,
    tokenRefresher: () =>
        ref.read(authSessionProvider.notifier).refreshSession(),
    onSessionExpired: () => ref.read(authSessionProvider.notifier).signOut(),
  );
});

final controlPlaneClientProvider = Provider<ControlPlaneClient>((ref) {
  return ControlPlaneClient(
    sessionProvider: () => ref.read(authSessionProvider).asData?.value,
    tokenRefresher: () =>
        ref.read(authSessionProvider.notifier).refreshSession(),
    onSessionExpired: () => ref.read(authSessionProvider.notifier).signOut(),
  );
});

final controlPlaneApiProvider = Provider<ControlPlaneApi>((ref) {
  final cpClient = ref.watch(controlPlaneClientProvider);
  final fsClient = ref.watch(firestoreRestClientProvider);
  return RealControlPlaneApi(
    controlPlaneClient: cpClient,
    firestoreClient: fsClient,
  );
});
