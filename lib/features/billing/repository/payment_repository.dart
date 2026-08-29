import 'package:khao_piyo_pos/shared/models/payment.dart';

abstract class PaymentRepository {
  Future<List<Payment>> getPaymentsForOrder(String orderId);
  Future<double> getTotalPaid(String orderId);
  Future<void> addPayment(Payment payment);
}
