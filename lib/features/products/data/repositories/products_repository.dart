import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:products_catelogs/core/constants/cloudinary_constants.dart';
import 'package:products_catelogs/core/constants/firestore_collections.dart';
import 'package:products_catelogs/features/products/presentation/widgets/add_edit_product_form_view.dart';

abstract class ProductsRepository {
  Future<void> createProduct(ProductFormResult product);
  Future<void> upsertProduct(ProductFormResult product);
  Future<void> updateProduct({
    required ProductFormResult product,
    required String initialNormalizedCode,
  });
  Future<void> deleteProduct(String normalizedCode);
  Future<void> setProductHidden({
    required String normalizedCode,
    required bool hidden,
  });
  Stream<List<ProductRecord>> watchProducts();
  Stream<List<ProductCategoryRecord>> watchCategories();
  Future<void> createCategory(String name);
  Future<void> renameCategory({
    required String categoryId,
    required String newName,
  });
  Future<void> deleteCategory(String categoryId);
}

class FirestoreProductsRepository implements ProductsRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  FirestoreProductsRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance;

  @override
  Future<void> createProduct(ProductFormResult product) async {
    final normalizedCode = _normalizeCode(product.code);
    if (normalizedCode.isEmpty) {
      throw StateError('Product code is required.');
    }
    final imageUrls = await _resolveImageUrls(product);

    final docRef = _firestore
        .collection(FirestoreCollections.products)
        .doc(normalizedCode);

    await _firestore.runTransaction((transaction) async {
      final existing = await transaction.get(docRef);
      if (existing.exists) {
        throw StateError('Product code already exists in database.');
      }

      transaction.set(
        docRef,
        _buildProductData(
          product: product,
          normalizedCode: normalizedCode,
          imageUrls: imageUrls,
          status: 'active',
          preserveCreatedAudit: const {},
        ),
      );
    });
  }

  @override
  Future<void> upsertProduct(ProductFormResult product) async {
    final normalizedCode = _normalizeCode(product.code);
    if (normalizedCode.isEmpty) {
      throw StateError('Product code is required.');
    }
    final imageUrls = await _resolveImageUrls(product);

    final docRef = _firestore
        .collection(FirestoreCollections.products)
        .doc(normalizedCode);

    await _firestore.runTransaction((transaction) async {
      final existing = await transaction.get(docRef);
      final oldData = existing.data() ?? <String, dynamic>{};
      final oldAudit = _asMap(oldData['audit']);
      final preserveCreatedAudit = <String, dynamic>{
        'createdAt': oldAudit['createdAt'],
        'createdByUid': oldAudit['createdByUid'],
        'createdByEmail': oldAudit['createdByEmail'],
      };

      final payload = _buildProductData(
        product: product,
        normalizedCode: normalizedCode,
        imageUrls: imageUrls,
        status: (oldData['status'] as String?)?.trim().isNotEmpty == true
            ? (oldData['status'] as String).trim()
            : 'active',
        preserveCreatedAudit: preserveCreatedAudit,
      );

      transaction.set(docRef, payload);
    });
  }

  @override
  Future<void> updateProduct({
    required ProductFormResult product,
    required String initialNormalizedCode,
  }) async {
    final newNormalizedCode = _normalizeCode(product.code);
    final oldNormalizedCode = initialNormalizedCode.trim().toLowerCase();
    if (newNormalizedCode.isEmpty) {
      throw StateError('Product code is required.');
    }
    final imageUrls = await _resolveImageUrls(product);

    final productsRef = _firestore.collection(FirestoreCollections.products);
    final oldDocRef = productsRef.doc(oldNormalizedCode);
    final newDocRef = productsRef.doc(newNormalizedCode);

    await _firestore.runTransaction((transaction) async {
      final oldSnap = await transaction.get(oldDocRef);
      if (!oldSnap.exists) {
        throw StateError('Original product does not exist.');
      }

      if (oldNormalizedCode != newNormalizedCode) {
        final newSnap = await transaction.get(newDocRef);
        if (newSnap.exists) {
          throw StateError('Target product code already exists.');
        }
      }

      final oldData = oldSnap.data() ?? <String, dynamic>{};
      final oldAudit = _asMap(oldData['audit']);
      final preserveCreatedAudit = <String, dynamic>{
        'createdAt': oldAudit['createdAt'],
        'createdByUid': oldAudit['createdByUid'],
        'createdByEmail': oldAudit['createdByEmail'],
      };

      final payload = _buildProductData(
        product: product,
        normalizedCode: newNormalizedCode,
        imageUrls: imageUrls,
        status: (oldData['status'] as String?)?.trim().isNotEmpty == true
            ? (oldData['status'] as String).trim()
            : 'active',
        preserveCreatedAudit: preserveCreatedAudit,
      );

      transaction.set(newDocRef, payload);
      if (oldNormalizedCode != newNormalizedCode) {
        transaction.delete(oldDocRef);
      }
    });
  }

  @override
  Future<void> deleteProduct(String normalizedCode) async {
    final code = normalizedCode.trim().toLowerCase();
    if (code.isEmpty) throw StateError('Invalid product code.');
    await _firestore
        .collection(FirestoreCollections.products)
        .doc(code)
        .delete();
  }

  @override
  Future<void> setProductHidden({
    required String normalizedCode,
    required bool hidden,
  }) async {
    final code = normalizedCode.trim().toLowerCase();
    if (code.isEmpty) throw StateError('Invalid product code.');
    final user = _auth.currentUser;
    await _firestore.collection(FirestoreCollections.products).doc(code).set({
      'status': hidden ? 'hidden' : 'active',
      'audit': {
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedByUid': user?.uid,
        'updatedByEmail': user?.email,
      },
    }, SetOptions(merge: true));
  }

  @override
  Stream<List<ProductRecord>> watchProducts() {
    return _firestore.collection(FirestoreCollections.products).snapshots().map(
      (snapshot) {
        final items = snapshot.docs
            .map((doc) => ProductRecord.fromDoc(doc))
            .toList();
        items.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
        return items;
      },
    );
  }

  @override
  Stream<List<ProductCategoryRecord>> watchCategories() {
    return _firestore
        .collection(FirestoreCollections.productCategories)
        .orderBy('nameLower')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => ProductCategoryRecord.fromDoc(doc))
              .toList();
        });
  }

  @override
  Future<void> createCategory(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) throw StateError('Category name is required.');
    final key = _normalizeKey(trimmed);
    if (key.isEmpty) throw StateError('Invalid category name.');

    final docRef = _firestore
        .collection(FirestoreCollections.productCategories)
        .doc(key);
    final exists = await docRef.get();
    if (exists.exists) {
      throw StateError('Category already exists.');
    }

    final user = _auth.currentUser;
    final now = FieldValue.serverTimestamp();
    await docRef.set({
      'name': trimmed,
      'nameLower': trimmed.toLowerCase(),
      'key': key,
      'status': 'active',
      'audit': {
        'source': 'web_admin',
        'createdAt': now,
        'updatedAt': now,
        'createdByUid': user?.uid,
        'createdByEmail': user?.email,
        'updatedByUid': user?.uid,
        'updatedByEmail': user?.email,
      },
    });
  }

  @override
  Future<void> renameCategory({
    required String categoryId,
    required String newName,
  }) async {
    final trimmed = newName.trim();
    if (trimmed.isEmpty) throw StateError('Category name is required.');
    final oldId = categoryId.trim();
    final newId = _normalizeKey(trimmed);
    if (oldId.isEmpty || newId.isEmpty) throw StateError('Invalid category.');

    final collection = _firestore.collection(
      FirestoreCollections.productCategories,
    );
    final oldDoc = collection.doc(oldId);
    final newDoc = collection.doc(newId);

    await _firestore.runTransaction((transaction) async {
      final oldSnap = await transaction.get(oldDoc);
      if (!oldSnap.exists) throw StateError('Category does not exist.');

      final oldData = oldSnap.data() ?? <String, dynamic>{};
      final oldAudit = _asMap(oldData['audit']);
      final user = _auth.currentUser;
      final now = FieldValue.serverTimestamp();

      final payload = {
        'name': trimmed,
        'nameLower': trimmed.toLowerCase(),
        'key': newId,
        'status': oldData['status'] ?? 'active',
        'audit': {
          'source': oldAudit['source'] ?? 'web_admin',
          'createdAt': oldAudit['createdAt'] ?? now,
          'updatedAt': now,
          'createdByUid': oldAudit['createdByUid'],
          'createdByEmail': oldAudit['createdByEmail'],
          'updatedByUid': user?.uid,
          'updatedByEmail': user?.email,
        },
      };

      if (oldId == newId) {
        transaction.set(oldDoc, payload);
      } else {
        final newSnap = await transaction.get(newDoc);
        if (newSnap.exists) throw StateError('Category name already exists.');
        transaction.set(newDoc, payload);
        transaction.delete(oldDoc);
      }
    });
  }

  @override
  Future<void> deleteCategory(String categoryId) async {
    final id = categoryId.trim();
    if (id.isEmpty) throw StateError('Invalid category id.');
    await _firestore
        .collection(FirestoreCollections.productCategories)
        .doc(id)
        .delete();
  }

  String _normalizeCode(String input) {
    return input.replaceAll('#', '').trim().toLowerCase();
  }

  String _normalizeKey(String input) {
    return input
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }

  String _marketKey(String marketName) {
    if (marketName.toLowerCase().contains('hyper')) return 'hyper_market';
    if (marketName.toLowerCase().contains('local')) return 'local_market';
    return _normalizeKey(marketName);
  }

  Map<String, dynamic> _buildProductData({
    required ProductFormResult product,
    required String normalizedCode,
    required List<String> imageUrls,
    required String status,
    required Map<String, dynamic> preserveCreatedAudit,
  }) {
    final now = FieldValue.serverTimestamp();
    final user = _auth.currentUser;
    final markets = <String, dynamic>{};
    product.marketPricingByMarket.forEach((marketName, prices) {
      final marketKey = _marketKey(marketName);
      markets[marketKey] = {
        'displayName': marketName,
        'prices': {
          for (final row in prices)
            _normalizeKey(row.unit): {
              'unit': row.unit,
              'overrideEnabled': row.overrideEnabled,
              'manualPriceQar': row.manualPrice,
              'manualOfferPriceQar': row.manualOfferPrice,
              'autoPriceQar': row.autoPrice,
              'autoOfferPriceQar': row.autoOfferPrice,
            },
        },
      };
    });

    return {
      'schemaVersion': 1,
      'productCode': product.code,
      'productCodeNormalized': normalizedCode,
      'productName': product.name,
      'productNameLower': product.name.toLowerCase().trim(),
      'productDescription': product.description,
      'category': {
        'name': product.category,
        'key': _normalizeKey(product.category),
      },
      'baseUnit': {
        'name': product.baseUnit,
        'key': _normalizeKey(product.baseUnit),
      },
      'saleUnits': [
        for (final unit in product.saleUnits)
          {
            'name': unit.unit,
            'key': _normalizeKey(unit.unit),
            'conversionToBaseUnit': unit.conversionToBaseUnit,
          },
      ],
      'pricing': {
        'currency': 'QAR',
        'markets': markets,
        'defaultMarketKey': 'hyper_market',
      },
      'inventory': {
        'initialInputQty': product.initialStockInput,
        'initialInputUnit': product.initialStockInputUnit ?? product.baseUnit,
        'baseUnitQty': product.initialStockInBaseUnit,
        'availableQtyBaseUnit': product.initialStockInBaseUnit,
      },
      'status': status,
      'linkedMarketing': 'Manual Entry',
      'metrics': {
        'salesCount': 0,
        'displayPriceQar': product.displayPriceQar,
        'displayOfferPriceQar': product.displayOfferPriceQar,
      },
      'search': {
        'tags': [
          product.name.toLowerCase().trim(),
          product.code.toLowerCase().trim(),
          product.category.toLowerCase().trim(),
          product.baseUnit.toLowerCase().trim(),
        ],
      },
      'images': {
        'urls': imageUrls,
        'primaryUrl': imageUrls.isEmpty ? null : imageUrls.first,
      },
      'audit': {
        'source': 'web_admin',
        'createdAt': preserveCreatedAudit['createdAt'] ?? now,
        'updatedAt': now,
        'createdByUid': preserveCreatedAudit['createdByUid'] ?? user?.uid,
        'createdByEmail': preserveCreatedAudit['createdByEmail'] ?? user?.email,
        'updatedByUid': user?.uid,
        'updatedByEmail': user?.email,
      },
    };
  }

  Future<List<String>> _resolveImageUrls(ProductFormResult product) async {
    final uploadedUrls = <String>[];
    for (final image in product.newImages) {
      final uploaded = await _uploadImageBytesToCloudinary(
        bytes: image.bytes,
        fileName: image.name,
      );
      if (uploaded != null && uploaded.isNotEmpty) {
        uploadedUrls.add(uploaded);
      }
    }

    final seen = <String>{};
    final merged = <String>[];
    for (final url in [...product.existingImageUrls, ...uploadedUrls]) {
      final trimmed = url.trim();
      if (trimmed.isEmpty) continue;
      if (seen.add(trimmed)) {
        merged.add(trimmed);
      }
    }
    return merged;
  }

  Future<String?> _uploadImageBytesToCloudinary({
    required Uint8List bytes,
    required String fileName,
  }) async {
    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/${CloudinaryConstants.cloudName}/image/upload',
    );
    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = CloudinaryConstants.uploadPreset
      ..files.add(
        http.MultipartFile.fromBytes('file', bytes, filename: fileName),
      );

    final response = await request.send();
    final body = await response.stream.bytesToString();
    if (response.statusCode != 200) {
      throw StateError(
        'Cloudinary upload failed (${response.statusCode}): $body',
      );
    }
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) {
      throw StateError('Invalid Cloudinary response payload.');
    }
    return decoded['secure_url'] as String?;
  }

  static Map<String, dynamic> _asMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, v) => MapEntry(key.toString(), v));
    }
    return <String, dynamic>{};
  }
}

