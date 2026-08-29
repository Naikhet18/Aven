// Widget test for DiscountDialog: the previous version of this file was the
// unmodified `flutter create` counter-app template and tested a widget
// (`find.byIcon(Icons.add)` / a "+1" counter) that has never existed in this
// app.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khao_piyo_pos/features/orders/providers/cart_provider.dart';
import 'package:khao_piyo_pos/features/orders/widgets/discount_dialog.dart';
import 'package:khao_piyo_pos/shared/models/menu_item.dart';

void main() {
  testWidgets('applying a percentage discount updates cart state', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(cartProvider.notifier).addItem(
          const MenuItem(id: 'a', businessId: 'biz-1', categoryId: 'cat-1', name: 'Tea', price: 100),
        );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: DiscountDialog()),
      ),
    );

    // Percentage is selected by default; enter 15% and apply.
    await tester.enterText(find.byType(TextField).first, '15');
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();

    final cartState = container.read(cartProvider);
    expect(cartState.discountType, 'PERCENTAGE');
    expect(cartState.discountValue, 15);
    expect(cartState.discount, 15); // 15% of a 100 subtotal
  });

  testWidgets('removing an applied discount clears it', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(cartProvider.notifier)
      ..addItem(const MenuItem(id: 'a', businessId: 'biz-1', categoryId: 'cat-1', name: 'Tea', price: 100))
      ..applyDiscount(type: 'FIXED', value: 20);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: DiscountDialog()),
      ),
    );

    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();

    expect(container.read(cartProvider).discountType, isNull);
  });
}
