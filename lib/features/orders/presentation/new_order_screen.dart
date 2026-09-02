import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:khao_piyo_pos/core/utils/currency.dart';
import 'package:khao_piyo_pos/features/menu/providers/menu_provider.dart';
import 'package:khao_piyo_pos/features/orders/providers/cart_provider.dart';
import 'package:khao_piyo_pos/features/orders/widgets/attach_customer_dialog.dart';
import 'package:khao_piyo_pos/features/orders/widgets/checkout_sheet.dart';
import 'package:khao_piyo_pos/features/orders/widgets/discount_dialog.dart';
import 'package:khao_piyo_pos/features/orders/widgets/order_setup_view.dart';
import 'package:khao_piyo_pos/features/settings/providers/settings_provider.dart';
import 'package:khao_piyo_pos/shared/models/category.dart';

class NewOrderScreen extends ConsumerWidget {
  const NewOrderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setupComplete = ref.watch(orderSetupCompleteProvider);

    return Scaffold(
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
          child: setupComplete
              ? const _OrderWorkspace(key: ValueKey('workspace'))
              : OrderSetupView(
                  key: const ValueKey('setup'),
                  onComplete: (orderType, tableNumber) {
                    final cartNotifier = ref.read(cartProvider.notifier);
                    cartNotifier.setOrderType(orderType);
                    cartNotifier.setTableNumber(tableNumber);
                    ref.read(orderSetupCompleteProvider.notifier).state = true;
                  },
                ),
        ),
      ),
    );
  }
}