class ProductRecord {
  final String code;
  final String name;
  final String category;
  final String description;
  final String baseUnit;
  final List<String> saleUnits;
  final List<SaleUnitConfig> saleUnitConfigs;
  final Map<String, List<MarketUnitPrice>> marketPricingByMarket;
  final double initialStockInput;
  final String? initialStockInputUnit;
  final double stockInBaseUnit;
  final double displayPriceQar;
  final double? displayOfferPriceQar;
  final int salesCount;
  final String linkedMarketing;
  final bool isHidden;
  final List<String> imageUrls;
  final String? primaryImageUrl;

  const ProductRecord({
    required this.code,
    required this.name,
    required this.category,
    required this.description,
    required this.baseUnit,
    required this.saleUnits,
    required this.saleUnitConfigs,
    required this.marketPricingByMarket,
    required this.initialStockInput,
    required this.initialStockInputUnit,
    required this.stockInBaseUnit,
    required this.displayPriceQar,
    required this.displayOfferPriceQar,
    required this.salesCount,
    required this.linkedMarketing,
    required this.isHidden,
    required this.imageUrls,
    required this.primaryImageUrl,
  });

  factory ProductRecord.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    final categoryMap = _asMap(data['category']);
    final baseUnitMap = _asMap(data['baseUnit']);
    final metricsMap = _asMap(data['metrics']);
    final inventoryMap = _asMap(data['inventory']);
    final pricingMap = _asMap(data['pricing']);
    final marketsMap = _asMap(pricingMap['markets']);
    final saleUnitsRaw = data['saleUnits'];

