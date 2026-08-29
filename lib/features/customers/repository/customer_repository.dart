import 'package:khao_piyo_pos/shared/models/customer.dart';

abstract class CustomerRepository {
  Future<List<Customer>> getCustomers(String businessId);
  Future<Customer?> getCustomerByPhone(String businessId, String phone);
  Future<Customer?> getCustomer(String customerId);
  Future<void> addCustomer(Customer customer);
  Future<void> upsertCustomer(Customer customer);

  /// Records a completed sale against a customer: bumps totalSpent,
  /// totalOrders, loyaltyPoints and lastVisit.
  Future<void> recordSale(String customerId, {required double amountSpent, required int pointsEarned});
}
