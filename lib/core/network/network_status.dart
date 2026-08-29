import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final connectivityResultsProvider = StreamProvider<List<ConnectivityResult>>((
  ref,
) async* {
  final connectivity = Connectivity();
  yield await connectivity.checkConnectivity();
  yield* connectivity.onConnectivityChanged;
});

final isOfflineProvider = Provider<bool>((ref) {
  final results = ref.watch(connectivityResultsProvider).valueOrNull;
  return results != null &&
      (results.isEmpty ||
          results.every((item) => item == ConnectivityResult.none));
});
