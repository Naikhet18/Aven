import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:khao_piyo_pos/shared/models/expense.dart';
import 'package:khao_piyo_pos/shared/models/supplier.dart';
import 'package:khao_piyo_pos/shared/providers/global_providers.dart';

final suppliersProvider = FutureProvider.autoDispose<List<Supplier>>((ref) async {
  final businessId = ref.watch(currentBusinessIdProvider);
  if (businessId == null) return [];
  return ref.watch(financeRepositoryProvider).getSuppliers(businessId);
});

final expensesProvider = FutureProvider.autoDispose<List<Expense>>((ref) async {
  final businessId = ref.watch(currentBusinessIdProvider);
  if (businessId == null) return [];
  return ref.watch(financeRepositoryProvider).getExpenses(businessId);
});
