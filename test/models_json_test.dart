import 'package:flutter_test/flutter_test.dart';
import 'package:khao_piyo_pos/shared/models/customer.dart';
import 'package:khao_piyo_pos/shared/models/ingredient.dart';
import 'package:khao_piyo_pos/shared/models/order.dart';
import 'package:khao_piyo_pos/shared/models/payment.dart';
import 'package:khao_piyo_pos/shared/models/restaurant_table.dart';

void main() {
  group('JSON round-trips (these are what the sync engine pushes/pulls)', () {
    test('Order survives toJson -> fromJson', () {
      final order = Order(
        id: 'order-1',
        businessId: 'biz-1',
        orderNumber: '260829-A1-001',
        orderType: 'DINE_IN',
        tableNumber: '4',
        status: 'NEW',
        paymentStatus: 'UNPAID',
        subtotal: 100,
        tax: 5,
        discount: 10,
        total: 95,
        createdByDevice: 'device-1',
        createdAt: DateTime.utc(2026, 8, 29, 10, 0),
        updatedAt: DateTime.utc(2026, 8, 29, 10, 0),
        customerId: 'cust-1',
        discountType: 'FIXED',
        discountReason: 'loyalty',
      );

      final restored = Order.fromJson(order.toJson());

      expect(restored.id, order.id);
      expect(restored.orderNumber, order.orderNumber);
      expect(restored.tableNumber, order.tableNumber);
      expect(restored.total, order.total);
      expect(restored.createdAt, order.createdAt);
      expect(restored.discountType, order.discountType);
    });

    test('Order.toJson always encodes timestamps as UTC, even from a local DateTime', () {
      // Every production timestamp starts life as DateTime.now() -- local,
      // not UTC. Supabase's timestamptz columns interpret a timezone-less
      // ISO string as if it were already UTC, so serializing a local
      // DateTime's wall-clock fields verbatim silently shifts the stored
      // instant by the device's UTC offset (this was a real bug: it showed
      // up as a kitchen ticket reporting a *negative* elapsed time). The
      // fix is calling .toUtc() before .toIso8601String(); this test pins
      // that down at the encoding level, which a same-process round-trip
      // through Order.fromJson wouldn't catch on its own since Dart parses
      // its own un-marked string back the same (wrong) way it wrote it.
      final localNow = DateTime(2026, 8, 29, 21, 38, 0);
      final order = Order(
        id: 'order-3',
        businessId: 'biz-1',
        orderNumber: '260829-C1-001',
        orderType: 'COUNTER',
        status: 'NEW',
        paymentStatus: 'UNPAID',
        subtotal: 50,
        tax: 0,
        discount: 0,
        total: 50,
        createdAt: localNow,
        updatedAt: localNow,
      );

      final encoded = order.toJson()['created_at'] as String;

      expect(encoded.endsWith('Z'), isTrue, reason: 'created_at must be UTC-marked, got "$encoded"');
      expect(DateTime.parse(encoded).isAtSameMomentAs(localNow), isTrue);
    });

    test('Order.fromJson handles Supabase snake_case keys and null timestamps', () {
      final json = {
        'id': 'order-2',
        'business_id': 'biz-1',
        'order_number': '260829-B2-001',
        'order_type': 'TAKEAWAY',
        'table_number': null,
        'status': 'COMPLETED',
        'payment_status': 'PAID',
        'subtotal': 50,
        'tax': 0,
        'discount': 0,
        'total': 50,
        'created_by_device': null,
        'created_at': null,
        'updated_at': null,
        'customer_id': null,
        'discount_type': null,
        'discount_reason': null,
      };

      final order = Order.fromJson(json);
      expect(order.tableNumber, isNull);
      expect(order.createdAt, isNull);
      expect(order.total, 50);
    });

    test('Payment survives toJson -> fromJson', () {
      final payment = Payment(
        id: 'pay-1',
        orderId: 'order-1',
        businessId: 'biz-1',
        paymentMethod: 'CASH',
        amount: 42.5,
        paymentTime: DateTime.utc(2026, 8, 29, 11, 0),
        deviceId: 'device-1',
      );

      final restored = Payment.fromJson(payment.toJson());
      expect(restored.amount, 42.5);
      expect(restored.paymentMethod, 'CASH');
      expect(restored.paymentTime, payment.paymentTime);
    });

    test('Ingredient.isLowStock reflects the threshold after a round-trip', () {
      final ingredient = Ingredient(
        id: 'ing-1',
        businessId: 'biz-1',
        name: 'Flour',
        unit: 'kg',
        currentStock: 2,
        lowStockThreshold: 5,
      );

      final restored = Ingredient.fromJson(ingredient.toJson());
      expect(restored.isLowStock, isTrue);
    });

    test('Customer numeric fields default sensibly when absent from remote payload', () {
      final customer = Customer.fromJson({
        'id': 'cust-1',
        'business_id': 'biz-1',
        'phone': '9990001111',
        'name': null,
      });

      expect(customer.totalSpent, 0);
      expect(customer.totalOrders, 0);
      expect(customer.loyaltyPoints, 0);
    });

    test('RestaurantTable survives toJson -> fromJson', () {
      final table = RestaurantTable(
        id: 'table-1',
        businessId: 'biz-1',
        name: 'VIP',
        sortOrder: 3,
        createdAt: DateTime.utc(2026, 8, 30, 9, 0),
        updatedAt: DateTime.utc(2026, 8, 30, 9, 0),
      );

      final restored = RestaurantTable.fromJson(table.toJson());
      expect(restored.name, 'VIP');
      expect(restored.sortOrder, 3);
      expect(restored.deletedAt, isNull);
    });
  });
}
