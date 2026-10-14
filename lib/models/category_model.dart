class CategoryModel {
  final String id;
  final String name;
  final String iconName;
  final int displayOrder;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.iconName,
    this.displayOrder = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'iconName': iconName,
      'displayOrder': displayOrder,
    };
  }

  factory CategoryModel.fromMap(Map<String, dynamic> map, [String? docId]) {
    return CategoryModel(
      id: docId ?? map['id'] ?? '',
      name: map['name'] ?? '',
      iconName: map['iconName'] ?? 'local_pizza',
      displayOrder: map['displayOrder'] ?? 0,
    );
  }

  CategoryModel copyWith({
    String? id,
    String? name,
    String? iconName,
    int? displayOrder,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      iconName: iconName ?? this.iconName,
      displayOrder: displayOrder ?? this.displayOrder,
    );
  }
}
