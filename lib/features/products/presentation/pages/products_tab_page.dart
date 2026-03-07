import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:products_catelogs/core/constants/firestore_collections.dart';
import 'package:products_catelogs/features/auth/application/auth_providers.dart';
import 'package:products_catelogs/features/products/data/repositories/products_repository.dart';
import 'package:products_catelogs/features/products/presentation/widgets/add_edit_product_form_view.dart';
import 'package:products_catelogs/features/products/presentation/widgets/bulk_upload_products_view.dart';
import 'package:products_catelogs/features/products/presentation/widgets/categories_management_view.dart';
import 'package:products_catelogs/features/products/presentation/widgets/product_details_view.dart';

enum _StockStatus { inStock, lowStock, soldOut }

enum _StockFilter { all, inStock, lowStock, soldOut }

enum _VisibilityFilter { all, visibleOnly, hiddenOnly }

enum _PerformanceLevel { excellent, veryGood, good }

enum _ProductAction { view, edit, toggleVisibility, delete }

class _Product {
  final String normalizedCode;
  final String id;
  final String name;
  final String category;
  final _PerformanceLevel performance;
  final int conversionPercent;
  final String linkedMarketing;
  final double priceQar;
  final int sales;
  final _StockStatus stockStatus;
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String description;
  final String baseUnit;
  final List<String> saleUnits;
  final List<SaleUnitConfig> saleUnitConfigs;
  final Map<String, List<MarketUnitPrice>> marketPricingByMarket;
  final double initialStockInput;
  final String? initialStockInputUnit;
  final double stockInBaseUnit;
  final double? offerPriceQar;
  final bool isHidden;
  final List<String> imageUrls;
  final String? primaryImageUrl;

  const _Product({
    required this.normalizedCode,
    required this.id,
    required this.name,
    required this.category,
    required this.performance,
    required this.conversionPercent,
    required this.linkedMarketing,
    required this.priceQar,
    required this.sales,
    required this.stockStatus,
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    this.description = '',
    this.baseUnit = 'Piece',
    this.saleUnits = const ['Piece'],
    this.saleUnitConfigs = const [
      SaleUnitConfig(unit: 'Piece', conversionToBaseUnit: 1),
    ],
    this.marketPricingByMarket = const {},
    this.initialStockInput = 0,
    this.initialStockInputUnit,
    this.stockInBaseUnit = 0,
    this.offerPriceQar,
    this.isHidden = false,
    this.imageUrls = const [],
    this.primaryImageUrl,
  });
}

class ProductsTabPage extends ConsumerStatefulWidget {
  const ProductsTabPage({super.key});

  @override
  ConsumerState<ProductsTabPage> createState() => _ProductsTabPageState();
}

class _ProductsTabPageState extends ConsumerState<ProductsTabPage> {
  static const int _rowsPerPage = 13;
  final ProductsRepository _productsRepository = FirestoreProductsRepository();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _tableHorizontalScrollController = ScrollController();
  NumberFormat get _currency => ref
      .read(userPreferencesProvider)
      .currencyFormatter(decimalDigits: 0);
  String get _currencyCode => ref.read(userPreferencesProvider).currency;

  String _query = '';
  _StockFilter _stockFilter = _StockFilter.all;
  _VisibilityFilter _visibilityFilter = _VisibilityFilter.all;
  String? _categoryFilterKey;
  int _currentPage = 1;
  bool _showCategoriesScreen = false;
  bool _showAddProductForm = false;
  _Product? _editingProduct;
  bool _isLoadingProducts = true;
  final List<ProductCategoryRecord> _categoryRecords = [];
  final Set<String> _selectedIds = <String>{};
  final List<_Product> _products = [];
  StreamSubscription<List<ProductRecord>>? _productsSub;
  StreamSubscription<List<ProductCategoryRecord>>? _categoriesSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _ordersSub;
  final Map<String, int> _salesByProduct = <String, int>{};
  final Map<String, double> _soldBaseQtyByProduct = <String, double>{};

