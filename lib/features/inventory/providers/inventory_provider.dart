import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:khao_piyo_pos/shared/models/ingredient.dart';
import 'package:khao_piyo_pos/shared/providers/global_providers.dart';

final ingredientsProvider = FutureProvider.autoDispose<List<Ingredient>>((ref) async {
  final businessId = ref.watch(currentBusinessIdProvider);
  if (businessId == null) return [];
  return ref.watch(inventoryRepositoryProvider).getIngredients(businessId);
});

final lowStockIngredientsProvider = FutureProvider.autoDispose<List<Ingredient>>((ref) async {
  final ingredients = await ref.watch(ingredientsProvider.future);
  return ingredients.where((i) => i.isLowStock).toList();
});
