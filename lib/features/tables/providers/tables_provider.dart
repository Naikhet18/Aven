import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:khao_piyo_pos/shared/models/restaurant_table.dart';
import 'package:khao_piyo_pos/shared/providers/global_providers.dart';

final tablesProvider = FutureProvider.autoDispose<List<RestaurantTable>>((ref) async {
  final businessId = ref.watch(currentBusinessIdProvider);
  if (businessId == null) return [];
  return ref.watch(tableRepositoryProvider).getTables(businessId);
});
