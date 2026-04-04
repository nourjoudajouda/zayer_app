import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/providers/auth_providers.dart';
import '../../features/cart/providers/cart_providers.dart';
import '../../features/home/providers/home_providers.dart';

/// Cart tab index in [MainShell] (must match [NavigationBar] destinations order).
const int _kCartShellIndex = 2;

class MainShell extends ConsumerStatefulWidget {
  const MainShell({
    super.key,
    required this.navigationShell,
  });

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  /// Tracks last visible branch so we only refetch when the user *enters* the Cart tab.
  int _previousShellIndex = -1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authRepositoryProvider).updateFcmToken();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cartCount = ref.watch(cartBadgeCountProvider);
    final shellIndex = widget.navigationShell.currentIndex;

    // Refresh cart from server whenever the user *enters* the Cart branch (tab or `go` to /cart).
    // [CartNotifier] no longer loads in its constructor, so this is the single fetch when opening Cart.
    if (shellIndex == _kCartShellIndex && _previousShellIndex != _kCartShellIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref.read(cartItemsProvider.notifier).loadItems();
      });
    }
    _previousShellIndex = shellIndex;

    return Scaffold(
      body: widget.navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: widget.navigationShell.currentIndex,
        onDestinationSelected: (index) {
          // Cart "Proceed to checkout" can leave proceeding=true if push/go doesn't
          // complete the awaited future; opening Cart again must clear the spinner.
          if (index == _kCartShellIndex) {
            ref.read(proceedingToCheckoutProvider.notifier).state = false;
          }
          widget.navigationShell.goBranch(index);
        },
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          const NavigationDestination(
            icon: Icon(Icons.public_outlined),
            selectedIcon: Icon(Icons.public),
            label: 'Markets',
          ),
          NavigationDestination(
            icon: Badge(
              label: Text('$cartCount'),
              isLabelVisible: cartCount > 0,
              child: const Icon(Icons.shopping_cart_outlined),
            ),
            selectedIcon: Badge(
              label: Text('$cartCount'),
              isLabelVisible: cartCount > 0,
              child: const Icon(Icons.shopping_cart),
            ),
            label: 'Cart',
          ),
          const NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Orders',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Account',
          ),
        ],
      ),
    );
  }
}
