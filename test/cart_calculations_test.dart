import 'package:flutter_test/flutter_test.dart';
import 'package:khao_piyo_pos/features/orders/providers/cart_provider.dart';
import 'package:khao_piyo_pos/shared/models/menu_item.dart';

MenuItem _item(String id, double price) {
  return MenuItem(id: id, businessId: 'biz-1', categoryId: 'cat-1', name: 'Item $id', price: price);
}

void main() {
  group('CartState money math', () {
    test('subtotal sums item totals', () {
      final state = CartState(items: [
        CartItem(menuItem: _item('a', 50), quantity: 2), // 100
        CartItem(menuItem: _item('b', 30), quantity: 1), // 30
      ]);

      expect(state.subtotal, 130);
    });

    test('percentage discount is a fraction of subtotal', () {
      final state = CartState(
        items: [CartItem(menuItem: _item('a', 200), quantity: 1)],
        discountType: 'PERCENTAGE',
        discountValue: 10,
      );

      expect(state.discount, 20);
    });

    test('fixed discount is clamped to subtotal so total never goes negative', () {
      final state = CartState(
        items: [CartItem(menuItem: _item('a', 50), quantity: 1)],
        discountType: 'FIXED',
        discountValue: 500,
      );

      expect(state.discount, 50);
      expect(state.totalFor(0), 0);
    });

    test('no discount applied when discountType is null', () {
      final state = CartState(items: [CartItem(menuItem: _item('a', 100), quantity: 1)]);
      expect(state.discount, 0);
    });

    test('tax is computed on (subtotal - discount), not raw subtotal', () {
      final state = CartState(
        items: [CartItem(menuItem: _item('a', 100), quantity: 1)],
        discountType: 'FIXED',
        discountValue: 20,
      );

      // (100 - 20) * 10% = 8
      expect(state.taxFor(10), 8);
      // total = subtotal - discount + tax = 100 - 20 + 8 = 88
      expect(state.totalFor(10), 88);
    });

    test('zero tax rate leaves total as subtotal minus discount', () {
      final state = CartState(items: [CartItem(menuItem: _item('a', 75), quantity: 1)]);
      expect(state.totalFor(0), 75);
    });
  });
}
