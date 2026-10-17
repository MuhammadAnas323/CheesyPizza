import 'package:uuid/uuid.dart';

enum OrderType {
  dineIn('Dine-in'),
  takeaway('Parcel/Takeaway'),
  delivery('Home Delivery');

  final String label;
  const OrderType(this.label);

  static OrderType fromString(String value) {
    for (final type in OrderType.values) {
      if (type.label.toLowerCase() == value.toLowerCase() ||
          type.name.toLowerCase() == value.toLowerCase()) {
        return type;
      }
    }
    return OrderType.dineIn;
  }
}

class OrderItemTopping {
  final String name;
  final double price;
  final double costPrice;

  const OrderItemTopping({
    required this.name,
    required this.price,
    this.costPrice = 0.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
      'costPrice': costPrice,
    };
  }

  factory OrderItemTopping.fromMap(Map<String, dynamic> map) {
    return OrderItemTopping(
      name: map['name'] ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      costPrice: (map['costPrice'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class OrderItem {
  final String id;
  final String productId;
  final String productName;
  final String categoryId;
  final String categoryName;
  final String? selectedSize;
  final List<OrderItemTopping> selectedToppings;
  final double unitPrice;
  final double unitCostPrice;
  final int quantity;
  final String? notes;

  OrderItem({
    String? id,
    required this.productId,
    required this.productName,
    required this.categoryId,
    required this.categoryName,
    this.selectedSize,
    this.selectedToppings = const [],
    required this.unitPrice,
    required this.unitCostPrice,
    this.quantity = 1,
    this.notes,
  }) : id = id ?? const Uuid().v4();

  double get toppingsPrice =>
      selectedToppings.fold(0.0, (sum, t) => sum + t.price);

  double get toppingsCost =>
      selectedToppings.fold(0.0, (sum, t) => sum + t.costPrice);

  double get singleItemPrice => unitPrice + toppingsPrice;

  double get singleItemCost => unitCostPrice + toppingsCost;

  double get totalPrice => singleItemPrice * quantity;

  double get totalCost => singleItemCost * quantity;

  double get profit => totalPrice - totalCost;

  String get displayName {
    final buffer = StringBuffer(productName);
    if (selectedSize != null && selectedSize!.isNotEmpty) {
      buffer.write(' ($selectedSize)');
    }
    return buffer.toString();
  }

  OrderItem copyWith({
    String? id,
    String? productId,
    String? productName,
    String? categoryId,
    String? categoryName,
    String? selectedSize,
    List<OrderItemTopping>? selectedToppings,
    double? unitPrice,
    double? unitCostPrice,
    int? quantity,
    String? notes,
  }) {
    return OrderItem(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      selectedSize: selectedSize ?? this.selectedSize,
      selectedToppings: selectedToppings ?? this.selectedToppings,
      unitPrice: unitPrice ?? this.unitPrice,
      unitCostPrice: unitCostPrice ?? this.unitCostPrice,
      quantity: quantity ?? this.quantity,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId,
      'productName': productName,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'selectedSize': selectedSize,
      'selectedToppings': selectedToppings.map((t) => t.toMap()).toList(),
      'unitPrice': unitPrice,
      'unitCostPrice': unitCostPrice,
      'quantity': quantity,
      'notes': notes,
    };
  }

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      id: map['id'],
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      categoryId: map['categoryId'] ?? '',
      categoryName: map['categoryName'] ?? '',
      selectedSize: map['selectedSize'],
      selectedToppings: (map['selectedToppings'] as List<dynamic>?)
              ?.map((t) => OrderItemTopping.fromMap(Map<String, dynamic>.from(t)))
              .toList() ??
          [],
      unitPrice: (map['unitPrice'] as num?)?.toDouble() ?? 0.0,
      unitCostPrice: (map['unitCostPrice'] as num?)?.toDouble() ?? 0.0,
      quantity: (map['quantity'] as num?)?.toInt() ?? 1,
      notes: map['notes'],
    );
  }
}

class OrderModel {
  final String id;
  final String orderNumber;
  final DateTime createdAt;
  final OrderType orderType;
  final List<OrderItem> items;
  final double subtotal;
  final double discountPercentage; // e.g. 10.0 for 10%
  final double discount;
  final double extraCharges;
  final String? extraChargesNote;
  final double totalAmount;
  final double totalCost;
  final double estimatedProfit;
  final String? customerName;
  final String? customerPhone;
  final String? tableOrAddress;
  final String? discountPersonName; // Name of person receiving the discount
  final String status; // Pending, Completed, Cancelled
  final String paymentMethod; // Cash, Account

  const OrderModel({
    required this.id,
    required this.orderNumber,
    required this.createdAt,
    required this.orderType,
    required this.items,
    required this.subtotal,
    this.discountPercentage = 0.0,
    required this.discount,
    this.extraCharges = 0.0,
    this.extraChargesNote,
    required this.totalAmount,
    required this.totalCost,
    required this.estimatedProfit,
    this.customerName,
    this.customerPhone,
    this.tableOrAddress,
    this.discountPersonName,
    this.status = 'Pending',
    this.paymentMethod = 'Cash',
  });

  int get totalItemsSold => items.fold(0, (sum, item) => sum + item.quantity);

  OrderModel copyWith({
    String? id,
    String? orderNumber,
    DateTime? createdAt,
    OrderType? orderType,
    List<OrderItem>? items,
    double? subtotal,
    double? discountPercentage,
    double? discount,
    double? extraCharges,
    String? extraChargesNote,
    double? totalAmount,
    double? totalCost,
    double? estimatedProfit,
    String? customerName,
    String? customerPhone,
    String? tableOrAddress,
    String? discountPersonName,
    String? status,
    String? paymentMethod,
  }) {
    return OrderModel(
      id: id ?? this.id,
      orderNumber: orderNumber ?? this.orderNumber,
      createdAt: createdAt ?? this.createdAt,
      orderType: orderType ?? this.orderType,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      discount: discount ?? this.discount,
      extraCharges: extraCharges ?? this.extraCharges,
      extraChargesNote: extraChargesNote ?? this.extraChargesNote,
      totalAmount: totalAmount ?? this.totalAmount,
      totalCost: totalCost ?? this.totalCost,
      estimatedProfit: estimatedProfit ?? this.estimatedProfit,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      tableOrAddress: tableOrAddress ?? this.tableOrAddress,
      discountPersonName: discountPersonName ?? this.discountPersonName,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'orderNumber': orderNumber,
      'createdAt': createdAt.toIso8601String(),
      'orderType': orderType.label,
      'items': items.map((i) => i.toMap()).toList(),
      'subtotal': subtotal,
      'discountPercentage': discountPercentage,
      'discount': discount,
      'extraCharges': extraCharges,
      'extraChargesNote': extraChargesNote,
      'totalAmount': totalAmount,
      'totalCost': totalCost,
      'estimatedProfit': estimatedProfit,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'tableOrAddress': tableOrAddress,
      'discountPersonName': discountPersonName,
      'status': status,
      'paymentMethod': paymentMethod,
    };
  }

  factory OrderModel.fromMap(Map<String, dynamic> map, [String? docId]) {
    final itemsList = (map['items'] as List<dynamic>?)
            ?.map((i) => OrderItem.fromMap(Map<String, dynamic>.from(i)))
            .toList() ??
        [];

    final double subtotal = (map['subtotal'] as num?)?.toDouble() ?? 0.0;
    final double discountPercentage = (map['discountPercentage'] as num?)?.toDouble() ?? 0.0;
    final double discount = (map['discount'] as num?)?.toDouble() ?? (subtotal * (discountPercentage / 100));
    final double extraCharges = (map['extraCharges'] as num?)?.toDouble() ?? 0.0;
    final double totalAmount = (map['totalAmount'] as num?)?.toDouble() ?? (subtotal - discount + extraCharges);
    final double calculatedCost =
        itemsList.fold<double>(0.0, (sum, item) => sum + item.totalCost);
    final double totalCost =
        (map['totalCost'] as num?)?.toDouble() ?? calculatedCost;
    final double estimatedProfit =
        (map['estimatedProfit'] as num?)?.toDouble() ?? (totalAmount - totalCost);

    return OrderModel(
      id: docId ?? map['id'] ?? '',
      orderNumber: map['orderNumber'] ?? '',
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      orderType: OrderType.fromString(map['orderType'] ?? 'Dine-in'),
      items: itemsList,
      subtotal: subtotal,
      discountPercentage: discountPercentage,
      discount: discount,
      extraCharges: extraCharges,
      extraChargesNote: map['extraChargesNote'],
      totalAmount: totalAmount,
      totalCost: totalCost,
      estimatedProfit: estimatedProfit,
      customerName: map['customerName'],
      customerPhone: map['customerPhone'],
      tableOrAddress: map['tableOrAddress'],
      discountPersonName: map['discountPersonName'],
      status: map['status'] ?? 'Pending',
      paymentMethod: map['paymentMethod'] ?? 'Cash',
    );
  }
}
