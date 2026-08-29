import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:khao_piyo_pos/core/audit/audit_log_service.dart';
import 'package:khao_piyo_pos/core/database/database.dart';
import 'package:khao_piyo_pos/core/device/device_identity.dart';
import 'package:khao_piyo_pos/core/sync/sync_service.dart';
import 'package:khao_piyo_pos/features/billing/repository/local_payment_repository.dart';
import 'package:khao_piyo_pos/features/billing/repository/payment_repository.dart';
import 'package:khao_piyo_pos/features/customers/repository/customer_repository.dart';
import 'package:khao_piyo_pos/features/customers/repository/local_customer_repository.dart';
import 'package:khao_piyo_pos/features/finance/repository/finance_repository.dart';
import 'package:khao_piyo_pos/features/finance/repository/local_finance_repository.dart';
import 'package:khao_piyo_pos/features/inventory/repository/inventory_repository.dart';
import 'package:khao_piyo_pos/features/inventory/repository/local_inventory_repository.dart';
import 'package:khao_piyo_pos/features/menu/repository/local_menu_repository.dart';
import 'package:khao_piyo_pos/features/menu/repository/menu_repository.dart';
import 'package:khao_piyo_pos/features/orders/repository/local_order_repository.dart';
import 'package:khao_piyo_pos/features/orders/repository/order_repository.dart';
import 'package:khao_piyo_pos/shared/models/audit_log.dart';
import 'package:khao_piyo_pos/shared/models/category.dart';
import 'package:khao_piyo_pos/shared/models/customer.dart';
import 'package:khao_piyo_pos/shared/models/expense.dart';
import 'package:khao_piyo_pos/shared/models/ingredient.dart';
import 'package:khao_piyo_pos/shared/models/inventory_transaction.dart';
import 'package:khao_piyo_pos/shared/models/menu_item.dart';
import 'package:khao_piyo_pos/shared/models/order.dart';
import 'package:khao_piyo_pos/shared/models/order_item.dart';
import 'package:khao_piyo_pos/shared/models/payment.dart';
import 'package:khao_piyo_pos/shared/models/supplier.dart';

// Needs to be overridden in main() after SharedPreferences.getInstance()
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError();
});

final supabaseClientProvider = Provider<SupabaseClient>((ref) => Supabase.instance.client);

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

final deviceIdentityProvider = Provider<DeviceIdentity>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return DeviceIdentity(prefs);
});

final currentBusinessIdProvider = StateProvider<String?>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return prefs.getString('business_id');
});

final authStateProvider = Provider<bool>((ref) {
  final businessId = ref.watch(currentBusinessIdProvider);
  return businessId != null;
});

/// The sync engine itself. Repositories below push through this; the
/// [syncRegistryProvider] wires their pull-merge handlers into it afterwards
/// to avoid a constructor cycle (repos need the sync service to push; the
/// sync service needs the repos' upsert methods to pull).
final syncServiceProvider = Provider<SyncService>((ref) {
  final db = ref.watch(databaseProvider);
  final supabase = ref.watch(supabaseClientProvider);
  final prefs = ref.watch(sharedPreferencesProvider);
  final service = SyncService(db, supabase, prefs);
  ref.onDispose(service.dispose);
  return service;
});

final menuRepositoryProvider = Provider<MenuRepository>((ref) {
  final db = ref.watch(databaseProvider);
  final syncService = ref.watch(syncServiceProvider);
  return LocalMenuRepository(db, syncService);
});

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  final db = ref.watch(databaseProvider);
  final syncService = ref.watch(syncServiceProvider);
  return LocalOrderRepository(db, syncService);
});

final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  final db = ref.watch(databaseProvider);
  final syncService = ref.watch(syncServiceProvider);
  return LocalCustomerRepository(db, syncService);
});

final inventoryRepositoryProvider = Provider<InventoryRepository>((ref) {
  final db = ref.watch(databaseProvider);
  final syncService = ref.watch(syncServiceProvider);
  return LocalInventoryRepository(db, syncService);
});

