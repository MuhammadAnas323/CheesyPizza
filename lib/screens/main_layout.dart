import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_colors.dart';
import '../providers/inventory_provider.dart';
import '../providers/repository_providers.dart';
import 'dashboard/dashboard_screen.dart';
import 'pos/pos_screen.dart';
import 'menu/menu_management_screen.dart';
import 'orders/orders_history_screen.dart';
import 'inventory/inventory_screen.dart';
import 'reports/sales_reports_screen.dart';

class MainLayout extends ConsumerStatefulWidget {
  const MainLayout({super.key});

  @override
  ConsumerState<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends ConsumerState<MainLayout> {
  int _currentIndex = 0;

  void _navigateToIndex(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final lowStockCount = ref.watch(lowStockCountProvider);
    final firebaseService = ref.watch(firebaseServiceProvider);
    final isDesktop = MediaQuery.of(context).size.width >= 850;

    final screens = [
      DashboardScreen(
        onNavigateToPos: () => _navigateToIndex(1),
        onNavigateToInventory: () => _navigateToIndex(4),
      ),
      const PosScreen(),
      const MenuManagementScreen(),
      const OrdersHistoryScreen(),
      const InventoryScreen(),
      const SalesReportsScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: AppColors.cheeseYellow,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.local_pizza, color: AppColors.darkRed, size: 20),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text(
                    'CHEESY PIZZA',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.6,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Fast Food Cafe Management',
                    style: TextStyle(
                      fontSize: 9.5,
                      color: Colors.white70,
                      letterSpacing: 0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Low stock alert indicator
          if (lowStockCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Tooltip(
                message: '$lowStockCount items low on stock',
                child: isDesktop
                    ? TextButton.icon(
                        style: TextButton.styleFrom(
                          backgroundColor: AppColors.warning,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20)),
                        ),
                        icon: const Icon(Icons.warning, size: 16),
                        label: Text(
                          '$lowStockCount Low Stock',
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        onPressed: () => _navigateToIndex(4),
                      )
                    : IconButton(
                        icon: Badge(
                          label: Text('$lowStockCount'),
                          backgroundColor: AppColors.cheeseYellow,
                          textColor: AppColors.textDark,
                          child: const Icon(Icons.warning_amber_rounded,
                              color: AppColors.cheeseYellow, size: 22),
                        ),
                        onPressed: () => _navigateToIndex(4),
                      ),
              ),
            ),

          // Firebase connection status badge / icon
          Padding(
            padding: EdgeInsets.only(right: isDesktop ? 12 : 6),
            child: Tooltip(
              message: firebaseService.isAvailable
                  ? 'Connected to Cloud Firestore'
                  : 'Local Storage Mode Active (Offline-ready)',
              child: isDesktop
                  ? Chip(
                      avatar: Icon(
                        firebaseService.isAvailable
                            ? Icons.cloud_done
                            : Icons.cloud_queue,
                        size: 15,
                        color: firebaseService.isAvailable
                            ? Colors.white
                            : Colors.white70,
                      ),
                      label: Text(
                        firebaseService.isAvailable
                            ? 'Firestore Live'
                            : 'Local / Offline',
                        style:
                            const TextStyle(fontSize: 11, color: Colors.white),
                      ),
                      backgroundColor: firebaseService.isAvailable
                          ? AppColors.success
                          : Colors.white.withAlpha(40),
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                      side: BorderSide.none,
                    )
                  : Icon(
                      firebaseService.isAvailable
                          ? Icons.cloud_done
                          : Icons.cloud_queue,
                      size: 20,
                      color: firebaseService.isAvailable
                          ? AppColors.cheeseYellow
                          : Colors.white60,
                    ),
            ),
          ),

          // POS shortcut button (Desktop only, mobile has bottom bar)
          if (isDesktop && _currentIndex != 1)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.cheeseYellow,
                  foregroundColor: AppColors.textDark,
                  elevation: 0,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                ),
                icon: const Icon(Icons.point_of_sale, size: 18),
                label: const Text(
                  'Take Order',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                onPressed: () => _navigateToIndex(1),
              ),
            ),
        ],
      ),
      body: isDesktop
          ? Row(
              children: [
                // Desktop Navigation Rail / Sidebar
                NavigationRail(
                  selectedIndex: _currentIndex,
                  onDestinationSelected: _navigateToIndex,
                  labelType: NavigationRailLabelType.all,
                  backgroundColor: Colors.white,
                  selectedIconTheme:
                      const IconThemeData(color: AppColors.primaryRed),
                  selectedLabelTextStyle: const TextStyle(
                    color: AppColors.primaryRed,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  unselectedIconTheme:
                      const IconThemeData(color: AppColors.mediumGrey),
                  unselectedLabelTextStyle: const TextStyle(
                    color: AppColors.mediumGrey,
                    fontSize: 11,
                  ),
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.dashboard_outlined),
                      selectedIcon: Icon(Icons.dashboard),
                      label: Text('Dashboard'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.point_of_sale_outlined),
                      selectedIcon: Icon(Icons.point_of_sale),
                      label: Text('POS Order'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.restaurant_menu_outlined),
                      selectedIcon: Icon(Icons.restaurant_menu),
                      label: Text('Menu'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.receipt_long_outlined),
                      selectedIcon: Icon(Icons.receipt_long),
                      label: Text('Orders'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.inventory_2_outlined),
                      selectedIcon: Icon(Icons.inventory_2),
                      label: Text('Inventory'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.bar_chart_outlined),
                      selectedIcon: Icon(Icons.bar_chart),
                      label: Text('Reports'),
                    ),
                  ],
                ),
                const VerticalDivider(width: 1, color: AppColors.borderGrey),
                Expanded(child: screens[_currentIndex]),
              ],
            )
          : screens[_currentIndex],
      bottomNavigationBar: !isDesktop
          ? BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: _navigateToIndex,
              type: BottomNavigationBarType.fixed,
              selectedItemColor: AppColors.primaryRed,
              unselectedItemColor: AppColors.mediumGrey,
              selectedLabelStyle:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
              unselectedLabelStyle: const TextStyle(fontSize: 10),
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.dashboard),
                  label: 'Dashboard',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.point_of_sale),
                  label: 'POS',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.restaurant_menu),
                  label: 'Menu',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.receipt_long),
                  label: 'Orders',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.inventory_2),
                  label: 'Inventory',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.bar_chart),
                  label: 'Reports',
                ),
              ],
            )
          : null,
    );
  }
}
