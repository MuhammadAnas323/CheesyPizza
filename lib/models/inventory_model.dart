class InventoryItem {
  final String id;
  final String name;
  final String category;
  final double currentStock;
  final double minStockAlert;
  final String unit;
  final double costPerUnit;
  final DateTime lastUpdated;

  const InventoryItem({
    required this.id,
    required this.name,
    required this.category,
    required this.currentStock,
    required this.minStockAlert,
    required this.unit,
    required this.costPerUnit,
    required this.lastUpdated,
  });

  bool get isLowStock => currentStock <= minStockAlert;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'currentStock': currentStock,
      'minStockAlert': minStockAlert,
      'unit': unit,
      'costPerUnit': costPerUnit,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  factory InventoryItem.fromMap(Map<String, dynamic> map, [String? docId]) {
    return InventoryItem(
      id: docId ?? map['id'] ?? '',
      name: map['name'] ?? '',
      category: map['category'] ?? 'General',
      currentStock: (map['currentStock'] as num?)?.toDouble() ?? 0.0,
      minStockAlert: (map['minStockAlert'] as num?)?.toDouble() ?? 5.0,
      unit: map['unit'] ?? 'kg',
      costPerUnit: (map['costPerUnit'] as num?)?.toDouble() ?? 0.0,
      lastUpdated: map['lastUpdated'] != null
          ? DateTime.tryParse(map['lastUpdated'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  InventoryItem copyWith({
    String? id,
    String? name,
    String? category,
    double? currentStock,
    double? minStockAlert,
    String? unit,
    double? costPerUnit,
    DateTime? lastUpdated,
  }) {
    return InventoryItem(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      currentStock: currentStock ?? this.currentStock,
      minStockAlert: minStockAlert ?? this.minStockAlert,
      unit: unit ?? this.unit,
      costPerUnit: costPerUnit ?? this.costPerUnit,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}
