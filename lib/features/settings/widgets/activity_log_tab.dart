import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:khao_piyo_pos/shared/models/audit_log.dart';
import 'package:khao_piyo_pos/shared/providers/global_providers.dart';

final recentActivityProvider = FutureProvider.autoDispose<List<AuditLog>>((ref) async {
  final businessId = ref.watch(currentBusinessIdProvider);
  if (businessId == null) return [];
  return ref.watch(auditLogServiceProvider).getRecent(businessId);
});

class ActivityLogTab extends ConsumerWidget {
  const ActivityLogTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(recentActivityProvider);

    return logsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error: $err')),
      data: (logs) {
        if (logs.isEmpty) {
          return const Center(child: Text('No activity recorded yet.'));
        }
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(recentActivityProvider),
          child: ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: logs.length,
            itemBuilder: (context, index) {
              final log = logs[index];
              return ListTile(
                leading: const Icon(Icons.fact_check_outlined),
                title: Text(_describe(log.actionType)),
                subtitle: log.details != null ? Text(log.details!, maxLines: 2, overflow: TextOverflow.ellipsis) : null,
                trailing: Text(
                  log.createdAt != null ? DateFormat('dd MMM, hh:mm a').format(log.createdAt!) : '',
                  style: const TextStyle(fontSize: 12),
                ),
              );
            },
          ),
        );
      },
    );
  }

  String _describe(String actionType) {
    switch (actionType) {
      case 'CANCEL_ORDER':
        return 'Order cancelled';
      case 'REFUND':
        return 'Refund issued';
      case 'MODIFY_STOCK':
        return 'Stock adjusted';
      case 'CHANGE_PRICE':
        return 'Price changed';
      default:
        return actionType;
    }
  }
}
