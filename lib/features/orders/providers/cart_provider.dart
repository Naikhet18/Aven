import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:khao_piyo_pos/features/settings/providers/printer_provider.dart';
import 'package:khao_piyo_pos/features/settings/providers/settings_provider.dart';
import 'package:khao_piyo_pos/shared/models/customer.dart';
import 'package:khao_piyo_pos/shared/models/menu_item.dart';
import 'package:khao_piyo_pos/shared/models/order.dart';
import 'package:khao_piyo_pos/shared/models/order_item.dart';
import 'package:khao_piyo_pos/shared/models/payment.dart';
import 'package:khao_piyo_pos/shared/providers/global_providers.dart';

class CartItem {
  final MenuItem menuItem;
  final int quantity;
  final String? notes;

  CartItem({
    required this.menuItem,
    required this.quantity,
    this.notes,
  });

  CartItem copyWith({
    MenuItem? menuItem,
    int? quantity,
    String? notes,
  }) {
    return CartItem(
      menuItem: menuItem ?? this.menuItem,
      quantity: quantity ?? this.quantity,
      notes: notes ?? this.notes,
    );
  }

  double get total => menuItem.price * quantity;
}

class CartState {
  final List<CartItem> items;
  final String orderType; // DINE_IN, TAKEAWAY, COUNTER
  final String? tableNumber;
  final bool isSaving;
  final String? error;

  /// PERCENTAGE or FIXED. Null means no discount applied.
  final String? discountType;
  final double discountValue;
  final String? discountReason;

  final Customer? customer;

  CartState({
    this.items = const [],
    this.orderType = 'DINE_IN',
    this.tableNumber,
    this.isSaving = false,
    this.error,
    this.discountType,
    this.discountValue = 0,
    this.discountReason,
    this.customer,
  });

  double get subtotal => items.fold(0, (sum, item) => sum + item.total);

  double get discount {
    if (discountType == 'PERCENTAGE') return subtotal * (discountValue / 100);
    if (discountType == 'FIXED') return discountValue.clamp(0, subtotal);
    return 0;
  }

  double taxFor(double taxRatePercent) => (subtotal - discount) * (taxRatePercent / 100);

  double totalFor(double taxRatePercent) => subtotal - discount + taxFor(taxRatePercent);

  CartState copyWith({
    List<CartItem>? items,
    String? orderType,
    String? tableNumber,
    bool? isSaving,
    String? error,
    String? discountType,
    double? discountValue,
    String? discountReason,
    Customer? customer,
    bool clearDiscount = false,
    bool clearCustomer = false,
  }) {
    return CartState(
      items: items ?? this.items,
      orderType: orderType ?? this.orderType,
      tableNumber: tableNumber ?? this.tableNumber,
      isSaving: isSaving ?? this.isSaving,
      error: error,
      discountType: clearDiscount ? null : (discountType ?? this.discountType),
      discountValue: clearDiscount ? 0 : (discountValue ?? this.discountValue),
      discountReason: clearDiscount ? null : (discountReason ?? this.discountReason),
      customer: clearCustomer ? null : (customer ?? this.customer),
    );
  }

  CartState clearError() => copyWith(error: null);
}

class CartNotifier extends Notifier<CartState> {
  @override
  CartState build() {
    return CartState();
  }

  void addItem(MenuItem item) {
    final existingIndex = state.items.indexWhere((i) => i.menuItem.id == item.id);
    if (existingIndex >= 0) {
      final updatedItems = List<CartItem>.from(state.items);
      final existing = updatedItems[existingIndex];
      updatedItems[existingIndex] = existing.copyWith(quantity: existing.quantity + 1);
      state = state.copyWith(items: updatedItems);
    } else {
      state = state.copyWith(
        items: [...state.items, CartItem(menuItem: item, quantity: 1)],
      );
    }
  }

  void updateQuantity(MenuItem item, int newQuantity) {
    if (newQuantity <= 0) {
      removeItem(item);
      return;
    }

    final index = state.items.indexWhere((i) => i.menuItem.id == item.id);
    if (index >= 0) {
      final updatedItems = List<CartItem>.from(state.items);
      updatedItems[index] = updatedItems[index].copyWith(quantity: newQuantity);
      state = state.copyWith(items: updatedItems);
    }
  }

  void updateNotes(MenuItem item, String? notes) {
    final index = state.items.indexWhere((i) => i.menuItem.id == item.id);
    if (index >= 0) {
      final updatedItems = List<CartItem>.from(state.items);
      updatedItems[index] = updatedItems[index].copyWith(notes: notes);
      state = state.copyWith(items: updatedItems);
    }
  }

