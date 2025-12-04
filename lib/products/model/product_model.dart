class Product {
  String id;
  String name;
  double price; // original price
  double? offerPrice; // ✅ optional offer price
  String unit;
  int stock;
  String description;
  List<String> images;
  String categoryId;
  double? hyperMarket; // ✅ maybe used as hyper price reference
  String market;
  String itemCode;
  double? hyperMarketPrice; // ✅ actual Hyper Market offer price
  double? kgPrice;
  double? ctrPrice;
  double? pcsPrice;
  bool isHidden;

  Product({
    required this.itemCode,
    required this.market,
    required this.id,
    required this.name,
    required this.price,
    this.offerPrice,
    required this.unit,
    required this.stock,
    required this.description,
    required this.images,
    required this.categoryId,
    this.hyperMarket,
    this.hyperMarketPrice,
    this.kgPrice,
    this.ctrPrice,
    this.pcsPrice,
    this.isHidden = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'itemCode': itemCode,
      'market': market,
      'hyperPrice': hyperMarket, // keep key consistent
      'id': id,
      'name': name,
      'price': price,
      'offerPrice': offerPrice,
      'unit': unit,
      'stock': stock,
      'description': description,
      'images': images,
      'categoryId': categoryId,
      'hyperMarketPrice': hyperMarketPrice,
      'kgPrice': kgPrice,
      'ctrPrice': ctrPrice,
      'pcsPrice': pcsPrice,
      'isHidden': isHidden,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    double? parseDouble(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value);
      return null;
    }

    int parseInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      if (value is double) return value.toInt();
      return 0;
    }

    return Product(
      itemCode: map['itemCode'] ?? "",
      market: map['market'] ?? "",
      hyperMarket: parseDouble(map['hyperPrice']),
      hyperMarketPrice: parseDouble(map['hyperMarketPrice']),
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      price: parseDouble(map['price']) ?? 0.0,
      offerPrice: parseDouble(map['offerPrice']),
      unit: map['unit'] ?? '',
      stock: parseInt(map['stock']),
      description: map['description'] ?? '',
      images: List<String>.from(map['images'] ?? []),
      categoryId: map['categoryId'] ?? '',
      kgPrice: parseDouble(map['kgPrice']),
      ctrPrice: parseDouble(map['ctrPrice']),
      pcsPrice: parseDouble(map['pcsPrice']),
      isHidden: (map['isHidden'] != null && map['isHidden'] is bool)
          ? map['isHidden'] as bool
          : false,
    );
  }
  Product copyWith({
    String? id,
    String? name,
    String? itemCode,
    double? price,
    double? offerPrice,
    String? unit,
    int? stock,
    String? description,
    List<String>? images,
    String? categoryId,
    double? hyperMarket,
    double? hyperMarketPrice,
    String? market,
    double? kgPrice,
    double? ctrPrice,
    double? pcsPrice,
    bool? isHidden, // ✅ new field
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      itemCode: itemCode ?? this.itemCode,
      price: price ?? this.price,
      offerPrice: offerPrice ?? this.offerPrice,
      unit: unit ?? this.unit,
      stock: stock ?? this.stock,
      description: description ?? this.description,
      images: images ?? List<String>.from(this.images),
      categoryId: categoryId ?? this.categoryId,
      hyperMarket: hyperMarket ?? this.hyperMarket,
      hyperMarketPrice: hyperMarketPrice ?? this.hyperMarketPrice,
      market: market ?? this.market,
      kgPrice: kgPrice ?? this.kgPrice,
      ctrPrice: ctrPrice ?? this.ctrPrice,
      pcsPrice: pcsPrice ?? this.pcsPrice,
      isHidden: isHidden ?? this.isHidden, // ✅ updated copy
    );
  }
}
