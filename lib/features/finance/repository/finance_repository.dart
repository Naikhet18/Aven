import 'package:khao_piyo_pos/shared/models/expense.dart';
import 'package:khao_piyo_pos/shared/models/supplier.dart';

abstract class FinanceRepository {
  Future<List<Supplier>> getSuppliers(String businessId);
  Future<void> addSupplier(Supplier supplier);
  Future<void> updateSupplier(Supplier supplier);
  Future<void> deleteSupplier(String supplierId);

  Future<List<Expense>> getExpenses(String businessId, {DateTime? start, DateTime? end});
  Future<void> addExpense(Expense expense);
  Future<double> getTotalExpenses(String businessId, DateTime start, DateTime end);
}