  void removeItem(MenuItem item) {
    final updatedItems = state.items.where((i) => i.menuItem.id != item.id).toList();
    state = state.copyWith(items: updatedItems);
  }

  void setOrderType(String type) {
    state = state.copyWith(orderType: type);
  }

  void setTableNumber(String? tableNumber) {
    state = state.copyWith(tableNumber: tableNumber);
  }

  void applyDiscount({required String type, required double value, String? reason}) {
    state = state.copyWith(discountType: type, discountValue: value, discountReason: reason);
  }

  void clearDiscount() {
    state = state.copyWith(clearDiscount: true);
  }

  void attachCustomer(Customer customer) {
    state = state.copyWith(customer: customer);
  }

  void detachCustomer() {
    state = state.copyWith(clearCustomer: true);
  }

  void clearCart() {
    state = CartState(orderType: state.orderType);
  }

  /// Saves the current cart as an order. Returns the created order on
  /// success (with its final items) so the caller can print a receipt
  /// immediately, or null on failure.
  Future<(Order, List<OrderItem>)?> saveOrder({String paymentStatus = 'UNPAID', String? paymentMethod}) async {
    if (state.items.isEmpty) return null;

    state = state.copyWith(isSaving: true, error: null);

    try {
      final businessId = ref.read(currentBusinessIdProvider);
      if (businessId == null) {
        state = state.copyWith(isSaving: false, error: 'No active business');
        return null;
      }

      final device = ref.read(deviceIdentityProvider);
      final taxRate = ref.read(settingsProvider).taxRatePercent;
      final orderRepo = ref.read(orderRepositoryProvider);

      final orderNumber = await orderRepo.generateNextOrderNumber(businessId, device.id, device.shortTag);
      final orderId = const Uuid().v4();
      final now = DateTime.now();
      final tax = state.taxFor(taxRate);
      final total = state.totalFor(taxRate);

      final order = Order(
        id: orderId,
        businessId: businessId,
        orderNumber: orderNumber,
        orderType: state.orderType,
        tableNumber: state.tableNumber,
        status: 'NEW',
        paymentStatus: paymentStatus,
        subtotal: state.subtotal,
        tax: tax,
        discount: state.discount,
        total: total,
        createdByDevice: device.id,
        createdAt: now,
        updatedAt: now,
        customerId: state.customer?.id,
        discountType: state.discountType,
        discountReason: state.discountReason,
      );

      final orderItems = state.items.map((cartItem) {
        return OrderItem(
          id: const Uuid().v4(),
          orderId: orderId,
          menuItemId: cartItem.menuItem.id,
          itemNameSnapshot: cartItem.menuItem.name,
          unitPrice: cartItem.menuItem.price,
          quantity: cartItem.quantity.toDouble(),
          notes: cartItem.notes,
          total: cartItem.total,
        );
      }).toList();

      await orderRepo.createOrder(order, orderItems);

      if (ref.read(printerConfigProvider).kotAutoPrint) {
        // Best-effort: a printer hiccup shouldn't block the order from saving.
        unawaited(ref.read(printerServiceProvider).printKitchenTicket(order, orderItems));
      }

      // Deduct stock for any item that has a recipe defined. Best-effort:
      // an inventory hiccup shouldn't block the order from being placed.
      try {
        await ref.read(inventoryRepositoryProvider).deductForOrder(
              businessId: businessId,
              orderId: orderId,
              orderItems: orderItems,
              deviceId: device.id,
            );
      } catch (_) {
        // Inventory tracking is best-effort; the order itself already saved.
      }

      if (paymentStatus == 'PAID' && paymentMethod != null) {
        await ref.read(paymentRepositoryProvider).addPayment(Payment(
              id: const Uuid().v4(),
              orderId: orderId,
              businessId: businessId,
              paymentMethod: paymentMethod,
              amount: total,
              paymentTime: now,
              deviceId: device.id,
            ));

        final customer = state.customer;
        if (customer != null) {
          final points = (total / ref.read(settingsProvider).loyaltyPointsPerCurrencyUnit).floor();
          try {
            await ref.read(customerRepositoryProvider).recordSale(
                  customer.id,
                  amountSpent: total,
                  pointsEarned: points,
                );
          } catch (_) {
            // Loyalty tracking is best-effort; the order/payment already saved.
          }
        }
      }

      clearCart();
      return (order, orderItems);
    } catch (e) {
      state = state.copyWith(isSaving: false, error: e.toString());
      return null;
    }
  }
}

final cartProvider = NotifierProvider<CartNotifier, CartState>(() {
  return CartNotifier();
});
