import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:khao_piyo_pos/core/sync/sync_status_provider.dart';
import 'package:khao_piyo_pos/core/theme/app_theme.dart';

/// A live, honest reflection of the sync engine's real state -- not a
/// decorative dot. Tapping it explains what the state means, since "3
/// pending" is meaningless to a cashier without context.
class SyncStatusChip extends ConsumerWidget {
  const SyncStatusChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(syncStatusProvider);

    return statusAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (status) {
        final (color, icon, label) = switch (status.state) {
          SyncState.offline => (Theme.of(context).colorScheme.onSurfaceVariant, Icons.cloud_off_rounded, 'Offline'),
          SyncState.syncing => (AppTheme.warning, Icons.sync_rounded, 'Syncing ${status.pendingCount}'),
          SyncState.synced => (AppTheme.success, Icons.cloud_done_rounded, 'Synced'),
        };

        return InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radius),
          onTap: () => _explain(context, status),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppTheme.radius),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 14, color: color),
                const SizedBox(width: 6),
                Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
              ],
            ),
          ),
        );
      },
    );
  }

  void _explain(BuildContext context, SyncStatus status) {
    final message = switch (status.state) {
      SyncState.offline => "No connection right now. Orders keep working normally and will sync automatically once you're back online.",
      SyncState.syncing => '${status.pendingCount} change${status.pendingCount == 1 ? '' : 's'} waiting to reach your other devices -- syncs automatically in the background.',
      SyncState.synced => 'Everything is up to date across all your devices.',
    };
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}
