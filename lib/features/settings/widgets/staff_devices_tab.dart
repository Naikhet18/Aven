import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:khao_piyo_pos/core/utils/join_code.dart';
import 'package:khao_piyo_pos/shared/providers/global_providers.dart';

final _joinCodeProvider = FutureProvider.autoDispose<String?>((ref) async {
  final businessId = ref.watch(currentBusinessIdProvider);
  if (businessId == null) return null;
  final client = ref.watch(supabaseClientProvider);
  final row = await client.from('businesses').select('join_code').eq('id', businessId).single();
  return row['join_code'] as String?;
});

final _connectedDevicesProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final businessId = ref.watch(currentBusinessIdProvider);
  if (businessId == null) return [];
  final client = ref.watch(supabaseClientProvider);
  final rows = await client.from('devices').select().eq('business_id', businessId).order('last_seen', ascending: false);
  return (rows as List).cast<Map<String, dynamic>>();
});

/// Owner-only: shows the restaurant join code + QR staff use to add their
/// own device with no password, plus which devices are currently connected.
/// Needs the network (the join code lives on the `businesses` row, which --
/// unlike orders/menu/etc. -- isn't mirrored into the local offline cache;
/// this is an infrequent admin action, not a core POS flow).
class StaffDevicesTab extends ConsumerWidget {
  const StaffDevicesTab({super.key});

  Future<void> _regenerateCode(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Regenerate code?'),
        content: const Text('The old code will stop working immediately. Devices already joined are not affected.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Regenerate')),
        ],
      ),
    );
    if (confirmed != true) return;

    final businessId = ref.read(currentBusinessIdProvider);
    if (businessId == null) return;
    final client = ref.read(supabaseClientProvider);

    for (var attempt = 0; attempt < 5; attempt++) {
      try {
        await client.from('businesses').update({'join_code': JoinCode.generate()}).eq('id', businessId);
        break;
      } catch (_) {
        if (attempt == 4 && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not regenerate the code. Try again.')));
        }
      }
    }
    ref.invalidate(_joinCodeProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final codeAsync = ref.watch(_joinCodeProvider);
    final devicesAsync = ref.watch(_connectedDevicesProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Restaurant Code', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('Staff enter this code (or scan the QR) on their own device to join instantly -- no password needed.'),
        const SizedBox(height: 16),
        codeAsync.when(
          loading: () => const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator())),
          error: (err, _) => Text('Could not load the code. Check your connection.\n$err'),
          data: (code) {
            if (code == null) return const Text('No code yet.');
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    QrImageView(data: 'khaopiyo://join/$code', size: 180),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          code,
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 4, fontFeatures: [FontFeature.tabularFigures()]),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy_outlined),
                          tooltip: 'Copy code',
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: code));
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Code copied.')));
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () => _regenerateCode(context, ref),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Regenerate code'),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const Divider(height: 48),
        Text('Connected Devices', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        devicesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Text('Error: $err'),
          data: (devices) {
            if (devices.isEmpty) return const Text('No devices yet.');
            return Column(
              children: devices.map((d) {
                final lastSeen = d['last_seen'] != null ? DateTime.tryParse(d['last_seen'] as String) : null;
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.smartphone_outlined),
                    title: Text(d['device_name'] as String? ?? 'Unknown device'),
                    subtitle: Text(
                      '${d['platform'] ?? ''}${lastSeen != null ? ' • Last seen ${DateFormat('dd MMM, hh:mm a').format(lastSeen)}' : ''}',
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}
