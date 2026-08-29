import 'package:drift/drift.dart';
import 'package:drift_sqflite/drift_sqflite.dart';

part 'database.g.dart';

@DataClassName('CategoryEntity')
class Categories extends Table {
  TextColumn get id => text()();
  TextColumn get businessId => text()();
  TextColumn get name => text()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime().nullable()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('MenuItemEntity')
class MenuItems extends Table {
  TextColumn get id => text()();
  TextColumn get businessId => text()();
  TextColumn get categoryId => text()();
  TextColumn get name => text()();
  RealColumn get price => real()();
  BoolColumn get isAvailable => boolean().withDefault(const Constant(true))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime().nullable()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('OrderEntity')
class Orders extends Table {
  TextColumn get id => text()();
  TextColumn get businessId => text()();
  TextColumn get orderNumber => text()();
  TextColumn get orderType => text()();
  TextColumn get tableNumber => text().nullable()();
  TextColumn get status => text()();
  TextColumn get paymentStatus => text()();
  RealColumn get subtotal => real()();
  RealColumn get tax => real()();
  RealColumn get discount => real()();
  RealColumn get total => real()();
  TextColumn get createdByDevice => text().nullable()();
  TextColumn get customerId => text().nullable()();
  TextColumn get discountType => text().nullable()();
  TextColumn get discountReason => text().nullable()();
  DateTimeColumn get createdAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('OrderItemEntity')
class OrderItems extends Table {
  TextColumn get id => text()();
  TextColumn get orderId => text()();
  TextColumn get menuItemId => text()();
  TextColumn get itemNameSnapshot => text()();
  RealColumn get unitPrice => real()();
  RealColumn get quantity => real()();
  TextColumn get notes => text().nullable()();
  RealColumn get total => real()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('IngredientEntity')
class Ingredients extends Table {
  TextColumn get id => text()();
  TextColumn get businessId => text()();
  TextColumn get name => text()();
  TextColumn get unit => text()();
  RealColumn get currentStock => real().withDefault(const Constant(0))();
  RealColumn get lowStockThreshold => real().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime().nullable()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('RecipeEntity')
class Recipes extends Table {
  TextColumn get id => text()();
  TextColumn get menuItemId => text()();
  TextColumn get ingredientId => text()();
  RealColumn get quantityRequired => real()();
  DateTimeColumn get createdAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('InventoryTransactionEntity')
class InventoryTransactions extends Table {
  TextColumn get id => text()();
  TextColumn get businessId => text()();
  TextColumn get ingredientId => text()();
  TextColumn get transactionType => text()();
  RealColumn get quantityChange => real()();
  TextColumn get supplierId => text().nullable()();
  RealColumn get cost => real().nullable()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime().nullable()();
  TextColumn get createdByDevice => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('CustomerEntity')
class Customers extends Table {
  TextColumn get id => text()();
  TextColumn get businessId => text()();
  TextColumn get phone => text().nullable()();
  TextColumn get name => text().nullable()();
  RealColumn get totalSpent => real().withDefault(const Constant(0))();
  IntColumn get totalOrders => integer().withDefault(const Constant(0))();
  IntColumn get loyaltyPoints => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastVisit => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('ExpenseEntity')
class Expenses extends Table {
  TextColumn get id => text()();
  TextColumn get businessId => text()();
  TextColumn get category => text()();
  RealColumn get amount => real()();
  DateTimeColumn get expenseDate => dateTime()();
  TextColumn get supplierId => text().nullable()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime().nullable()();
  TextColumn get createdByDevice => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('SupplierEntity')
class Suppliers extends Table {
  TextColumn get id => text()();
  TextColumn get businessId => text()();
  TextColumn get name => text()();
  TextColumn get contactName => text().nullable()();
  TextColumn get phone => text().nullable()();
  TextColumn get email => text().nullable()();
  TextColumn get address => text().nullable()();
  DateTimeColumn get createdAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime().nullable()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('AuditLogEntity')
class AuditLogs extends Table {
  TextColumn get id => text()();
  TextColumn get businessId => text()();
  TextColumn get deviceId => text().nullable()();
  TextColumn get actionType => text()();
  TextColumn get details => text().nullable()(); // JSON string
  DateTimeColumn get createdAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('SyncOperationEntity')
class SyncOperations extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get operation => text()(); // INSERT, UPDATE, DELETE
  TextColumn get targetTable => text()();
  TextColumn get recordId => text()();
  TextColumn get payload => text()(); // JSON string of the record
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  TextColumn get status => text().withDefault(const Constant('PENDING'))(); // PENDING, FAILED
}

@DriftDatabase(tables: [
  Categories, 
  MenuItems, 
  Orders, 
  OrderItems,
  Ingredients,
  Recipes,
  InventoryTransactions,
  Customers,
  Expenses,
  Suppliers,
  AuditLogs,
  SyncOperations
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 2; // Incremented version
  
  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from == 1) {
          // We are in dev, simplest is just to recreate tables if needed, or add columns.
          // Since it's local dev, adding the new tables is fine.
          await m.createTable(ingredients);
          await m.createTable(recipes);
          await m.createTable(inventoryTransactions);
          await m.createTable(customers);
          await m.createTable(expenses);
          await m.createTable(suppliers);
          await m.createTable(auditLogs);
          await m.createTable(syncOperations);
          
          await m.addColumn(orders, orders.customerId);
          await m.addColumn(orders, orders.discountType);
          await m.addColumn(orders, orders.discountReason);
        }
      },
    );
  }
}

QueryExecutor _openConnection() {
  return SqfliteQueryExecutor.inDatabaseFolder(
    path: 'khaopiyo_pos.sqlite',
  );
}