    final saleUnits = <String>[];
    final saleUnitConfigs = <SaleUnitConfig>[];
    if (saleUnitsRaw is List) {
      for (final item in saleUnitsRaw) {
        final itemMap = _asMap(item);
        final unitName = (itemMap['name'] as String?)?.trim();
        if (unitName != null && unitName.isNotEmpty) {
          saleUnits.add(unitName);
          saleUnitConfigs.add(
            SaleUnitConfig(
              unit: unitName,
              conversionToBaseUnit:
                  _toDouble(itemMap['conversionToBaseUnit']) ?? 1,
            ),
          );
        }
      }
    }

    final marketPricingByMarket = <String, List<MarketUnitPrice>>{};
    marketsMap.forEach((marketKey, marketValue) {
      final marketObj = _asMap(marketValue);
      final displayName = (marketObj['displayName'] as String?)?.trim();
      final pricesMap = _asMap(marketObj['prices']);
      final rows = <MarketUnitPrice>[];
      pricesMap.forEach((_, value) {
        final rowMap = _asMap(value);
        final unit = (rowMap['unit'] as String?)?.trim();
        if (unit == null || unit.isEmpty) return;
        rows.add(
          MarketUnitPrice(
            unit: unit,
            overrideEnabled: rowMap['overrideEnabled'] == true,
            manualPrice: _toDouble(rowMap['manualPriceQar']),
            manualOfferPrice: _toDouble(rowMap['manualOfferPriceQar']),
            autoPrice: _toDouble(rowMap['autoPriceQar']),
            autoOfferPrice: _toDouble(rowMap['autoOfferPriceQar']),
          ),
        );
      });
      marketPricingByMarket[displayName ?? marketKey] = rows;
    });

