import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/order_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../providers/order_provider.dart';
import '../../../services/printer_service.dart';

class OrderDetailsDialog extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final statusLower = order.status.toLowerCase();
    final isCompleted = statusLower == 'completed';
    final isCancelled = statusLower == 'cancelled';
    final isPending = !isCompleted && !isCancelled;

    final hasCustomerInfo = (order.customerName != null && order.customerName!.trim().isNotEmpty) ||
        (order.tableOrAddress != null && order.tableOrAddress!.trim().isNotEmpty);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540, maxHeight: 720),
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
                                    : AppColors.warningLight),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isCompleted
                                  ? AppColors.success.withAlpha(75)
                                  : (isCancelled
                                      ? AppColors.danger.withAlpha(75)
                                      : AppColors.warning.withAlpha(75)),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isCompleted
                                    ? Icons.check_circle
                                    : (isCancelled ? Icons.cancel : Icons.schedule),
                                size: 14,
                                color: isCompleted
                                    ? AppColors.success
                                    : (isCancelled ? AppColors.danger : AppColors.warning),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                order.status.toUpperCase(),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11.5,
                                  color: isCompleted
                                      ? AppColors.success
                                      : (isCancelled ? AppColors.danger : AppColors.warning),
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

                    // Customer Info Box
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
                                  const Icon(Icons.person, size: 15, color: AppColors.textMuted),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      order.customerName!,
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
                            if (order.tableOrAddress != null && order.tableOrAddress!.trim().isNotEmpty) ...[
                              if (order.customerName != null && order.customerName!.trim().isNotEmpty)
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

                    // Pending Order Quick Action Banner
                    if (isPending) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.warningLight.withAlpha(90),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.warning.withAlpha(90)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: const [
                                Icon(Icons.touch_app, size: 16, color: AppColors.warning),
                                SizedBox(width: 6),
                                Text(
                                  'Order Status Actions',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
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
