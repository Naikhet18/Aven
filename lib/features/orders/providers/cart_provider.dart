import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:khao_piyo_pos/shared/models/menu_item.dart';
import 'package:khao_piyo_pos/shared/models/order.dart';
import 'package:khao_piyo_pos/shared/models/order_item.dart';
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

  CartState({
    this.items = const [],
    this.orderType = 'DINE_IN',
    this.tableNumber,
    this.isSaving = false,
    this.error,
  });

  double get subtotal => items.fold(0, (sum, item) => sum + item.total);
  double get tax => 0.0; // Implement later
  double get discount => 0.0; // Implement later
  double get total => subtotal + tax - discount;

  CartState copyWith({
    List<CartItem>? items,
    String? orderType,
    String? tableNumber,
    bool? isSaving,
    String? error,
  }) {
    return CartState(
      items: items ?? this.items,
      orderType: orderType ?? this.orderType,
      tableNumber: tableNumber ?? this.tableNumber,
      isSaving: isSaving ?? this.isSaving,
      error: error, // intentionally don't default to this.error unless provided, wait no, let's just allow clearing
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

  void clearCart() {
    state = CartState(orderType: state.orderType);
  }

  Future<bool> saveOrder() async {
    if (state.items.isEmpty) return false;

    state = state.copyWith(isSaving: true, error: null);

    try {
      final businessId = ref.read(currentBusinessIdProvider);
      if (businessId == null) {
        state = state.copyWith(isSaving: false, error: 'No active business');
        return false;
      }
      
      final repo = ref.read(orderRepositoryProvider);
      
      final orderNumber = await repo.generateNextOrderNumber(businessId);
      final orderId = const Uuid().v4();
      final now = DateTime.now();

      final order = Order(
        id: orderId,
        businessId: businessId,
        orderNumber: orderNumber,
        orderType: state.orderType,
        tableNumber: state.tableNumber,
        status: 'NEW', // Initial status
        paymentStatus: 'UNPAID', // Modify later for instant payment workflow
        subtotal: state.subtotal,
        tax: state.tax,
        discount: state.discount,
        total: state.total,
        createdAt: now,
        updatedAt: now,
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

      await repo.createOrder(order, orderItems);
      
      clearCart();
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: e.toString());
      return false;
    }
  }
}

final cartProvider = NotifierProvider<CartNotifier, CartState>(() {
  return CartNotifier();
});