    final linkedMarketing = (data['linkedMarketing'] as String?)?.trim();
    final status =
        (data['status'] as String?)?.trim().toLowerCase() ?? 'active';
    final imagesMap = _asMap(data['images']);
    final urlsRaw = imagesMap['urls'];
    final imageUrls = <String>[];
    if (urlsRaw is List) {
      for (final item in urlsRaw) {
        if (item is String && item.trim().isNotEmpty) {
          imageUrls.add(item.trim());
        }
      }
    }
    final rawPrimary = (imagesMap['primaryUrl'] as String?)?.trim();
    final primaryImageUrl = (rawPrimary != null && rawPrimary.isNotEmpty)
        ? rawPrimary
        : (imageUrls.isEmpty ? null : imageUrls.first);

    return ProductRecord(
      code: (data['productCode'] as String?)?.trim().isNotEmpty == true
          ? (data['productCode'] as String).trim()
          : '#${doc.id}',
      name: (data['productName'] as String?)?.trim() ?? 'Unnamed Product',
      category: (categoryMap['name'] as String?)?.trim() ?? 'Uncategorized',
      description: (data['productDescription'] as String?)?.trim() ?? '',
      baseUnit: (baseUnitMap['name'] as String?)?.trim() ?? 'Piece',
      saleUnits: saleUnits.isEmpty ? const ['Piece'] : saleUnits,
      saleUnitConfigs: saleUnitConfigs.isEmpty
          ? const [SaleUnitConfig(unit: 'Piece', conversionToBaseUnit: 1)]
          : saleUnitConfigs,
      marketPricingByMarket: marketPricingByMarket,
      initialStockInput: _toDouble(inventoryMap['initialInputQty']) ?? 0,
      initialStockInputUnit: (inventoryMap['initialInputUnit'] as String?)
          ?.trim(),
      stockInBaseUnit:
          _toDouble(inventoryMap['availableQtyBaseUnit']) ??
          _toDouble(inventoryMap['baseUnitQty']) ??
          0,
      displayPriceQar: _toDouble(metricsMap['displayPriceQar']) ?? 0,
      displayOfferPriceQar: _toDouble(metricsMap['displayOfferPriceQar']),
      salesCount: _toInt(metricsMap['salesCount']) ?? 0,
      linkedMarketing: linkedMarketing == null || linkedMarketing.isEmpty
          ? 'N/A'
          : linkedMarketing,
      isHidden: status == 'hidden',
      imageUrls: imageUrls,
      primaryImageUrl: primaryImageUrl,
    );
  }

  static Map<String, dynamic> _asMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, v) => MapEntry(key.toString(), v));
    }
    return <String, dynamic>{};
  }

  static double? _toDouble(Object? value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.trim());
    return null;
  }

  static int? _toInt(Object? value) {
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim());
    return null;
  }
}

class ProductCategoryRecord {
  final String id;
  final String name;

  const ProductCategoryRecord({required this.id, required this.name});

  factory ProductCategoryRecord.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    final name = (data['name'] as String?)?.trim();
    return ProductCategoryRecord(
      id: doc.id,
      name: (name == null || name.isEmpty) ? doc.id : name,
    );
  }
}
