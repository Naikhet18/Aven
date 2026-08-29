import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:khao_piyo_pos/shared/models/customer.dart';
import 'package:khao_piyo_pos/shared/providers/global_providers.dart';

final customersProvider = FutureProvider.autoDispose<List<Customer>>((ref) async {
  final businessId = ref.watch(currentBusinessIdProvider);
  if (businessId == null) return [];
  return ref.watch(customerRepositoryProvider).getCustomers(businessId);
});