class _OrderWorkspace extends ConsumerWidget {
  const _OrderWorkspace({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isWide = MediaQuery.of(context).size.width > 750;
    final cartState = ref.watch(cartProvider);
    final settings = ref.watch(settingsProvider);
    final total = cartState.totalFor(settings.taxRatePercent);

    if (isWide) {
      return Row(
        children: [
          const Expanded(flex: 5, child: _MenuSection()),
          Container(
            width: 1,
            color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
          const Expanded(flex: 3, child: _CartSection()),
        ],
      );
    }

    // Mobile layout
    return Scaffold(
      body: const _MenuSection(),
      bottomNavigationBar: cartState.items.isEmpty ? null : SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: FilledButton(
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                useSafeArea: true,
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                builder: (context) => const _CartSection(),
              );
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'View Cart (${cartState.items.length} items)', 
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
                ),
                Text(
                  Currency.format(total, symbol: settings.currencySymbol),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// State provider to track the selected category ID for modern pill-based navigation
final selectedCategoryProvider = StateProvider<String?>((ref) => null);

class _MenuSection extends ConsumerWidget {
  const _MenuSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final menuStateAsync = ref.watch(menuProvider);
    final selectedCategoryId = ref.watch(selectedCategoryProvider);
    final currencySymbol = ref.watch(settingsProvider).currencySymbol;

    return menuStateAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
      data: (state) {
        if (state.categories.isEmpty) {
          return const Center(child: Text('No menu items available.'));
        }

        // Default to first category if none selected
        final activeCategory = selectedCategoryId ?? state.categories.first.id;

        final categoryItems = state.menuItems
            .where((item) => item.categoryId == activeCategory && item.isAvailable)
            .toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Text(
                'Menu',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            // Category Pills
            SizedBox(
              height: 56,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                scrollDirection: Axis.horizontal,
                itemCount: state.categories.length,
                separatorBuilder: (context, index) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final category = state.categories[index];
                  final isSelected = category.id == activeCategory;
                  
                  return _CategoryPill(
                    category: category,
                    isSelected: isSelected,
                    onTap: () => ref.read(selectedCategoryProvider.notifier).state = category.id,
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            // Item Grid
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 220,
                  childAspectRatio: 0.85,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: categoryItems.length,
                itemBuilder: (context, index) {
                  final item = categoryItems[index];
                  return _MenuItemCard(
                    name: item.name,
                    price: item.price,
                    currencySymbol: currencySymbol,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      ref.read(cartProvider.notifier).addItem(item);
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MenuItemCard extends StatefulWidget {
  final String name;
  final double price;
  final String currencySymbol;
  final VoidCallback onTap;

  const _MenuItemCard({required this.name, required this.price, required this.currencySymbol, required this.onTap});

  @override
  State<_MenuItemCard> createState() => _MenuItemCardState();
}

class _MenuItemCardState extends State<_MenuItemCard> {
  bool _pressed = false;

  void _setPressed(bool value) => setState(() => _pressed = value);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: Card(
          clipBehavior: Clip.antiAlias,
          color: scheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.3)),
          ),
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Icon(Icons.fastfood_rounded, size: 48, color: scheme.primary),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  Currency.format(widget.price, symbol: widget.currencySymbol),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(color: scheme.primary, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OrderContextBar extends ConsumerWidget {
  final CartState cartState;
  const _OrderContextBar({required this.cartState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final (icon, label) = switch (cartState.orderType) {
      'DINE_IN' => (Icons.table_restaurant_rounded, cartState.tableNumber != null ? 'Dine In · Table ${cartState.tableNumber}' : 'Dine In'),
      'TAKEAWAY' => (Icons.shopping_bag_outlined, 'Takeaway'),
      _ => (Icons.point_of_sale_rounded, 'Counter'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: scheme.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: scheme.primary))),
          TextButton(
            onPressed: () => ref.read(orderSetupCompleteProvider.notifier).state = false,
            style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8)),
            child: const Text('Change'),
          ),
        ],
      ),
    );
  }
}

class _CategoryPill extends StatelessWidget {
  final Category category;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryPill({
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected 
              ? Theme.of(context).colorScheme.primary 
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: isSelected 
                ? Colors.transparent 
                : Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            )
          ] : [],
        ),
        alignment: Alignment.center,
        child: Text(
          category.name,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: isSelected 
                ? Colors.white 
                : Theme.of(context).colorScheme.onSurface,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _CartSection extends ConsumerWidget {
  const _CartSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartState = ref.watch(cartProvider);
    final cartNotifier = ref.read(cartProvider.notifier);
    final settings = ref.watch(settingsProvider);
    final tax = cartState.taxFor(settings.taxRatePercent);
    final total = cartState.totalFor(settings.taxRatePercent);

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        children: [
          // Header & Order Type
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current Order',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _OrderContextBar(cartState: cartState),
                const SizedBox(height: 12),
                InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => showDialog(context: context, builder: (_) => const AttachCustomerDialog()),
                  child: Chip(
                    avatar: const Icon(Icons.person_outline, size: 18),
                    label: Text(cartState.customer?.name ?? cartState.customer?.phone ?? 'Attach customer'),
                    onDeleted: cartState.customer == null ? null : cartNotifier.detachCustomer,
                  ),
                ),
              ],
            ),
          ),
          
          // Cart Items List
          Expanded(
            child: cartState.items.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long_outlined, size: 64, color: Theme.of(context).colorScheme.outline),
                        const SizedBox(height: 16),
                        Text(
                          'No items in cart',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: cartState.items.length,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) {
                      final cartItem = cartState.items[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          children: [
                            // Quantity Controls
                            Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove, size: 18),
                                    tooltip: 'Decrease quantity',
                                    onPressed: () {
                                      HapticFeedback.selectionClick();
                                      cartNotifier.updateQuantity(cartItem.menuItem, cartItem.quantity - 1);
                                    },
                                  ),
                                  Text(
                                    '${cartItem.quantity}',
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add, size: 18),
                                    tooltip: 'Increase quantity',
                                    onPressed: () {
                                      HapticFeedback.selectionClick();
                                      cartNotifier.updateQuantity(cartItem.menuItem, cartItem.quantity + 1);
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Item Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    cartItem.menuItem.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    Currency.format(cartItem.menuItem.price, symbol: settings.currencySymbol),
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Total for item
                            Text(
                              Currency.format(cartItem.menuItem.price * cartItem.quantity, symbol: settings.currencySymbol),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),

          if (cartState.error != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        cartState.error!,
                        style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Totals and Checkout
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, -5),
                )
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Subtotal', style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                    Text(Currency.format(cartState.subtotal, symbol: settings.currencySymbol), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
                if (cartState.discountType != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        cartState.discountType == 'PERCENTAGE' ? 'Discount (${cartState.discountValue.toStringAsFixed(0)}%)' : 'Discount',
                        style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                      Text(
                        '-${Currency.format(cartState.discount, symbol: settings.currencySymbol)}',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.error),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Tax (${settings.taxRatePercent.toStringAsFixed(0)}%)', style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                    Text(Currency.format(tax, symbol: settings.currencySymbol), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  child: Divider(),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                    Text(
                      Currency.format(total, symbol: settings.currencySymbol),
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                Row(
                  children: [
                    // Discount Button
                    Expanded(
                      flex: 1,
                      child: OutlinedButton.icon(
                        onPressed: cartState.items.isEmpty
                            ? null
                            : () => showDialog(context: context, builder: (_) => const DiscountDialog()),
                        icon: const Icon(Icons.sell_outlined),
                        label: const Text('Discount'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Main Save/Charge Button
                    Expanded(
                      flex: 2,
                      child: FilledButton.icon(
                        onPressed: cartState.items.isEmpty || cartState.isSaving
                            ? null
                            : () {
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (context) => const CheckoutSheet(),
                                );
                              },
                        icon: cartState.isSaving 
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) 
                          : const Icon(Icons.check_circle_outline),
                        label: const Text('Charge', style: TextStyle(fontSize: 18)),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
