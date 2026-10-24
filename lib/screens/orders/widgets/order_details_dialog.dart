import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/order_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../providers/order_provider.dart';
import '../../../services/printer_service.dart';

class OrderDetailsDialog extends ConsumerStatefulWidget {
  final OrderModel order;

  const OrderDetailsDialog({
    super.key,
    required this.order,
  });

  static Future<void> show(BuildContext context, OrderModel order) {
    return showDialog(
      context: context,
      builder: (ctx) => OrderDetailsDialog(order: order),
    );
  }

  @override
  ConsumerState<OrderDetailsDialog> createState() => _OrderDetailsDialogState();
}

class _OrderDetailsDialogState extends ConsumerState<OrderDetailsDialog> {
  int _tapCount = 0;
  DateTime? _firstTapTime;
  bool _showCancelOption = false;
  bool _isCancelling = false;

  OrderModel get _latestOrder {
    final ordersList = ref.read(orderNotifierProvider).asData?.value ?? [];
    return ordersList.firstWhere(
      (o) => o.id == widget.order.id,
      orElse: () => widget.order,
    );
  }

  void _handleTap() {
    final statusLower = _latestOrder.status.toLowerCase();
    // Only enabled for completed orders. Do not show or enable for other statuses.
    if (statusLower != 'completed') return;
    if (_showCancelOption) return;

    final now = DateTime.now();
    if (_firstTapTime == null || now.difference(_firstTapTime!) > const Duration(seconds: 3)) {
      _firstTapTime = now;
      _tapCount = 1;
    } else {
      _tapCount++;
      if (_tapCount >= 7) {
        setState(() {
          _showCancelOption = true;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Admin unlocked: Cancel Order option is now available.'),
              backgroundColor: Colors.black87,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    }
  }

  Future<void> _confirmCancelOrder(OrderModel currentOrder) async {
    if (_isCancelling) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (confirmCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
        contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.warning_amber_rounded, color: AppColors.danger, size: 22),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Cancel Completed Order?',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50.withAlpha(120),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 18, color: AppColors.danger),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Order ${currentOrder.orderNumber} • ${CurrencyFormatter.format(currentOrder.totalAmount)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.danger),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Are you sure you want to cancel this order?',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(height: 6),
            const Text(
              'This will mark the order as Cancelled and deduct the sales amount from today\'s dashboard statistics and sales reports.',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted, height: 1.4),
            ),
          ],
        ),
        actions: [
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textDark,
              side: BorderSide(color: Colors.grey.shade300),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            onPressed: () => Navigator.pop(confirmCtx, false),
            child: const Text('No, Keep Order'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            icon: const Icon(Icons.cancel, size: 16),
            onPressed: () => Navigator.pop(confirmCtx, true),
            label: const Text('Yes, Cancel Order'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isCancelling = true);
      try {
        await ref.read(orderNotifierProvider.notifier).updateStatus(currentOrder.id, 'Cancelled');
        if (!mounted) return;
        Navigator.pop(context); // Close order details dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order ${currentOrder.orderNumber} has been Cancelled.'),
            backgroundColor: AppColors.danger,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        setState(() => _isCancelling = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error cancelling order: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch order list so details update in real-time when edited
    final ordersList = ref.watch(orderNotifierProvider).asData?.value ?? [];
    final order = ordersList.firstWhere(
      (o) => o.id == widget.order.id,
      orElse: () => widget.order,
    );

    final statusLower = order.status.toLowerCase();
    final isCompleted = statusLower == 'completed';
    final isCancelled = statusLower == 'cancelled';
    final isOnTable = statusLower == 'on table';
    final isPending = !isCompleted && !isCancelled;

    final hasCustomerInfo = (order.customerName != null && order.customerName!.trim().isNotEmpty) ||
        (order.guestName != null && order.guestName!.trim().isNotEmpty) ||
        (order.tableOrAddress != null && order.tableOrAddress!.trim().isNotEmpty);

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _handleTap(),
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: EdgeInsets.symmetric(
          horizontal: MediaQuery.of(context).size.width < 600 ? 12 : 24,
          vertical: 20,
        ),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 560,
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                color: AppColors.primaryRed,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(40),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.receipt_long, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Order ${order.orderNumber}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            DateFormatter.formatDateTime(order.createdAt),
                            style: TextStyle(
                              color: Colors.white.withAlpha(200),
                              fontSize: 11.5,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white, size: 20),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),

              // Scrollable Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status, Type, and Payment Chips
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          // Status Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isCompleted
                                  ? AppColors.successLight
                                  : (isCancelled
                                      ? AppColors.danger.withAlpha(30)
                                      : (isOnTable
                                          ? Colors.blue.shade50
                                          : AppColors.warningLight)),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isCompleted
                                    ? AppColors.success.withAlpha(75)
                                    : (isCancelled
                                        ? AppColors.danger.withAlpha(75)
                                        : (isOnTable
                                            ? Colors.blue.withAlpha(75)
                                            : AppColors.warning.withAlpha(75))),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isCompleted
                                      ? Icons.check_circle
                                      : (isCancelled
                                          ? Icons.cancel
                                          : (isOnTable
                                              ? Icons.table_restaurant
                                              : Icons.schedule)),
                                  size: 14,
                                  color: isCompleted
                                      ? AppColors.success
                                      : (isCancelled
                                          ? AppColors.danger
                                          : (isOnTable ? Colors.blue : AppColors.warning)),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  order.status.toUpperCase(),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11.5,
                                    color: isCompleted
                                        ? AppColors.success
                                        : (isCancelled
                                            ? AppColors.danger
                                            : (isOnTable ? Colors.blue : AppColors.warning)),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Order Type Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.lightRed.withAlpha(35),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.primaryRed.withAlpha(40)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  order.orderType == OrderType.takeaway
                                      ? Icons.takeout_dining
                                      : (order.orderType == OrderType.delivery
                                          ? Icons.delivery_dining
                                          : Icons.restaurant),
                                  size: 14,
                                  color: AppColors.primaryRed,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  order.orderType.label,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11.5,
                                    color: AppColors.primaryRed,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Payment Method Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.lightGrey,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              order.paymentMethod,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.mediumGrey,
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Hidden Cancel Order Banner (Unlocked by 7 taps within 3 seconds on completed orders)
                      if (isCompleted && _showCancelOption) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.red.shade300, width: 1.2),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.admin_panel_settings, color: AppColors.danger, size: 20),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'Admin Unlocked: Cancel Order option revealed.',
                                  style: TextStyle(
                                    color: AppColors.danger,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11.5,
                                  ),
                                ),
                              ),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.danger,
                                  foregroundColor: Colors.white,
                                  visualDensity: VisualDensity.compact,
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                ),
                                icon: _isCancelling
                                    ? const SizedBox(
                                        width: 12,
                                        height: 12,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                      )
                                    : const Icon(Icons.cancel, size: 14),
                                label: const Text('Cancel Order', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                onPressed: _isCancelling ? null : () => _confirmCancelOrder(order),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Customer Info & Guest Info Box
                      if (hasCustomerInfo) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.lightGrey.withAlpha(50),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.borderGrey.withAlpha(100)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (order.customerName != null && order.customerName!.trim().isNotEmpty)
                                Row(
                                  children: [
                                    const Icon(Icons.person, size: 15, color: AppColors.textDark),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        'Customer: ${order.customerName!.trim()}',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                                      ),
                                    ),
                                    if (order.customerPhone != null && order.customerPhone!.trim().isNotEmpty) ...[
                                      const Icon(Icons.phone, size: 14, color: AppColors.textMuted),
                                      const SizedBox(width: 4),
                                      Text(
                                        order.customerPhone!,
                                        style: const TextStyle(fontSize: 12, color: AppColors.textDark),
                                      ),
                                    ],
                                  ],
                                ),
                              if (order.guestName != null && order.guestName!.trim().isNotEmpty) ...[
                                if (order.customerName != null && order.customerName!.trim().isNotEmpty)
                                  const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Icon(Icons.card_giftcard, size: 15, color: Colors.purple.shade700),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        'Guest / Free Order: ${order.guestName!.trim()}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12.5,
                                          color: Colors.purple.shade900,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              if (order.tableOrAddress != null && order.tableOrAddress!.trim().isNotEmpty) ...[
                                if ((order.customerName != null && order.customerName!.trim().isNotEmpty) ||
                                    (order.guestName != null && order.guestName!.trim().isNotEmpty))
                                  const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.location_on, size: 15, color: AppColors.textMuted),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        order.tableOrAddress!,
                                        style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 14),

                      // Items Ordered List
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Items Ordered',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13.5,
                              color: AppColors.textDark,
                            ),
                          ),
                          Text(
                            '${order.totalItemsSold} items',
                            style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.borderGrey.withAlpha(120)),
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: order.items.length,
                          separatorBuilder: (_, _) => const Divider(height: 8),
                          itemBuilder: (context, idx) {
                            final item = order.items[idx];
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.lightRed.withAlpha(35),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '${item.quantity}x',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                        color: AppColors.primaryRed,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.displayName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12.5,
                                            color: AppColors.textDark,
                                          ),
                                        ),
                                        if (item.notes != null && item.notes!.isNotEmpty)
                                          Text(
                                            'Note: ${item.notes}',
                                            style: const TextStyle(fontSize: 11, color: AppColors.primaryRed),
                                          ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    CurrencyFormatter.format(item.totalPrice),
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Bill Summary Card
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.lightGrey.withAlpha(60),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.borderGrey.withAlpha(120)),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Subtotal:', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                                Text(CurrencyFormatter.format(order.subtotal),
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                              ],
                            ),
                            if (order.discount > 0) ...[
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      order.discountPersonName != null && order.discountPersonName!.trim().isNotEmpty
                                          ? 'Discount (${order.discountPercentage > 0 ? "${order.discountPercentage.toStringAsFixed(0)}% - " : ""}${order.discountPersonName!.trim()}):'
                                          : (order.discountPercentage > 0
                                              ? 'Discount (${order.discountPercentage.toStringAsFixed(0)}%):'
                                              : 'Discount:'),
                                      style: const TextStyle(fontSize: 12, color: AppColors.danger),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text('- ${CurrencyFormatter.format(order.discount)}',
                                      style: const TextStyle(
                                          fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.danger)),
                                ],
                              ),
                            ],
                            if (order.extraCharges > 0) ...[
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      order.extraChargesNote != null && order.extraChargesNote!.trim().isNotEmpty
                                          ? 'Extra Charges (${order.extraChargesNote!.trim()}):'
                                          : 'Extra Charges:',
                                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text('+ ${CurrencyFormatter.format(order.extraCharges)}',
                                      style: const TextStyle(
                                          fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryRed)),
                                ],
                              ),
                            ],
                            const Divider(height: 14),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Total Bill:',
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textDark),
                                ),
                                Text(
                                  CurrencyFormatter.format(order.totalAmount),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryRed,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Pending/OnTable Order Quick Action Banner
                      if (isPending) ...[
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isOnTable
                                ? Colors.blue.shade50
                                : AppColors.warningLight.withAlpha(90),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: isOnTable
                                    ? Colors.blue.withAlpha(90)
                                    : AppColors.warning.withAlpha(90)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    isOnTable ? Icons.table_restaurant : Icons.touch_app,
                                    size: 16,
                                    color: isOnTable ? Colors.blue : AppColors.warning,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    isOnTable ? 'On Table – Actions' : 'Order Status Actions',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: AppColors.textDark),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              if (!isOnTable) ...[
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.blue,
                                      side: const BorderSide(color: Colors.blue),
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                    ),
                                    icon: const Icon(Icons.table_restaurant, size: 16),
                                    label: const Text('Move to On Table',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                                    onPressed: () async {
                                      Navigator.pop(context);
                                      await ref
                                          .read(orderNotifierProvider.notifier)
                                          .updateStatus(order.id, 'On Table');
                                    },
                                  ),
                                ),
                                const SizedBox(height: 8),
                              ],
                              Row(
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.success,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 10),
                                      ),
                                      icon: const Icon(Icons.check_circle, size: 16),
                                      label: const Text('Complete Order',
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                                      onPressed: () => _showCompleteOrderPaymentDialog(context, ref, order),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    flex: 2,
                                    child: OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppColors.danger,
                                        side: const BorderSide(color: AppColors.danger),
                                        padding: const EdgeInsets.symmetric(vertical: 10),
                                      ),
                                      icon: const Icon(Icons.cancel_outlined, size: 16),
                                      label: const Text('Cancel',
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                      onPressed: () async {
                                        Navigator.pop(context);
                                        await ref
                                            .read(orderNotifierProvider.notifier)
                                            .updateStatus(order.id, 'Cancelled');
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Actions Bottom Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  border: Border(top: BorderSide(color: AppColors.borderGrey.withAlpha(100))),
                ),
                child: Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    // Hidden Cancel Order button (shown in bottom bar when revealed for completed orders)
                    if (isCompleted && _showCancelOption)
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.danger,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          visualDensity: VisualDensity.compact,
                        ),
                        icon: _isCancelling
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.cancel, size: 15),
                        label: const Text('Cancel Order', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        onPressed: _isCancelling ? null : () => _confirmCancelOrder(order),
                      ),

                    // Kitchen KOT Button: ONLY visible for Pending orders, NEVER on completed orders
                    if (!isCompleted && !isCancelled)
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          visualDensity: VisualDensity.compact,
                        ),
                        icon: const Icon(Icons.restaurant, size: 15),
                        label: const Text('Kitchen KOT', style: TextStyle(fontSize: 12)),
                        onPressed: () => PrinterService.printKitchenSlip(order),
                      ),

                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryRed,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        visualDensity: VisualDensity.compact,
                      ),
                      icon: const Icon(Icons.print, size: 15),
                      label: Text(
                        isCompleted ? 'Print Receipt / Slip' : 'Customer Slip',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      onPressed: () => PrinterService.printReceipt(order),
                    ),

                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCompleteOrderPaymentDialog(BuildContext context, WidgetRef ref, OrderModel order) {
    String selectedPaymentMethod = (order.paymentMethod.toLowerCase() == 'account') ? 'Account' : 'Cash';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.successLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.check_circle, color: AppColors.success, size: 20),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Complete Order',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Complete order ${order.orderNumber} for ${CurrencyFormatter.format(order.totalAmount)}.',
                  style: const TextStyle(fontSize: 13, color: AppColors.textDark),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Select Payment Method:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark),
                ),
                const SizedBox(height: 10),

                // Cash Option
                InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => setDialogState(() => selectedPaymentMethod = 'Cash'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: selectedPaymentMethod == 'Cash'
                          ? Colors.green.shade50
                          : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selectedPaymentMethod == 'Cash'
                            ? Colors.green
                            : AppColors.borderGrey,
                        width: selectedPaymentMethod == 'Cash' ? 1.8 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.payments_outlined,
                          color: selectedPaymentMethod == 'Cash' ? Colors.green : AppColors.textMuted,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Cash',
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
                          ),
                        ),
                        Icon(
                          selectedPaymentMethod == 'Cash'
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                          color: selectedPaymentMethod == 'Cash' ? Colors.green : AppColors.textMuted,
                          size: 22,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Account Option
                InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => setDialogState(() => selectedPaymentMethod = 'Account'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: selectedPaymentMethod == 'Account'
                          ? Colors.blue.shade50
                          : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selectedPaymentMethod == 'Account'
                            ? Colors.blue
                            : AppColors.borderGrey,
                        width: selectedPaymentMethod == 'Account' ? 1.8 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.account_balance_outlined,
                          color: selectedPaymentMethod == 'Account' ? Colors.blue : AppColors.textMuted,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Account (Digital / Bank Transfer)',
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
                          ),
                        ),
                        Icon(
                          selectedPaymentMethod == 'Account'
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                          color: selectedPaymentMethod == 'Account' ? Colors.blue : AppColors.textMuted,
                          size: 22,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text('Back'),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.check, size: 16),
                label: const Text('Confirm & Complete'),
                onPressed: () async {
                  Navigator.pop(dialogCtx); // Close payment dialog
                  Navigator.pop(context); // Close details dialog
                  await ref.read(orderNotifierProvider.notifier).updateStatus(
                        order.id,
                        'Completed',
                        paymentMethod: selectedPaymentMethod,
                      );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            'Order ${order.orderNumber} completed with payment method: $selectedPaymentMethod'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