final financeRepositoryProvider = Provider<FinanceRepository>((ref) {
  final db = ref.watch(databaseProvider);
  final syncService = ref.watch(syncServiceProvider);
  return LocalFinanceRepository(db, syncService);
});

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  final db = ref.watch(databaseProvider);
  final syncService = ref.watch(syncServiceProvider);
  return LocalPaymentRepository(db, syncService);
});

final auditLogServiceProvider = Provider<AuditLogService>((ref) {
  final db = ref.watch(databaseProvider);
  final syncService = ref.watch(syncServiceProvider);
  return AuditLogService(db, syncService);
});

/// Reading this provider once (see `main.dart`) wires every repository's
/// pull-merge handler into the sync engine's registry. This is the piece
/// that breaks the sync-service/repository constructor cycle: everything
/// above only pushes; this is what makes pulling and realtime actually work.
final syncRegistryProvider = Provider<void>((ref) {
  final syncService = ref.watch(syncServiceProvider);
  final menuRepo = ref.watch(menuRepositoryProvider) as LocalMenuRepository;
  final orderRepo = ref.watch(orderRepositoryProvider) as LocalOrderRepository;
  final customerRepo = ref.watch(customerRepositoryProvider) as LocalCustomerRepository;
  final inventoryRepo = ref.watch(inventoryRepositoryProvider) as LocalInventoryRepository;
  final financeRepo = ref.watch(financeRepositoryProvider) as LocalFinanceRepository;
  final paymentRepo = ref.watch(paymentRepositoryProvider) as LocalPaymentRepository;
  final auditLogService = ref.watch(auditLogServiceProvider);

  syncService.registerSyncable(SyncableTable(
    table: 'categories',
    upsertFromRemote: (row) => menuRepo.upsertCategoryFromRemote(Category.fromJson(row)),
  ));
  syncService.registerSyncable(SyncableTable(
    table: 'menu_items',
    upsertFromRemote: (row) => menuRepo.upsertMenuItemFromRemote(MenuItem.fromJson(row)),
  ));
  syncService.registerSyncable(SyncableTable(
    table: 'orders',
    upsertFromRemote: (row) => orderRepo.upsertOrderFromRemote(Order.fromJson(row)),
  ));
  syncService.registerSyncable(SyncableTable(
    table: 'customers',
    upsertFromRemote: (row) => customerRepo.upsertCustomerFromRemote(Customer.fromJson(row)),
  ));
  syncService.registerSyncable(SyncableTable(
    table: 'ingredients',
    upsertFromRemote: (row) => inventoryRepo.upsertIngredientFromRemote(Ingredient.fromJson(row)),
  ));
  syncService.registerSyncable(SyncableTable(
    table: 'inventory_transactions',
    timestampColumn: 'created_at',
    upsertFromRemote: (row) => inventoryRepo.upsertTransactionFromRemote(InventoryTransaction.fromJson(row)),
  ));
  syncService.registerSyncable(SyncableTable(
    table: 'suppliers',
    upsertFromRemote: (row) => financeRepo.upsertSupplierFromRemote(Supplier.fromJson(row)),
  ));
  syncService.registerSyncable(SyncableTable(
    table: 'expenses',
    timestampColumn: 'created_at',
    upsertFromRemote: (row) => financeRepo.upsertExpenseFromRemote(Expense.fromJson(row)),
  ));
  syncService.registerSyncable(SyncableTable(
    table: 'payments',
    timestampColumn: 'created_at',
    upsertFromRemote: (row) => paymentRepo.upsertPaymentFromRemote(Payment.fromJson(row)),
  ));
  syncService.registerSyncable(SyncableTable(
    table: 'audit_logs',
    timestampColumn: 'created_at',
    upsertFromRemote: (row) => auditLogService.upsertFromRemote(AuditLog.fromJson(row)),
  ));

  syncService.onOrderUpserted = (orderId) async {
    final supabase = ref.read(supabaseClientProvider);
    final rows = await supabase.from('order_items').select().eq('order_id', orderId);
    for (final row in rows) {
      await orderRepo.upsertOrderItem(OrderItem.fromJson(row));
    }
  };
});
