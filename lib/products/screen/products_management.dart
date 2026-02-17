import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:products_catelogs/products/provider/products_management_pro.dart';
import 'package:products_catelogs/products/screen/add_products.dart';
import 'package:products_catelogs/products/screen/bulk.dart';
import 'package:products_catelogs/products/screen/edit_products.dart';
import 'package:products_catelogs/theme/colors.dart';
import 'package:products_catelogs/theme/widgets/app_components.dart';
import 'package:products_catelogs/theme/widgets/reference_scaffold.dart';
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
    return ReferenceScaffold(
      title: "Products Management",
      subtitle: "Catalog and pricing",
      bodyPadding: EdgeInsets.zero,
      actions: [
        IconButton(
          icon: const Icon(Icons.upload_file_rounded),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const BulkProductUploadScreen(),
              ),
            );
          },
          tooltip: 'Bulk Upload',
        ),
        IconButton(
          icon: const Icon(Iconsax.refresh),
          onPressed: _refreshProducts,
          tooltip: 'Refresh',
        ),
      ],
      body: RefreshIndicator(
        onRefresh: _refreshProducts,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [_buildSearchBar(), _buildStatsBar(), _buildProductsList()],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToAddProduct(context),
        icon: const Icon(Iconsax.add),
        label: const Text("Add"),
      ),
    );
  }

  // ==================== SEARCH BAR ====================
  Widget _buildSearchBar() {
    final theme = Theme.of(context);
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
                  filled: true,
                  fillColor: theme.cardColor,
                  suffixIcon: Icon(
                    Iconsax.command_square,
                    color: theme.textTheme.bodySmall?.color,
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
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).cardColor,
                    foregroundColor: hasFilters
                        ? Colors.white
                        : Theme.of(context).colorScheme.onSurface,
                    side: hasFilters
                        ? null
                        : BorderSide(color: Theme.of(context).dividerColor),
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
    final theme = Theme.of(context);
    return SliverToBoxAdapter(
      child: Consumer<ProductProvider>(
        builder: (context, provider, _) {
          final total = provider.filteredProducts.length;
          final visible = provider.filteredProducts
              .where((p) => !p.isHidden)
              .length;
          final hidden = provider.filteredProducts
              .where((p) => p.isHidden)
              .length;

          return AppSectionCard(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(14),
            color: theme.colorScheme.primary.withAlpha(14),
            child: Row(
              children: [
                Expanded(
                  child: _buildStatItem("Total", total.toString(), Iconsax.box),
                ),
                Expanded(
                  child: _buildStatItem(
                    "Visible",
                    visible.toString(),
                    Iconsax.eye,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    "Hidden",
                    hidden.toString(),
                    Iconsax.eye_slash,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.primary),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(label, style: theme.textTheme.bodySmall),
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
            delegate: SliverChildBuilderDelegate((context, index) {
              if (index == products.length) {
                return _buildLoadingIndicator(provider);
              }
              return _ProductCard(
                key: ValueKey(products[index].id),
                product: products[index],
              );
            }, childCount: products.length + 1),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return SliverFillRemaining(
      child: AppEmptyState(
        icon: Iconsax.box,
        title: "No products found",
        subtitle: "Try adjusting your search or category filters",
        action: OutlinedButton(
          onPressed: () => _navigateToAddProduct(context),
          child: const Text("Add Product"),
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

  const _ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _navigateToEdit(context),
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProductImage(),
              const SizedBox(width: 12),
              Expanded(child: _buildProductInfo(context)),
              const SizedBox(width: 4),
              _buildActionMenu(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductImage() {
    final hasImage =
        product.images.isNotEmpty && product.images.first.isNotEmpty;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 80,
        height: 80,
        color: AppColors.lightMutedSurface,
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
        Text(
          product.name,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),

        Row(
          children: [
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withAlpha(14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  product.categoryId,
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: product.isHidden
                    ? Colors.red.withAlpha(22)
                    : AppColors.success.withAlpha(24),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                product.isHidden ? "Hidden" : "Visible",
                style: TextStyle(
                  fontSize: 11,
                  color: product.isHidden
                      ? Colors.red.shade700
                      : AppColors.success,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        Row(
          children: [
            Text(
              "QAR ${displayPrice.toStringAsFixed(2)}",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.primary,
              ),
            ),
            if (hasOffer && product.price != product.offerPrice) ...[
              const SizedBox(width: 8),
              Text(
                "QAR ${product.price.toStringAsFixed(2)}",
                style: TextStyle(
                  fontSize: 12,
                  decoration: TextDecoration.lineThrough,
                  color: theme.textTheme.bodySmall?.color,
                ),
              ),
            ],
          ],
        ),

        if (product.stock <= 10)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                Icon(Iconsax.warning_2, size: 14, color: AppColors.warning),
                const SizedBox(width: 4),
                Text(
                  "Low stock (${product.stock})",
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.warning,
                    fontWeight: FontWeight.w600,
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
      icon: const Icon(Icons.more_vert_rounded),
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
      MaterialPageRoute(builder: (_) => EditProducts(product: product)),
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
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text("Product deleted")));
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
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
    final theme = Theme.of(context);
    return Consumer<ProductProvider>(
      builder: (context, provider, _) {
        return SafeArea(
          top: false,
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.75,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Filter by Category",
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (provider.selectedFilterCategories.isNotEmpty)
                        TextButton(
                          onPressed: () {
                            for (var cat in List.from(
                              provider.selectedFilterCategories,
                            )) {
                              provider.toggleFilterCategory(cat);
                            }
                          },
                          child: const Text("Clear All"),
                        ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Flexible(
                  child: provider.categories.isEmpty
                      ? const AppEmptyState(
                          title: "No categories available",
                          subtitle: "Create categories first to use filters",
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
    final theme = Theme.of(context);
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 10,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: AppSectionCard(
          title: "Update Prices",
          subtitle: widget.product.name,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _offerPriceController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: "Offer Price",
                  prefixIcon: Icon(Iconsax.tag),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _hypermarketPriceController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: "Hypermarket Price",
                  prefixIcon: Icon(Iconsax.shop),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: theme.dividerColor),
                      ),
                      child: const Text("Cancel"),
                    ),
                  ),
                  const SizedBox(width: 10),
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
        ),
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
