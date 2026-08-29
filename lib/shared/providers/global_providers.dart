import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:khao_piyo_pos/core/database/database.dart';
import 'package:khao_piyo_pos/features/menu/repository/menu_repository.dart';
import 'package:khao_piyo_pos/features/menu/repository/local_menu_repository.dart';
import 'package:khao_piyo_pos/features/orders/repository/order_repository.dart';
import 'package:khao_piyo_pos/features/orders/repository/local_order_repository.dart';
import 'package:khao_piyo_pos/core/sync/sync_service.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

final menuRepositoryProvider = Provider<MenuRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return LocalMenuRepository(db);
});

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  final db = ref.watch(databaseProvider);
  final syncService = ref.watch(syncServiceProvider);
  return LocalOrderRepository(db, syncService);
});

// Needs to be overridden in main() after SharedPreferences.getInstance()
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError();
});

final currentBusinessIdProvider = StateProvider<String?>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return prefs.getString('business_id');
});

final authStateProvider = Provider<bool>((ref) {
  final businessId = ref.watch(currentBusinessIdProvider);
  return businessId != null;
});
