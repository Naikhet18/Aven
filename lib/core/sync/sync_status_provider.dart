import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:khao_piyo_pos/shared/providers/global_providers.dart';

enum SyncState { offline, syncing, synced }

class SyncStatus {
  final SyncState state;
  final int pendingCount;
  const SyncStatus({required this.state, required this.pendingCount});
}

/// Combines the sync engine's real pending-operations count with live
/// connectivity to drive a single honest status -- not a decorative dot.
/// "Synced" only shows when there's genuinely nothing queued and a network
/// path exists; "Syncing" reflects an actual queue depth a cashier can act
/// on (e.g. walk closer to the router) rather than a vague spinner.
final syncStatusProvider = StreamProvider<SyncStatus>((ref) {
  final syncService = ref.watch(syncServiceProvider);
  final controller = StreamController<SyncStatus>();

  var pending = 0;
  var online = true;

  void emit() {
    if (controller.isClosed) return;
    final state = !online ? SyncState.offline : (pending > 0 ? SyncState.syncing : SyncState.synced);
    controller.add(SyncStatus(state: state, pendingCount: pending));
  }

  Connectivity().checkConnectivity().then((result) {
    online = result.any((r) => r != ConnectivityResult.none);
    emit();
  });

  final connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
    online = results.any((r) => r != ConnectivityResult.none);
    emit();
  });

  final pendingSub = syncService.pendingCount.listen((count) {
    pending = count;
    emit();
  });

  ref.onDispose(() {
    connectivitySub.cancel();
    pendingSub.cancel();
    controller.close();
  });

  return controller.stream;
});
