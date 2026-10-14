class ProductSize {
  final String name; // e.g. Small, Medium, Large, Jumbo
  final double price; // Selling price in PKR
  final double costPrice; // Cost price in PKR for profit estimation

  const ProductSize({
    required this.name,
    required this.price,
    required this.costPrice,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
      'costPrice': costPrice,
    };
  }

  factory ProductSize.fromMap(Map<String, dynamic> map) {
    return ProductSize(
      name: map['name'] ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      costPrice: (map['costPrice'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class ProductTopping {
  final String name; // e.g. Extra Cheese, Mushrooms, Jalapenos, Pepperoni
  final double price; // Added selling price
  final double costPrice; // Added ingredient cost

  const ProductTopping({
    required this.name,
    required this.price,
    required this.costPrice,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
      'costPrice': costPrice,
    };
  }

  factory ProductTopping.fromMap(Map<String, dynamic> map) {
    return ProductTopping(
      name: map['name'] ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      costPrice: (map['costPrice'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class RecipeIngredient {
  final String inventoryItemId; // Matches InventoryItem.id
  final String ingredientName;
  final double quantityRequired; // Quantity consumed per item
  final String unit; // kg, g, pcs, etc.

  const RecipeIngredient({
    required this.inventoryItemId,
    required this.ingredientName,
    required this.quantityRequired,
    required this.unit,
  });

  Map<String, dynamic> toMap() {
    return {
      'inventoryItemId': inventoryItemId,
      'ingredientName': ingredientName,
      'quantityRequired': quantityRequired,
      'unit': unit,
    };
  }

  factory RecipeIngredient.fromMap(Map<String, dynamic> map) {
    return RecipeIngredient(
      inventoryItemId: map['inventoryItemId'] ?? '',
      ingredientName: map['ingredientName'] ?? '',
      quantityRequired: (map['quantityRequired'] as num?)?.toDouble() ?? 0.0,
      unit: map['unit'] ?? 'kg',
    );
  }
}

class ProductModel {
  final String id;
  final String name;
  final String categoryId;
  final String description;
  final String imageUrl;
  final double basePrice;
  final double baseCostPrice;
  final bool isAvailable;
  final bool hasSizes;
  final List<ProductSize> sizes;
  final List<ProductTopping> availableToppings;
  final List<RecipeIngredient> recipe;

  const ProductModel({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.description,
    this.imageUrl = '',
    required this.basePrice,
    required this.baseCostPrice,
    this.isAvailable = true,
    this.hasSizes = false,
    this.sizes = const [],
    this.availableToppings = const [],
    this.recipe = const [],
  });

  double get displayStartingPrice {
    if (hasSizes && sizes.isNotEmpty) {
      return sizes.map((s) => s.price).reduce((a, b) => a < b ? a : b);
    }
    return basePrice;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'categoryId': categoryId,
      'description': description,
      'imageUrl': imageUrl,
      'basePrice': basePrice,
      'baseCostPrice': baseCostPrice,
      'isAvailable': isAvailable,
      'hasSizes': hasSizes,
      'sizes': sizes.map((s) => s.toMap()).toList(),
      'availableToppings': availableToppings.map((t) => t.toMap()).toList(),
      'recipe': recipe.map((r) => r.toMap()).toList(),
    };
  }

  factory ProductModel.fromMap(Map<String, dynamic> map, [String? docId]) {
    return ProductModel(
      id: docId ?? map['id'] ?? '',
      name: map['name'] ?? '',
      categoryId: map['categoryId'] ?? '',
      description: map['description'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      basePrice: (map['basePrice'] as num?)?.toDouble() ?? 0.0,
      baseCostPrice: (map['baseCostPrice'] as num?)?.toDouble() ?? 0.0,
      isAvailable: map['isAvailable'] ?? true,
      hasSizes: map['hasSizes'] ?? false,
      sizes: (map['sizes'] as List<dynamic>?)
              ?.map((item) => ProductSize.fromMap(Map<String, dynamic>.from(item)))
              .toList() ??
          [],
      availableToppings: (map['availableToppings'] as List<dynamic>?)
              ?.map((item) => ProductTopping.fromMap(Map<String, dynamic>.from(item)))
              .toList() ??
          [],
      recipe: (map['recipe'] as List<dynamic>?)
              ?.map((item) => RecipeIngredient.fromMap(Map<String, dynamic>.from(item)))
              .toList() ??
          [],
    );
  }

  ProductModel copyWith({
    String? id,
    String? name,
    String? categoryId,
    String? description,
    String? imageUrl,
    double? basePrice,
    double? baseCostPrice,
    bool? isAvailable,
    bool? hasSizes,
    List<ProductSize>? sizes,
    List<ProductTopping>? availableToppings,
    List<RecipeIngredient>? recipe,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      categoryId: categoryId ?? this.categoryId,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      basePrice: basePrice ?? this.basePrice,
      baseCostPrice: baseCostPrice ?? this.baseCostPrice,
      isAvailable: isAvailable ?? this.isAvailable,
      hasSizes: hasSizes ?? this.hasSizes,
      sizes: sizes ?? this.sizes,
      availableToppings: availableToppings ?? this.availableToppings,
      recipe: recipe ?? this.recipe,
    );
  }
}