  @override
  void initState() {
    super.initState();
    _productsSub = _productsRepository.watchProducts().listen(
      (records) {
        if (!mounted) return;
        setState(() {
          _products
            ..clear()
            ..addAll(records.map(_mapRecordToProduct));
          _isLoadingProducts = false;
        });
      },
      onError: (error) {
        if (!mounted) return;
        setState(() => _isLoadingProducts = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load products: $error')),
        );
      },
    );
    _categoriesSub = _productsRepository.watchCategories().listen(
      (records) {
        if (!mounted) return;
        setState(() {
          _categoryRecords
            ..clear()
            ..addAll(records);
        });
      },
      onError: (error) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load categories: $error')),
        );
      },
    );
    _subscribeOrderMetrics();
  }

  @override
  void dispose() {
    _productsSub?.cancel();
    _categoriesSub?.cancel();
    _ordersSub?.cancel();
    _searchController.dispose();
    _tableHorizontalScrollController.dispose();
    super.dispose();
  }

  void _subscribeOrderMetrics() {
    _ordersSub?.cancel();
    _ordersSub = _firestore
        .collection(FirestoreCollections.orders)
        .snapshots()
        .listen((snapshot) {
          final salesCounts = <String, int>{};
          final soldBase = <String, double>{};
          for (final doc in snapshot.docs) {
            final data = doc.data();
            final status = '${data['orderStatus'] ?? ''}'.toLowerCase();
            final isCompleted =
                status == 'delivered' ||
                status == 'completed' ||
                status == 'complete';
            if (!isCompleted) continue;
            final items = data['items'];
            if (items is! List) continue;
            for (final item in items) {
              if (item is! Map) continue;
              final map = item.map((k, v) => MapEntry('$k', v));
              final rawCode = '${map['productCode'] ?? ''}'.trim();
              if (rawCode.isEmpty) continue;
              final code = _normalizeProductCode(rawCode);
              final qtyBase = _doubleOr(map['qtyBase']);
              final soldQty = _doubleOr(map['qty']);
              final soldUnits = soldQty > 0 ? soldQty.round() : 1;
              salesCounts.update(
                code,
                (value) => value + soldUnits,
                ifAbsent: () => soldUnits,
              );
              soldBase.update(
                code,
                (value) => value + qtyBase,
                ifAbsent: () => qtyBase,
              );
            }
          }
          if (!mounted) return;
          setState(() {
            _salesByProduct
              ..clear()
              ..addAll(salesCounts);
            _soldBaseQtyByProduct
              ..clear()
              ..addAll(soldBase);
          });
        });
  }

  List<_Product> get _filteredProducts {
    return _products.where((product) {
      final matchesQuery =
          _query.isEmpty ||
          product.name.toLowerCase().contains(_query) ||
          product.id.toLowerCase().contains(_query) ||
          product.category.toLowerCase().contains(_query) ||
          product.linkedMarketing.toLowerCase().contains(_query);

      final matchesStock =
          _stockFilter == _StockFilter.all ||
          (_stockFilter == _StockFilter.inStock &&
              product.stockStatus == _StockStatus.inStock) ||
          (_stockFilter == _StockFilter.lowStock &&
              product.stockStatus == _StockStatus.lowStock) ||
          (_stockFilter == _StockFilter.soldOut &&
              product.stockStatus == _StockStatus.soldOut);

      final matchesVisibility =
          _visibilityFilter == _VisibilityFilter.all ||
          (_visibilityFilter == _VisibilityFilter.visibleOnly &&
              !product.isHidden) ||
          (_visibilityFilter == _VisibilityFilter.hiddenOnly &&
              product.isHidden);

      final matchesCategory =
          _categoryFilterKey == null ||
          product.category.trim().toLowerCase() == _categoryFilterKey;

      return matchesQuery &&
          matchesStock &&
          matchesVisibility &&
          matchesCategory;
    }).toList();
  }

  List<String> get _availableCategories {
    final byLower = <String, String>{};
    for (final record in _categoryRecords) {
      final name = record.name.trim();
      if (name.isEmpty) continue;
      byLower.putIfAbsent(name.toLowerCase(), () => name);
    }
    for (final product in _products) {
      final name = product.category.trim();
      if (name.isEmpty) continue;
      byLower.putIfAbsent(name.toLowerCase(), () => name);
    }
    final names = byLower.values.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return names;
  }

  String get _selectedCategoryLabel {
    if (_categoryFilterKey == null) return 'All Categories';
    for (final category in _availableCategories) {
      if (category.toLowerCase() == _categoryFilterKey) return category;
    }
    return _categoryFilterKey!;
  }

  int get _totalPages {
    final pages = (_filteredProducts.length / _rowsPerPage).ceil();
    return pages < 1 ? 1 : pages;
  }

  List<_Product> get _visibleProducts {
    final filtered = _filteredProducts;
    if (filtered.isEmpty) return const [];
    final safePage = _currentPage > _totalPages ? _totalPages : _currentPage;
    final start = (safePage - 1) * _rowsPerPage;
    final end = start + _rowsPerPage > filtered.length
        ? filtered.length
        : start + _rowsPerPage;
    return filtered.sublist(start, end);
  }

  Widget _buildBulkUploadView({bool inSideSheet = false}) {
    return BulkUploadProductsView(
      inSideSheet: inSideSheet,
      currencyCode: _currencyCode,
      onBack: () {
        Navigator.of(context).pop();
      },
      onUpsertOne: (product) async {
        await _productsRepository.upsertProduct(product);
      },
      onUpdateOne: (product) async {
        final normalizedCode = _normalizeProductCode(product.code);
        await _productsRepository.updateProduct(
          product: product,
          initialNormalizedCode: normalizedCode,
        );
      },
      onCreateOne: (product) async {
        await _productsRepository.createProduct(product);
      },
    );
  }

  Future<void> _openBulkUploadSideSheet() {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Bulk Upload',
      barrierColor: const Color(0x400F172A),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (context, _, __) {
        final width = MediaQuery.of(context).size.width;
        final sheetWidth = width > 1080 ? 460.0 : (width > 720 ? 420.0 : width);
        return Align(
          alignment: Alignment.centerRight,
          child: Material(
            color: Colors.white,
            child: SafeArea(
              child: SizedBox(
                width: sheetWidth,
                height: double.infinity,
                child: _buildBulkUploadView(inSideSheet: true),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, _, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOut,
        );
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_showCategoriesScreen) {
      return CategoriesManagementView(
        categories: _categoryRecords,
        onBack: () {
          setState(() => _showCategoriesScreen = false);
        },
        onCreateCategory: (name) async {
          await _productsRepository.createCategory(name);
        },
        onRenameCategory: ({required categoryId, required newName}) async {
          await _productsRepository.renameCategory(
            categoryId: categoryId,
            newName: newName,
          );
        },
        onDeleteCategory: (categoryId) async {
          await _productsRepository.deleteCategory(categoryId);
        },
      );
    }

    if (_showAddProductForm) {
      return AddEditProductFormView(
        existingNormalizedCodes: _products
            .map((p) => p.id.replaceAll('#', '').trim().toLowerCase())
            .toSet(),
        categories: _categoryRecords.map((c) => c.name).toList(),
        onCancel: () {
          setState(() {
            _showAddProductForm = false;
            _editingProduct = null;
          });
        },
        isEdit: _editingProduct != null,
        initialNormalizedCode: _editingProduct?.normalizedCode,
        initialData: _editingProduct == null
            ? null
            : _buildInitialDataFromProduct(_editingProduct!),
        onSave: _handleSaveProduct,
        currencyCode: _currencyCode,
      );
    }

    final filtered = _filteredProducts;
    final visible = _visibleProducts;
    final selectedCount = filtered
        .where((product) => _selectedIds.contains(product.id))
        .length;
    final isAllSelected =
        filtered.isNotEmpty && selectedCount == filtered.length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 1200;
        final isNarrow = constraints.maxWidth < 880;
        final tableWidth = constraints.maxWidth < 1420
            ? 1420.0
            : constraints.maxWidth;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(isCompact),
            const SizedBox(height: 14),
            isNarrow
                ? Column(
                    children: [
                      _buildSearchField(),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: _buildFilterButton(),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(child: _buildSearchField()),
                      const SizedBox(width: 10),
                      _buildFilterButton(),
                    ],
                  ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                IconButton(
                  onPressed: filtered.isEmpty
                      ? null
                      : () {
                          setState(() {
                            if (isAllSelected) {
                              for (final product in filtered) {
                                _selectedIds.remove(product.id);
                              }
                            } else {
                              for (final product in filtered) {
                                _selectedIds.add(product.id);
                              }
                            }
                          });
                        },
                  icon: Icon(
                    isAllSelected ? Iconsax.tick_square : Iconsax.square,
                    color: const Color(0xFF2EA8A5),
                  ),
                ),
                Text(
                  '$selectedCount Selected',
                  style: const TextStyle(
                    color: Color(0xFF2EA8A5),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextButton(
                  onPressed: filtered.isEmpty
                      ? null
                      : () {
                          setState(() {
                            for (final product in filtered) {
                              _selectedIds.add(product.id);
                            }
                          });
                        },
                  child: const Text('Select All'),
                ),
                TextButton.icon(
                  onPressed: selectedCount == 0 ? null : () {},
                  icon: const Icon(Iconsax.trash, size: 16),
                  label: const Text('Delete'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: _isLoadingProducts
                    ? const Center(child: CircularProgressIndicator())
                    : visible.isEmpty
                    ? const Center(
                        child: Text(
                          'No products found.',
                          style: TextStyle(
                            color: Color(0xFF6B7280),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      )
                    : isCompact
                    ? _buildCardList(visible)
                    : _buildDesktopTable(visible, tableWidth),
              ),
            ),
            const SizedBox(height: 12),
            _buildPaginationFooter(totalItems: filtered.length),
          ],
        );
      },
    );
  }

  Widget _buildHeader(bool compact) {
    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Product List',
            style: TextStyle(
              fontSize: 30,
              height: 1.1,
              color: Color(0xFF111827),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Track stock levels, availability, and restocking needs in real time.',
            style: TextStyle(
              color: Color(0xFF8A94A6),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _headerActionButton(
                onTap: () {
                  setState(() => _showCategoriesScreen = true);
                },
                icon: Iconsax.category,
                label: 'Categories',
              ),
              _headerActionButton(
                onTap: () {
                  unawaited(_openBulkUploadSideSheet());
                },
                icon: Iconsax.document_upload,
                label: 'Bulk Upload',
              ),
              _headerActionButton(
                onTap: () {
                  setState(() => _showAddProductForm = true);
                },
                icon: Iconsax.add,
                label: 'Add Product',
                highlighted: true,
              ),
            ],
          ),
        ],
      );
    }

    return Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Product List',
                style: TextStyle(
                  fontSize: 30,
                  height: 1.1,
                  color: Color(0xFF111827),
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Track stock levels, availability, and restocking needs in real time.',
                style: TextStyle(
                  color: Color(0xFF8A94A6),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        _headerActionButton(
          onTap: () {
            setState(() => _showCategoriesScreen = true);
          },
          icon: Iconsax.category,
          label: 'Categories',
        ),
        const SizedBox(width: 8),
        _headerActionButton(
          onTap: () {
            unawaited(_openBulkUploadSideSheet());
          },
          icon: Iconsax.document_upload,
          label: 'Bulk Upload',
        ),
        const SizedBox(width: 8),
        _headerActionButton(
          onTap: () {
            setState(() => _showAddProductForm = true);
          },
          icon: Iconsax.add,
          label: 'Add Product',
          highlighted: true,
        ),
      ],
    );
  }

  Widget _headerActionButton({
    required VoidCallback onTap,
    required IconData icon,
    required String label,
    bool highlighted = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
          border: Border.all(
            color: highlighted
                ? const Color(0xFF111827)
                : const Color(0xFFDDE2EA),
            width: highlighted ? 1.4 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 19, color: const Color(0xFF111827)),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF111827),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      onChanged: (value) {
        setState(() {
          _query = value.trim().toLowerCase();
          _currentPage = 1;
        });
      },
      decoration: InputDecoration(
        hintText: 'Search products',
        prefixIcon: const Icon(Iconsax.search_normal),
        fillColor: const Color(0xFFFFFFFF),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFDDE2EA)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFDDE2EA)),
        ),
      ),
    );
  }

  Widget _buildFilterButton() {
    return PopupMenuButton<String>(
      color: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 8,
      shadowColor: const Color(0x1A0F172A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      offset: const Offset(0, 42),
      onSelected: (value) {
        setState(() {
          switch (value) {
            case 'stock_all':
              _stockFilter = _StockFilter.all;
              break;
            case 'stock_in':
              _stockFilter = _StockFilter.inStock;
              break;
            case 'stock_low':
              _stockFilter = _StockFilter.lowStock;
              break;
            case 'stock_out':
              _stockFilter = _StockFilter.soldOut;
              break;
            case 'vis_all':
              _visibilityFilter = _VisibilityFilter.all;
              break;
            case 'vis_visible':
              _visibilityFilter = _VisibilityFilter.visibleOnly;
              break;
            case 'vis_hidden':
              _visibilityFilter = _VisibilityFilter.hiddenOnly;
              break;
            case 'cat_all':
              _categoryFilterKey = null;
              break;
            default:
              if (value.startsWith('cat:')) {
                _categoryFilterKey = value.substring(4);
              }
              break;
          }
          _currentPage = 1;
        });
      },
      itemBuilder: (context) {
        final categoryItems = _availableCategories
            .map(
              (name) => PopupMenuItem<String>(
                value: 'cat:${name.toLowerCase()}',
                child: Text(name),
              ),
            )
            .toList();
        return [
          const PopupMenuItem<String>(
            enabled: false,
            child: Text('Stock', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
          const PopupMenuItem(value: 'stock_all', child: Text('All Statuses')),
          const PopupMenuItem(value: 'stock_in', child: Text('In Stock')),
          const PopupMenuItem(value: 'stock_low', child: Text('Low Stock')),
          const PopupMenuItem(value: 'stock_out', child: Text('Sold Out')),
          const PopupMenuDivider(),
          const PopupMenuItem<String>(
            enabled: false,
            child: Text(
              'Visibility',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          const PopupMenuItem(value: 'vis_all', child: Text('All Products')),
          const PopupMenuItem(
            value: 'vis_visible',
            child: Text('Visible Only'),
          ),
          const PopupMenuItem(value: 'vis_hidden', child: Text('Hidden Only')),
          const PopupMenuDivider(),
          const PopupMenuItem<String>(
            enabled: false,
            child: Text(
              'Category',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          const PopupMenuItem(value: 'cat_all', child: Text('All Categories')),
          if (categoryItems.isEmpty)
            const PopupMenuItem<String>(
              enabled: false,
              child: Text('No categories'),
            ),
          ...categoryItems,
        ];
      },
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFDDE2EA)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Iconsax.filter4, size: 18),
            const SizedBox(width: 8),
            Text(switch (_stockFilter) {
              _StockFilter.all => 'All Status',
              _StockFilter.inStock => 'In Stock',
              _StockFilter.lowStock => 'Low Stock',
              _StockFilter.soldOut => 'Sold Out',
            }),
            const SizedBox(width: 6),
            const Text('•', style: TextStyle(color: Color(0xFF9CA3AF))),
            const SizedBox(width: 6),
            Text(switch (_visibilityFilter) {
              _VisibilityFilter.all => 'All',
              _VisibilityFilter.visibleOnly => 'Visible',
              _VisibilityFilter.hiddenOnly => 'Hidden',
            }),
            const SizedBox(width: 6),
            const Text('•', style: TextStyle(color: Color(0xFF9CA3AF))),
            const SizedBox(width: 6),
            Text(_selectedCategoryLabel),
            const SizedBox(width: 8),
            const Icon(Iconsax.arrow_down_1),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopTable(List<_Product> products, double width) {
    return Scrollbar(
      controller: _tableHorizontalScrollController,
      thumbVisibility: true,
      child: SingleChildScrollView(
        controller: _tableHorizontalScrollController,
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: width,
          child: Column(
            children: [
              _buildTableHeader(width),
              const Divider(height: 1, color: Color(0xFFE8EBF0)),
              Expanded(
                child: ListView.separated(
                  itemCount: products.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, color: Color(0xFFE8EBF0)),
                  itemBuilder: (context, index) {
                    final product = products[index];
                    final selected = _selectedIds.contains(product.id);
                    return _buildTableRow(product, selected, width);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTableHeader(double width) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      color: const Color(0xFFF8FAFC),
      child: Row(
        children: [
          SizedBox(width: 44),
          _HeaderCell(width: 124, text: 'Product ID'),
          _HeaderCell(width: 238, text: 'Product Name'),
          _HeaderCell(width: 168, text: 'Categories'),
          _HeaderCell(width: 158, text: 'Performance'),
          _HeaderCell(width: 120, text: 'Conversion'),
          _HeaderCell(width: 198, text: 'Linked Marketing'),
          _HeaderCell(width: 120, text: 'Price ($_currencyCode)'),
          _HeaderCell(width: 96, text: 'Sales'),
          _HeaderCell(width: 138, text: 'Stock Status'),
          _HeaderCell(width: 170, text: 'Available Stock'),
          _HeaderCell(width: 112, text: 'Action'),
        ],
      ),
    );
  }

  Widget _buildTableRow(_Product product, bool selected, double width) {
    final stockStyle = _stockStyle(product.stockStatus);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      color: selected ? const Color(0xFFF3FAFA) : Colors.white,
      child: Row(
        children: [
          SizedBox(
            width: 44,
            child: Checkbox(
              value: selected,
              onChanged: (_) {
                setState(() {
                  if (selected) {
                    _selectedIds.remove(product.id);
                  } else {
                    _selectedIds.add(product.id);
                  }
                });
              },
            ),
          ),
          _RowCell(width: 124, text: product.id),
          SizedBox(
            width: 238,
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: product.iconBackground,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: product.primaryImageUrl == null
                      ? Icon(product.icon, size: 17, color: product.iconColor)
                      : Image.network(
                          product.primaryImageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Icon(
                            product.icon,
                            size: 17,
                            color: product.iconColor,
                          ),
                        ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    product.name,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF111827),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          _RowCell(width: 168, text: product.category),
          _RowCell(width: 158, text: _performanceLabel(product.performance)),
          _RowCell(width: 120, text: '${_resolvedConversion(product)}%'),
          _RowCell(
            width: 198,
            text: product.linkedMarketing,
            color: const Color(0xFF2488B7),
          ),
          _RowCell(width: 120, text: _currency.format(product.priceQar)),
          _RowCell(width: 96, text: _resolvedSales(product).toString()),
          SizedBox(
            width: 138,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: stockStyle.$1,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: stockStyle.$3),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Iconsax.record_circle, size: 7, color: stockStyle.$2),
                    const SizedBox(width: 6),
                    Text(
                      stockStyle.$4,
                      style: TextStyle(
                        color: stockStyle.$2,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          _RowCell(
            width: 170,
            text:
                '${product.stockInBaseUnit.toStringAsFixed(2)} ${product.baseUnit}',
          ),
          SizedBox(width: 112, child: _buildProductActionMenu(product)),
        ],
      ),
    );
  }

  Widget _buildCardList(List<_Product> products) {
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: products.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final product = products[index];
        final stockStyle = _stockStyle(product.stockStatus);
        final selected = _selectedIds.contains(product.id);

        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFF3FAFA) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Checkbox(
                    value: selected,
                    onChanged: (_) {
                      setState(() {
                        if (selected) {
                          _selectedIds.remove(product.id);
                        } else {
                          _selectedIds.add(product.id);
                        }
                      });
                    },
                  ),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: product.iconBackground,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: product.primaryImageUrl == null
                        ? Icon(product.icon, size: 20, color: product.iconColor)
                        : Image.network(
                            product.primaryImageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Icon(
                              product.icon,
                              size: 20,
                              color: product.iconColor,
                            ),
                          ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: const TextStyle(
                            color: Color(0xFF111827),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          product.id,
                          style: const TextStyle(
                            color: Color(0xFF6B7280),
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: stockStyle.$1,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: stockStyle.$3),
                    ),
                    child: Text(
                      stockStyle.$4,
                      style: TextStyle(
                        color: stockStyle.$2,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _infoRow('Category', product.category),
              _infoRow('Performance', _performanceLabel(product.performance)),
              _infoRow('Conversion', '${_resolvedConversion(product)}%'),
              _infoRow('Linked Marketing', product.linkedMarketing),
              _infoRow('Price', _currency.format(product.priceQar)),
              _infoRow('Sales', _resolvedSales(product).toString()),
              _infoRow(
                'Available Stock',
                '${product.stockInBaseUnit.toStringAsFixed(2)} ${product.baseUnit}',
              ),
              _infoRow('Visibility', product.isHidden ? 'Hidden' : 'Visible'),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: _buildProductActionMenu(product),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 122,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF111827),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductActionMenu(_Product product) {
    return Align(
      alignment: Alignment.centerLeft,
      child: PopupMenuButton<_ProductAction>(
        tooltip: 'Product options',
        color: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 8,
        shadowColor: const Color(0x1A0F172A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        offset: const Offset(0, 42),
        icon: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFDDE2EA)),
          ),
          child: const Icon(
            Iconsax.setting,
            size: 18,
            color: Color(0xFF4B5563),
          ),
        ),
        onSelected: (action) => _handleProductAction(product, action),
        itemBuilder: (context) => [
          const PopupMenuItem<_ProductAction>(
            value: _ProductAction.view,
            child: Row(
              children: [
                Icon(Iconsax.monitor, size: 18, color: Color(0xFF2277B8)),
                SizedBox(width: 10),
                Text('View'),
              ],
            ),
          ),
          const PopupMenuItem<_ProductAction>(
            value: _ProductAction.edit,
            child: Row(
              children: [
                Icon(Iconsax.setting, size: 18, color: Color(0xFF374151)),
                SizedBox(width: 10),
                Text('Edit'),
              ],
            ),
          ),
          PopupMenuItem<_ProductAction>(
            value: _ProductAction.toggleVisibility,
            child: Row(
              children: [
                Icon(
                  product.isHidden ? Iconsax.eye : Iconsax.eye_slash,
                  size: 18,
                  color: const Color(0xFF4B5563),
                ),
                const SizedBox(width: 10),
                Text(product.isHidden ? 'Unhide' : 'Hide'),
              ],
            ),
          ),
          const PopupMenuItem<_ProductAction>(
            value: _ProductAction.delete,
            child: Row(
              children: [
                Icon(Iconsax.trash, size: 18, color: Color(0xFFE65A5A)),
                SizedBox(width: 10),
                Text('Delete'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handleProductAction(_Product product, _ProductAction action) {
    switch (action) {
      case _ProductAction.view:
        unawaited(_openProductDetailsSideSheet(product));
        break;
      case _ProductAction.edit:
        _openEditForm(product);
        break;
      case _ProductAction.toggleVisibility:
        _toggleProductVisibility(product);
        break;
      case _ProductAction.delete:
        _confirmDeleteProduct(product);
        break;
    }
  }

  Widget _buildPaginationFooter({required int totalItems}) {
    final totalPages = _totalPages;
    final safePage = _currentPage > totalPages ? totalPages : _currentPage;
    final pager = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _paginationButton(
          icon: Iconsax.arrow_left_2,
          enabled: safePage > 1,
          onTap: () {
            setState(() {
              if (_currentPage > 1) _currentPage--;
            });
          },
        ),
        const SizedBox(width: 8),
        Container(
          width: 42,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFF111827),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            safePage.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 8),
        _paginationButton(
          icon: Iconsax.arrow_right_2,
          enabled: safePage < totalPages,
          onTap: () {
            setState(() {
              if (_currentPage < totalPages) _currentPage++;
            });
          },
        ),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 760;
        if (isNarrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 10,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFDDE2EA)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Show: 13',
                          style: TextStyle(
                            color: Color(0xFF111827),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Iconsax.arrow_swap, size: 17),
                      ],
                    ),
                  ),
                  Text(
                    '$totalItems items',
                    style: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Align(alignment: Alignment.centerRight, child: pager),
            ],
          );
        }

        return Row(
          children: [
            Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFDDE2EA)),
              ),
              child: const Row(
                children: [
                  Text(
                    'Show: 13',
                    style: TextStyle(
                      color: Color(0xFF111827),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(Iconsax.arrow_swap, size: 17),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '$totalItems items',
              style: const TextStyle(
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            pager,
          ],
        );
      },
    );
  }

  Widget _paginationButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFDDE2EA)),
        ),
        child: Icon(
          icon,
          color: enabled ? const Color(0xFF111827) : const Color(0xFFBDC4D2),
        ),
      ),
    );
  }

  String _performanceLabel(_PerformanceLevel performance) {
    switch (performance) {
      case _PerformanceLevel.excellent:
        return 'Excellent';
      case _PerformanceLevel.veryGood:
        return 'Very Good';
      case _PerformanceLevel.good:
        return 'Good';
    }
  }

  (Color, Color, Color, String) _stockStyle(_StockStatus status) {
    switch (status) {
      case _StockStatus.inStock:
        return (
          const Color(0xFFEFFAF3),
          const Color(0xFF21A453),
          const Color(0xFFD1F0DD),
          'In Stock',
        );
      case _StockStatus.lowStock:
        return (
          const Color(0xFFFFF8E8),
          const Color(0xFFDD9C00),
          const Color(0xFFF8EAC6),
          'Low Stock',
        );
      case _StockStatus.soldOut:
        return (
          const Color(0xFFFFEEF0),
          const Color(0xFFE44949),
          const Color(0xFFF7D5DA),
          'Sold Out',
        );
    }
  }

  Future<void> _handleSaveProduct(ProductFormResult result) async {
    final editing = _editingProduct;
    if (editing == null) {
      await _productsRepository.createProduct(result);
    } else {
      await _productsRepository.updateProduct(
        product: result,
        initialNormalizedCode: editing.normalizedCode,
      );
    }
    if (!mounted) return;

    setState(() {
      _showAddProductForm = false;
      _editingProduct = null;
      _query = '';
      _currentPage = 1;
      _stockFilter = _StockFilter.all;
      _categoryFilterKey = null;
      _selectedIds.clear();
      _searchController.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Product ${result.name} saved successfully (${result.baseUnit} base unit)',
        ),
      ),
    );
  }

  void _openEditForm(_Product product) {
    setState(() {
      _editingProduct = product;
      _showAddProductForm = true;
    });
  }

  Future<void> _toggleProductVisibility(_Product product) async {
    final hide = !product.isHidden;
    try {
      await _productsRepository.setProductHidden(
        normalizedCode: product.normalizedCode,
        hidden: hide,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            hide
                ? '${product.name} is now hidden.'
                : '${product.name} is now visible.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update visibility: $error')),
      );
    }
  }

  Future<void> _confirmDeleteProduct(_Product product) async {
    final shouldDelete = await _showConfirmSideSheet(
      title: 'Delete Product',
      message: 'Delete "${product.name}" permanently?',
      confirmLabel: 'Delete',
    );
    if (shouldDelete != true) return;

    try {
      await _productsRepository.deleteProduct(product.normalizedCode);
      if (!mounted) return;
      _selectedIds.remove(product.id);
      setState(() {});
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${product.name} deleted.')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete product: $error')),
      );
    }
  }

  (IconData, Color, Color) _visualByCategory(String category) {
    switch (category) {
      case 'Laptop & PC':
        return (
          Iconsax.monitor,
          const Color(0xFF0F766E),
          const Color(0xFFE6FFFA),
        );
      case 'Smartphone':
        return (
          Iconsax.mobile,
          const Color(0xFF1F2937),
          const Color(0xFFE0E7FF),
        );
      case 'Accessories':
        return (
          Iconsax.airpod,
          const Color(0xFF374151),
          const Color(0xFFE5E7EB),
        );
      default:
        return (Iconsax.box, const Color(0xFF6B7280), const Color(0xFFF1F5F9));
    }
  }

  _Product _mapRecordToProduct(ProductRecord record) {
    final visual = _visualByCategory(record.category);
    final stockStatus = record.stockInBaseUnit <= 0
        ? _StockStatus.soldOut
        : record.stockInBaseUnit < 100
        ? _StockStatus.lowStock
        : _StockStatus.inStock;

    return _Product(
      normalizedCode: record.code.replaceAll('#', '').trim().toLowerCase(),
      id: record.code.startsWith('#') ? record.code : '#${record.code}',
      name: record.name,
      category: record.category,
      performance: _PerformanceLevel.good,
      conversionPercent: 0,
      linkedMarketing: record.linkedMarketing,
      priceQar: record.displayPriceQar,
      sales: record.salesCount,
      stockStatus: stockStatus,
      icon: visual.$1,
      iconColor: visual.$2,
      iconBackground: visual.$3,
      description: record.description,
      baseUnit: record.baseUnit,
      saleUnits: record.saleUnits,
      saleUnitConfigs: record.saleUnitConfigs,
      marketPricingByMarket: record.marketPricingByMarket,
      initialStockInput: record.initialStockInput,
      initialStockInputUnit: record.initialStockInputUnit,
      stockInBaseUnit: record.stockInBaseUnit,
      offerPriceQar: record.displayOfferPriceQar,
      isHidden: record.isHidden,
      imageUrls: record.imageUrls,
      primaryImageUrl: record.primaryImageUrl,
    );
  }

  ProductFormInitialData _buildInitialDataFromProduct(_Product product) {
    return ProductFormInitialData(
      name: product.name,
      code: product.id,
      description: product.description,
      category: product.category,
      baseUnit: product.baseUnit,
      saleUnits: product.saleUnitConfigs,
      marketPricingByMarket: product.marketPricingByMarket,
      initialStockInput: product.initialStockInput,
      initialStockInputUnit: product.initialStockInputUnit ?? product.baseUnit,
      imageUrls: product.imageUrls,
    );
  }

  Future<bool?> _showConfirmSideSheet({
    required String title,
    required String message,
    required String confirmLabel,
  }) {
    return showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: title,
      barrierColor: const Color(0x400F172A),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (context, _, __) {
        final width = MediaQuery.of(context).size.width;
        final sheetWidth = width > 1080 ? 460.0 : (width > 720 ? 420.0 : width);
        return Align(
          alignment: Alignment.centerRight,
          child: Material(
            color: Colors.white,
            child: SafeArea(
              child: SizedBox(
                width: sheetWidth,
                height: double.infinity,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.fromLTRB(18, 14, 10, 14),
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
                                color: Color(0xFF111827),
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            icon: const Icon(Iconsax.close_circle, size: 20),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Text(
                          message,
                          style: const TextStyle(
                            color: Color(0xFF111827),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: FilledButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: Text(confirmLabel),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, _, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOut,
        );
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        );
      },
    );
  }

  Future<void> _openProductDetailsSideSheet(_Product product) {
    final stockStyle = _stockStyle(product.stockStatus);
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Product Details',
      barrierColor: const Color(0x400F172A),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (context, _, __) {
        final width = MediaQuery.of(context).size.width;
        final sheetWidth = width > 1400 ? 680.0 : (width > 980 ? 620.0 : width);
        return Align(
          alignment: Alignment.centerRight,
          child: Material(
            color: const Color(0xFFF8FAFC),
            child: SafeArea(
              child: SizedBox(
                width: sheetWidth,
                height: double.infinity,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: ProductDetailsView(
                    data: ProductDetailsData(
                      id: product.id,
                      name: product.name,
                      category: product.category,
                      description: product.description,
                      baseUnit: product.baseUnit,
                      saleUnits: product.saleUnits,
                      saleUnitConfigs: product.saleUnitConfigs,
                      marketPricingByMarket: product.marketPricingByMarket,
                      stockInBaseUnit: product.stockInBaseUnit,
                      initialStockInput: product.initialStockInput,
                      initialStockInputUnit:
                          product.initialStockInputUnit ?? product.baseUnit,
                      priceQar: product.priceQar,
                      offerPriceQar: product.offerPriceQar,
                      sales: _resolvedSales(product),
                      linkedMarketing: product.linkedMarketing,
                      isHidden: product.isHidden,
                      stockStatusLabel: stockStyle.$4,
                      stockStatusColor: stockStyle.$2,
                      stockStatusBackground: stockStyle.$1,
                      icon: product.icon,
                      iconColor: product.iconColor,
                      iconBackground: product.iconBackground,
                      imageUrl: product.primaryImageUrl,
                      imageUrls: product.imageUrls,
                    ),
                    onBack: () => Navigator.of(context).pop(),
                    onEdit: () {
                      Navigator.of(context).pop();
                      _openEditForm(product);
                    },
                    currencyCode: _currencyCode,
                  ),
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, _, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOut,
        );
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        );
      },
    );
  }

  int _resolvedSales(_Product product) {
    final live = _salesByProduct[product.normalizedCode] ?? 0;
    return live > 0 ? live : product.sales;
  }

  int _resolvedConversion(_Product product) {
    final soldBase = _soldBaseQtyByProduct[product.normalizedCode] ?? 0;
    final denominator = soldBase + product.stockInBaseUnit;
    if (denominator <= 0) return product.conversionPercent;
    final livePercent = ((soldBase / denominator) * 100).round();
    return livePercent > product.conversionPercent
        ? livePercent
        : product.conversionPercent;
  }

  String _normalizeProductCode(String code) {
    return code.replaceAll('#', '').trim().toLowerCase();
  }

  double _doubleOr(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.trim()) ?? 0;
    return 0;
  }
}

class _HeaderCell extends StatelessWidget {
  final double width;
  final String text;

  const _HeaderCell({required this.width, required this.text});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF4B5565),
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
      ),
    );
  }
}

class _RowCell extends StatelessWidget {
  final double width;
  final String text;
  final Color color;

  const _RowCell({
    required this.width,
    required this.text,
    this.color = const Color(0xFF1F2937),
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
