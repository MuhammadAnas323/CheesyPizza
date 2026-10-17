import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/order_model.dart';
import '../core/utils/currency_formatter.dart';
import '../core/utils/date_formatter.dart';

class PrinterService {
  /// 80mm standard thermal roll width
  static const double thermalWidthMm = 80.0;
  static const double thermalMarginMm = 4.0;

  static PdfPageFormat get _thermalFormat => PdfPageFormat(
        thermalWidthMm * PdfPageFormat.mm,
        double.infinity,
        marginAll: thermalMarginMm * PdfPageFormat.mm,
      );

  /// Generates the Customer Bill Receipt PDF
  static Future<Uint8List> generateReceiptPdf(OrderModel order) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: _thermalFormat,
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 2),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              mainAxisSize: pw.MainAxisSize.min,
              children: [
                // Header
                pw.Text(
                  'CHEESY PIZZA',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  'Fast Food Cafe & Pizza Bar',
                  style: const pw.TextStyle(fontSize: 9),
                ),
                pw.Text(
                  'Order Tel: 0300-CHEESY (243379)',
                  style: const pw.TextStyle(fontSize: 8),
                ),
                pw.SizedBox(height: 6),
                _buildDottedDivider(),
                pw.SizedBox(height: 4),

                // Order Meta
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Order: ${order.orderNumber}',
                        style: pw.TextStyle(
                            fontSize: 10, fontWeight: pw.FontWeight.bold)),
                    pw.Text(order.orderType.label.toUpperCase(),
                        style: pw.TextStyle(
                            fontSize: 9, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
                pw.SizedBox(height: 2),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Date: ${DateFormatter.formatShort(order.createdAt)}',
                        style: const pw.TextStyle(fontSize: 8)),
                    pw.Text('Time: ${DateFormatter.formatTime(order.createdAt)}',
                        style: const pw.TextStyle(fontSize: 8)),
                  ],
                ),
                if (order.customerName != null && order.customerName!.isNotEmpty) ...[
                  pw.SizedBox(height: 2),
                  pw.Align(
                    alignment: pw.Alignment.centerLeft,
                    child: pw.Text('Customer: ${order.customerName}',
                        style: const pw.TextStyle(fontSize: 8)),
                  ),
                ],
                if (order.customerPhone != null && order.customerPhone!.isNotEmpty) ...[
                  pw.SizedBox(height: 1),
                  pw.Align(
                    alignment: pw.Alignment.centerLeft,
                    child: pw.Text('Phone: ${order.customerPhone}',
                        style: const pw.TextStyle(fontSize: 8)),
                  ),
                ],
                if (order.tableOrAddress != null && order.tableOrAddress!.isNotEmpty) ...[
                  pw.SizedBox(height: 1),
                  pw.Align(
                    alignment: pw.Alignment.centerLeft,
                    child: pw.Text('Address/Table: ${order.tableOrAddress}',
                        style: const pw.TextStyle(fontSize: 8)),
                  ),
                ],

                pw.SizedBox(height: 4),
                _buildDottedDivider(),
                pw.SizedBox(height: 4),

                // Items Table Header
                pw.Row(
                  children: [
                    pw.Expanded(
                      flex: 5,
                      child: pw.Text('Item Description',
                          style: pw.TextStyle(
                              fontSize: 8, fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.Expanded(
                      flex: 1,
                      child: pw.Text('Qty',
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(
                              fontSize: 8, fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.Expanded(
                      flex: 2,
                      child: pw.Text('Price',
                          textAlign: pw.TextAlign.right,
                          style: pw.TextStyle(
                              fontSize: 8, fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.Expanded(
                      flex: 2,
                      child: pw.Text('Total',
                          textAlign: pw.TextAlign.right,
                          style: pw.TextStyle(
                              fontSize: 8, fontWeight: pw.FontWeight.bold)),
                    ),
                  ],
                ),
                pw.SizedBox(height: 3),
                _buildSolidDivider(),
                pw.SizedBox(height: 3),

                // Item Lines
                ...order.items.map((item) {
                  return pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 2.5),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Row(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Expanded(
                              flex: 5,
                              child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Text(
                                    item.displayName,
                                    style: pw.TextStyle(
                                      fontSize: 9,
                                      fontWeight: pw.FontWeight.bold,
                                    ),
                                  ),
                                  if (item.selectedToppings.isNotEmpty)
                                    pw.Text(
                                      '+ ${item.selectedToppings.map((t) => t.name).join(', ')}',
                                      style: const pw.TextStyle(
                                          fontSize: 7, color: PdfColors.grey700),
                                    ),
                                  if (item.notes != null && item.notes!.isNotEmpty)
                                    pw.Text(
                                      'Note: ${item.notes}',
                                      style: const pw.TextStyle(
                                          fontSize: 7, color: PdfColors.grey800),
                                    ),
                                ],
                              ),
                            ),
                            pw.Expanded(
                              flex: 1,
                              child: pw.Text(
                                '${item.quantity}',
                                textAlign: pw.TextAlign.center,
                                style: pw.TextStyle(
                                    fontSize: 9, fontWeight: pw.FontWeight.bold),
                              ),
                            ),
                            pw.Expanded(
                              flex: 2,
                              child: pw.Text(
                                CurrencyFormatter.format(item.singleItemPrice)
                                    .replaceAll('Rs. ', ''),
                                textAlign: pw.TextAlign.right,
                                style: const pw.TextStyle(fontSize: 8),
                              ),
                            ),
                            pw.Expanded(
                              flex: 2,
                              child: pw.Text(
                                CurrencyFormatter.format(item.totalPrice)
                                    .replaceAll('Rs. ', ''),
                                textAlign: pw.TextAlign.right,
                                style: pw.TextStyle(
                                    fontSize: 8.5, fontWeight: pw.FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),

                pw.SizedBox(height: 4),
                _buildDottedDivider(),
                pw.SizedBox(height: 4),

                // Calculations
                _buildSummaryRow('Subtotal:', CurrencyFormatter.format(order.subtotal).replaceAll('Rs. ', '')),
                if (order.discountPercentage > 0)
                  _buildSummaryRow(
                      'Discount (${order.discountPercentage.toStringAsFixed(0)}%):', '- ${CurrencyFormatter.format(order.discount).replaceAll('Rs. ', '')}'),
                if (order.extraCharges > 0)
                  _buildSummaryRow(
                      '${order.extraChargesNote ?? "Extra Charges"}:', '+ ${CurrencyFormatter.format(order.extraCharges).replaceAll('Rs. ', '')}'),
                pw.SizedBox(height: 3),
                _buildSolidDivider(),
                pw.SizedBox(height: 4),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'TOTAL BILL:',
                      style: pw.TextStyle(
                          fontSize: 12, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text(
                      CurrencyFormatter.format(order.totalAmount),
                      style: pw.TextStyle(
                          fontSize: 12, fontWeight: pw.FontWeight.bold),
                    ),
                  ],
                ),
                pw.SizedBox(height: 3),
                _buildSolidDivider(),
                pw.SizedBox(height: 3),

                // Payment info
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Payment Method: ${order.paymentMethod}',
                        style: const pw.TextStyle(fontSize: 8)),
                    pw.Text('Items: ${order.totalItemsSold}',
                        style: const pw.TextStyle(fontSize: 8)),
                  ],
                ),

                pw.SizedBox(height: 6),
                _buildDottedDivider(),
                pw.SizedBox(height: 6),

                // Footer
                pw.Text(
                  'Thank you for choosing Cheesy Pizza!',
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(
                      fontSize: 8.5, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  '*** Have a Cheesy Day! ***',
                  style: const pw.TextStyle(fontSize: 7.5),
                ),
                pw.SizedBox(height: 4),
                pw.BarcodeWidget(
                  barcode: pw.Barcode.code128(),
                  data: order.orderNumber,
                  width: 100,
                  height: 24,
                  drawText: false,
                ),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  /// Generates the Kitchen Order Slip (KOT) PDF
  static Future<Uint8List> generateKitchenSlipPdf(OrderModel order) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: _thermalFormat,
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 2),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              mainAxisSize: pw.MainAxisSize.min,
              children: [
                // Header
                pw.Center(
                  child: pw.Text(
                    '*** KITCHEN SLIP (KOT) ***',
                    style: pw.TextStyle(
                      fontSize: 13,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.SizedBox(height: 4),
                _buildSolidDivider(),
                pw.SizedBox(height: 4),

                // Big Order info
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      order.orderNumber,
                      style: pw.TextStyle(
                          fontSize: 14, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.black, width: 1.2),
                      ),
                      child: pw.Text(
                        order.orderType.label.toUpperCase(),
                        style: pw.TextStyle(
                            fontSize: 10, fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  'Time: ${DateFormatter.formatTime(order.createdAt)}  (${DateFormatter.formatShort(order.createdAt)})',
                  style: const pw.TextStyle(fontSize: 9),
                ),
                if (order.customerName != null && order.customerName!.isNotEmpty) ...[
                  pw.SizedBox(height: 2),
                  pw.Text('Customer: ${order.customerName}${order.customerPhone != null && order.customerPhone!.isNotEmpty ? ' (${order.customerPhone})' : ''}',
                      style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
                ],
                if (order.tableOrAddress != null && order.tableOrAddress!.isNotEmpty) ...[
                  pw.SizedBox(height: 2),
                  pw.Text('Address/Table: ${order.tableOrAddress}',
                      style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
                ],
                if (order.extraCharges > 0 || (order.extraChargesNote != null && order.extraChargesNote!.trim().isNotEmpty)) ...[
                  pw.SizedBox(height: 4),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.black, width: 0.8),
                    ),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Expanded(
                          child: pw.Text(
                            order.extraChargesNote != null && order.extraChargesNote!.trim().isNotEmpty
                                ? 'EXTRA / NOTE: ${order.extraChargesNote!.trim()}'
                                : 'EXTRA CHARGES APPLIED',
                            style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                        if (order.extraCharges > 0)
                          pw.Text(
                            CurrencyFormatter.format(order.extraCharges),
                            style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
                          ),
                      ],
                    ),
                  ),
                ],

                pw.SizedBox(height: 6),
                _buildSolidDivider(),
                pw.SizedBox(height: 4),

                // Kitchen Items
                pw.Text(
                  'ITEMS TO PREPARE:',
                  style: pw.TextStyle(
                      fontSize: 9, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 4),

                ...order.items.map((item) {
                  return pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 6),
                    child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Container(
                          width: 28,
                          height: 24,
                          alignment: pw.Alignment.center,
                          decoration: pw.BoxDecoration(
                            border: pw.Border.all(width: 1),
                          ),
                          child: pw.Text(
                            '${item.quantity}x',
                            style: pw.TextStyle(
                              fontSize: 11,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ),
                        pw.SizedBox(width: 8),
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                item.productName,
                                style: pw.TextStyle(
                                  fontSize: 11,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                              if (item.selectedSize != null &&
                                  item.selectedSize!.isNotEmpty)
                                pw.Text(
                                  'Size: ${item.selectedSize}',
                                  style: pw.TextStyle(
                                    fontSize: 9,
                                    fontWeight: pw.FontWeight.bold,
                                  ),
                                ),
                              if (item.selectedToppings.isNotEmpty)
                                pw.Text(
                                  'Toppings: ${item.selectedToppings.map((t) => t.name).join(', ')}',
                                  style: const pw.TextStyle(
                                    fontSize: 8.5,
                                  ),
                                ),
                              if (item.notes != null && item.notes!.isNotEmpty)
                                pw.Container(
                                  margin: const pw.EdgeInsets.only(top: 2),
                                  padding: const pw.EdgeInsets.symmetric(
                                      horizontal: 4, vertical: 1),
                                  decoration: const pw.BoxDecoration(
                                    color: PdfColors.grey200,
                                    borderRadius: pw.BorderRadius.all(
                                        pw.Radius.circular(2)),
                                  ),
                                  child: pw.Text(
                                    'PREP NOTE: ${item.notes}',
                                    style: pw.TextStyle(
                                      fontSize: 8.5,
                                      fontWeight: pw.FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),

                pw.SizedBox(height: 6),
                _buildSolidDivider(),
                pw.SizedBox(height: 4),

                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Total Items: ${order.totalItemsSold}',
                        style: pw.TextStyle(
                            fontSize: 10, fontWeight: pw.FontWeight.bold)),
                    pw.Text('[ CHEESY PIZZA KITCHEN ]',
                        style: const pw.TextStyle(fontSize: 8)),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildDottedDivider() {
    return pw.Container(
      height: 1,
      child: pw.Row(
        children: List.generate(
          35,
          (index) => pw.Expanded(
            child: pw.Container(
              color: index % 2 == 0 ? PdfColors.grey700 : PdfColors.white,
              height: 0.6,
            ),
          ),
        ),
      ),
    );
  }

  static pw.Widget _buildSolidDivider() {
    return pw.Divider(thickness: 0.8, color: PdfColors.black);
  }

  static pw.Widget _buildSummaryRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 8.5)),
          pw.Text(value, style: const pw.TextStyle(fontSize: 8.5)),
        ],
      ),
    );
  }

  /// Print or preview customer receipt
  static Future<void> printReceipt(OrderModel order) async {
    await Printing.layoutPdf(
      onLayout: (format) => generateReceiptPdf(order),
      name: 'Receipt_${order.orderNumber}',
    );
  }

  /// Print or preview kitchen slip
  static Future<void> printKitchenSlip(OrderModel order) async {
    await Printing.layoutPdf(
      onLayout: (format) => generateKitchenSlipPdf(order),
      name: 'KitchenSlip_${order.orderNumber}',
    );
  }

  /// Interactive Print Dialog
  static void showPrintModal(BuildContext context, OrderModel order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Print Bill / Slip (${order.orderNumber})',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const Divider(),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFC62828),
                    child: Icon(Icons.receipt_long, color: Colors.white),
                  ),
                  title: const Text('Customer Slip',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Prints customer bill receipt'),
                  trailing: ElevatedButton.icon(
                    icon: const Icon(Icons.print, size: 16),
                    label: const Text('Print'),
                    onPressed: () {
                      Navigator.pop(ctx);
                      printReceipt(order);
                    },
                  ),
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFFFA000),
                    child: Icon(Icons.restaurant, color: Colors.white),
                  ),
                  title: const Text('Kitchen Slip',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Prints kitchen preparation ticket'),
                  trailing: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF212529),
                    ),
                    icon: const Icon(Icons.print, size: 16),
                    label: const Text('Print KOT'),
                    onPressed: () {
                      Navigator.pop(ctx);
                      printKitchenSlip(order);
                    },
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }
}
