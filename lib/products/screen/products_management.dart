import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:products_catelogs/products/provider/products_management_pro.dart';
import 'package:products_catelogs/products/screen/add_products.dart';
import 'package:products_catelogs/products/screen/edit_products.dart';
import 'package:provider/provider.dart';

class ProductsManagement extends StatefulWidget {
  const ProductsManagement({super.key});

  @override
  State<ProductsManagement> createState() => _ProductsManagementState();
}

class _ProductsManagementState extends State<ProductsManagement> {
  final ScrollController _scrollController = ScrollController();
  static const double _scrollThreshold = 200.0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;

    if (currentScroll >= maxScroll - _scrollThreshold) {
      _loadMoreProducts();
    }
  }

  void _loadMoreProducts() {
    final provider = context.read<ProductProvider>();
    if (!provider.isLoadingMore && provider.hasMoreProducts) {
      provider.loadMoreProducts();
    }
  }

  Future<void> _refreshProducts() async {
    await context.read<ProductProvider>().refreshProducts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: _buildAppBar(),
      body: RefreshIndicator(
        onRefresh: _refreshProducts,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            _buildSearchBar(),
            _buildStatsBar(),
            _buildProductsList(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToAddProduct(context),
        icon: const Icon(Iconsax.add),
        label: const Text("Add"),
      ),
    );
  }

  // ==================== APP BAR ====================
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text("Products Management"),
      actions: [
        IconButton(
          icon: const Icon(Iconsax.refresh),
          onPressed: _refreshProducts,
          tooltip: 'Refresh',
        ),
      ],
    );
  }

  // ==================== SEARCH BAR ====================
  Widget _buildSearchBar() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  hintText: "Search products...",
                  prefixIcon: const Icon(Iconsax.search_normal_1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onChanged: (value) {
                  context.read<ProductProvider>().setSearchQuery(value);
                },
              ),
            ),
            const SizedBox(width: 12),
            Consumer<ProductProvider>(
              builder: (context, provider, _) {
                final hasFilters = provider.selectedFilterCategories.isNotEmpty;
                return IconButton.filled(
                  icon: Badge(
                    isLabelVisible: hasFilters,
                    label: Text('${provider.selectedFilterCategories.length}'),
                    child: const Icon(Iconsax.filter),
                  ),
                  onPressed: () => _showFilterBottomSheet(context),
                  style: IconButton.styleFrom(
                    backgroundColor: hasFilters 
                      ? Theme.of(context).primaryColor 
                      : null,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ==================== STATS BAR ====================
  Widget _buildStatsBar() {
    return SliverToBoxAdapter(
      child: Consumer<ProductProvider>(
        builder: (context, provider, _) {
          final total = provider.filteredProducts.length;
          final visible = provider.filteredProducts.where((p) => !p.isHidden).length;
          final hidden = provider.filteredProducts.where((p) => p.isHidden).length;

          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem("Total", total.toString(), Iconsax.box),
                _buildStatItem("Visible", visible.toString(), Iconsax.eye),
                _buildStatItem("Hidden", hidden.toString(), Iconsax.eye_slash),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  // ==================== PRODUCTS LIST ====================
  Widget _buildProductsList() {
    return Consumer<ProductProvider>(
      builder: (context, provider, _) {
        if (!provider.initialLoadComplete) {
          return const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final products = provider.filteredProducts;

        if (products.isEmpty) {
          return _buildEmptyState();
        }

        return SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                if (index == products.length) {
                  return _buildLoadingIndicator(provider);
                }
                return _ProductCard(
                  key: ValueKey(products[index].id),
                  product: products[index],
                );
              },
              childCount: products.length + 1,
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Iconsax.box, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              "No products found",
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              "Try adjusting your search or filters",
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator(ProductProvider provider) {
    if (!provider.isLoadingMore) return const SizedBox(height: 80);
    
    return const Padding(
      padding: EdgeInsets.all(16.0),
      child: Center(child: CircularProgressIndicator()),
    );
  }

  void _navigateToAddProduct(BuildContext context) {
    context.read<ProductProvider>().resetForm();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddProducts()),
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _FilterBottomSheet(),
    );
  }
}

// ==================== PRODUCT CARD ====================
class _ProductCard extends StatelessWidget {
  final Product product;

  const _ProductCard({
    super.key,
    required this.product,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _navigateToEdit(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProductImage(),
              const SizedBox(width: 12),
              Expanded(
                child: _buildProductInfo(context),
              ),
              _buildActionMenu(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductImage() {
    final hasImage = product.images.isNotEmpty && product.images.first.isNotEmpty;

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 80,
        height: 80,
        color: Colors.grey[200],
        child: hasImage
            ? Image.network(
                product.images.first,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(Iconsax.image),
                loadingBuilder: (_, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  );
                },
              )
            : const Icon(Iconsax.image, size: 32),
      ),
    );
  }

  Widget _buildProductInfo(BuildContext context) {
    final theme = Theme.of(context);
    final hasOffer = product.offerPrice != null;
    final displayPrice = hasOffer ? product.offerPrice! : product.price;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Product Name
        Text(
          product.name,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        
        // Category & Status Row
        Row(
          children: [
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  product.categoryId,
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.primaryColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: product.isHidden
                    ? Colors.red.withOpacity(0.1)
                    : Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                product.isHidden ? "Hidden" : "Visible",
                style: TextStyle(
                  fontSize: 11,
                  color: product.isHidden ? Colors.red : Colors.green,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        
        // Price Section
        Row(
          children: [
            Text(
              "QR ${displayPrice.toStringAsFixed(2)}",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: hasOffer ? Colors.green : theme.primaryColor,
              ),
            ),
            if (hasOffer && product.price != product.offerPrice) ...[
              const SizedBox(width: 8),
              Text(
                "QR ${product.price.toStringAsFixed(2)}",
                style: const TextStyle(
                  fontSize: 12,
                  decoration: TextDecoration.lineThrough,
                  color: Colors.grey,
                ),
              ),
            ],
          ],
        ),
        
        // Stock Warning
        if (product.stock <= 10)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                Icon(
                  Iconsax.warning_2,
                  size: 14,
                  color: Colors.orange[700],
                ),
                const SizedBox(width: 4),
                Text(
                  "Low stock (${product.stock})",
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.orange[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildActionMenu(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Iconsax.edit, size: 18),
              SizedBox(width: 12),
              Text('Edit'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'price',
          child: Row(
            children: [
              Icon(Iconsax.dollar_circle, size: 18),
              SizedBox(width: 12),
              Text('Update Prices'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'visibility',
          child: Row(
            children: [
              Icon(
                product.isHidden ? Iconsax.eye : Iconsax.eye_slash,
                size: 18,
              ),
              const SizedBox(width: 12),
              Text(product.isHidden ? 'Show' : 'Hide'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Iconsax.trash, size: 18, color: Colors.red),
              SizedBox(width: 12),
              Text('Delete', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
      onSelected: (value) {
        switch (value) {
          case 'edit':
            _navigateToEdit(context);
            break;
          case 'price':
            _showPriceEditSheet(context);
            break;
          case 'visibility':
            _toggleVisibility(context);
            break;
          case 'delete':
            _confirmDelete(context);
            break;
        }
      },
    );
  }

  void _navigateToEdit(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditProducts(product: product),
      ),
    );
  }

  void _showPriceEditSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _PriceEditBottomSheet(product: product),
    );
  }

  Future<void> _toggleVisibility(BuildContext context) async {
    final provider = context.read<ProductProvider>();
    await provider.toggleProductVisibility(product.id, !product.isHidden);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            product.isHidden
                ? "Product is now visible"
                : "Product is now hidden",
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Product"),
        content: Text("Delete '${product.name}'? This cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          FilledButton(
            onPressed: () {
              context.read<ProductProvider>().deleteProduct(product.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Product deleted")),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }
}

// ==================== FILTER BOTTOM SHEET ====================
class _FilterBottomSheet extends StatelessWidget {
  const _FilterBottomSheet();

  @override
  Widget build(BuildContext context) {
    return Consumer<ProductProvider>(
      builder: (context, provider, _) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Filter by Category",
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (provider.selectedFilterCategories.isNotEmpty)
                      TextButton(
                        onPressed: () {
                          for (var cat in List.from(provider.selectedFilterCategories)) {
                            provider.toggleFilterCategory(cat);
                          }
                        },
                        child: const Text("Clear All"),
                      ),
                  ],
                ),
              ),
              
              const Divider(height: 1),
              
              // Categories List
              Flexible(
                child: provider.categories.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Text("No categories available"),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: provider.categories.length,
                        itemBuilder: (context, index) {
                          final category = provider.categories[index];
                          final isSelected = provider.selectedFilterCategories
                              .contains(category.name);

                          return CheckboxListTile(
                            title: Text(category.name),
                            value: isSelected,
                            onChanged: (_) {
                              provider.toggleFilterCategory(category.name);
                            },
                          );
                        },
                      ),
              ),
              
              const Divider(height: 1),
              
              // Apply Button
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Apply Filters"),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ==================== PRICE EDIT BOTTOM SHEET ====================
class _PriceEditBottomSheet extends StatefulWidget {
  final Product product;

  const _PriceEditBottomSheet({required this.product});

  @override
  State<_PriceEditBottomSheet> createState() => _PriceEditBottomSheetState();
}

class _PriceEditBottomSheetState extends State<_PriceEditBottomSheet> {
  late final TextEditingController _offerPriceController;
  late final TextEditingController _hypermarketPriceController;

  @override
  void initState() {
    super.initState();
    _offerPriceController = TextEditingController(
      text: widget.product.offerPrice?.toString() ?? "",
    );
    _hypermarketPriceController = TextEditingController(
      text: widget.product.hyperMarketPrice?.toString() ?? "",
    );
  }

  @override
  void dispose() {
    _offerPriceController.dispose();
    _hypermarketPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Update Prices",
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.product.name,
            style: TextStyle(color: Colors.grey[600]),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 20),
          
          TextField(
            controller: _offerPriceController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: "Offer Price",
              prefixIcon: const Icon(Iconsax.tag),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          TextField(
            controller: _hypermarketPriceController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: "Hypermarket Price",
              prefixIcon: const Icon(Iconsax.shop),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 20),
          
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () => _savePrices(context),
                  child: const Text("Save"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _savePrices(BuildContext context) {
    final offerPrice = double.tryParse(_offerPriceController.text);
    final hyperPrice = double.tryParse(_hypermarketPriceController.text);

    final provider = context.read<ProductProvider>();
    
    if (offerPrice != null) {
      provider.setOfferPrice(widget.product, offerPrice);
    }
    
    if (hyperPrice != null) {
      provider.setHyperMarketPrice(widget.product, hyperPrice);
    }

    Navigator.pop(context);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Prices updated successfully")),
    );
  }
}

// ==================== IMAGE PREVIEW PAGE ====================
class ImagePreviewPage extends StatelessWidget {
  final List<String> images;
  final int initialIndex;

  const ImagePreviewPage({
    super.key,
    required this.images,
    this.initialIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: PageView.builder(
        controller: PageController(initialPage: initialIndex),
        itemCount: images.length,
        itemBuilder: (context, index) {
          return InteractiveViewer(
            minScale: 1.0,
            maxScale: 4.0,
            child: Center(
              child: Image.network(
                images[index],
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.error_outline,
                  color: Colors.white,
                  size: 60,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}