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
  static const double _scrollThreshold = 300.0;

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
    final threshold = maxScroll - _scrollThreshold;

    if (currentScroll >= threshold) {
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
      appBar: _buildAppBar(context),
      body: RefreshIndicator(
        onRefresh: _refreshProducts,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            _buildSearchAndFilterBar(context),
            _buildProductsList(),
          ],
        ),
      ),
    );
  }

  // ==================== APP BAR ====================
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      title: const Text("Products"),
      actions: [
        IconButton(
          onPressed: () => _navigateToAddProduct(context),
          icon: const Icon(Iconsax.add),
          tooltip: 'Add Product',
        ),
      ],
    );
  }

  void _navigateToAddProduct(BuildContext context) {
    context.read<ProductProvider>().resetForm();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddProducts()),
    );
  }

  // ==================== SEARCH & FILTER BAR ====================
  Widget _buildSearchAndFilterBar(BuildContext context) {
    final theme = Theme.of(context);
    
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Expanded(
              flex: 5,
              child: _SearchBar(theme: theme),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 1,
              child: _FilterButton(
                theme: theme,
                onPressed: () => _showFilterBottomSheet(context),
              ),
            ),
          ],
        ),
      ),
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
          return _buildEmptyState(context);
        }

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
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
              findChildIndexCallback: (Key key) {
                final valueKey = key as ValueKey<String>;
                final products = provider.filteredProducts;
                for (int i = 0; i < products.length; i++) {
                  if (products[i].id == valueKey.value) {
                    return i;
                  }
                }
                return null;
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'asstes/Image-3.png',
              width: 200,
              height: 200,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 16),
            Text(
              "No products found",
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator(ProductProvider provider) {
    if (!provider.isLoadingMore) return const SizedBox.shrink();
    
    return const Padding(
      padding: EdgeInsets.all(16.0),
      child: Center(child: CircularProgressIndicator()),
    );
  }

  // ==================== FILTER BOTTOM SHEET ====================
  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _FilterBottomSheet(),
    );
  }
}

// ==================== SEARCH BAR WIDGET ====================
class _SearchBar extends StatelessWidget {
  final ThemeData theme;

  const _SearchBar({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(40),
        color: theme.cardColor,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(Icons.search, color: theme.iconTheme.color),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              decoration: const InputDecoration(
                hintText: "Search products...",
                border: InputBorder.none,
              ),
              onChanged: (value) {
                context.read<ProductProvider>().setSearchQuery(value);
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== FILTER BUTTON WIDGET ====================
class _FilterButton extends StatelessWidget {
  final ThemeData theme;
  final VoidCallback onPressed;

  const _FilterButton({
    required this.theme,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(40),
        color: theme.cardColor,
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: const Icon(Iconsax.filter),
        tooltip: 'Filter Products',
      ),
    );
  }
}

// ==================== PRODUCT CARD WIDGET ====================
class _ProductCard extends StatelessWidget {
  final Product product;

  const _ProductCard({
    super.key,
    required this.product,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: GestureDetector(
        onLongPress: () => _showProductOptions(context),
        child: Container(
          height: 120,
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                _ProductImage(product: product),
                const SizedBox(width: 10),
                Expanded(
                  child: _ProductDetails(product: product, theme: theme),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showProductOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ProductOptionsBottomSheet(product: product),
    );
  }
}

// ==================== PRODUCT IMAGE WIDGET ====================
class _ProductImage extends StatelessWidget {
  final Product product;

  const _ProductImage({required this.product});

  bool get _hasValidImage =>
      product.images.isNotEmpty && product.images.first.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _hasValidImage ? _showImagePreview(context) : null,
      child: _hasValidImage ? _buildNetworkImage() : _buildPlaceholder(),
    );
  }

  Widget _buildNetworkImage() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 100,
        height: 100,
        child: Image.network(
          product.images.first,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildPlaceholder(),
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return const Icon(Iconsax.image, size: 60);
  }

  void _showImagePreview(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ImagePreviewPage(images: product.images),
      ),
    );
  }
}

// ==================== PRODUCT DETAILS WIDGET ====================
class _ProductDetails extends StatelessWidget {
  final Product product;
  final ThemeData theme;

  const _ProductDetails({
    required this.product,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildProductName(),
        _buildCategoryAndStatus(),
        const SizedBox(height: 10),
        _buildPriceSection(context),
      ],
    );
  }

  Widget _buildProductName() {
    return Text(
      product.name,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: theme.textTheme.bodyLarge?.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildCategoryAndStatus() {
    return Row(
      children: [
        Text(
          product.categoryId,
          style: theme.textTheme.bodyMedium,
        ),
        const Spacer(),
        Text(
          product.isHidden ? "Hidden" : "Visible",
          style: theme.textTheme.bodyMedium?.copyWith(
            color: product.isHidden ? Colors.red : Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildPriceSection(BuildContext context) {
    return InkWell(
      onTap: () => _showPriceEditSheet(context),
      child: Row(
        children: [
          if (_hasOfferPrice) _buildOfferPrice(),
          if (_hasOfferPrice && _hasHyperMarketPrice)
            const SizedBox(width: 10),
          if (_hasHyperMarketPrice) _buildHyperMarketPrice(),
        ],
      ),
    );
  }

  bool get _hasOfferPrice =>
      product.offerPrice != null || (product.price != null && product.price != 0);

  bool get _hasHyperMarketPrice =>
      product.hyperMarketPrice != null || product.hyperMarket != null;

  Widget _buildOfferPrice() {
    final price = product.offerPrice ?? product.price;
    return Text(
      "Qr ${price.toStringAsFixed(2)}",
      style: theme.textTheme.bodySmall?.copyWith(
        color: Colors.green,
        fontSize: 15,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildHyperMarketPrice() {
    final price = product.hyperMarketPrice ?? product.hyperMarket;
    return Text(
      "Qr ${price?.toStringAsFixed(2) ?? '0.00'}",
      style: theme.textTheme.bodySmall?.copyWith(
        color: Colors.red,
        fontSize: 15,
        fontWeight: FontWeight.bold,
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
}

// ==================== FILTER BOTTOM SHEET ====================
class _FilterBottomSheet extends StatelessWidget {
  const _FilterBottomSheet();

  @override
  Widget build(BuildContext context) {
    return Consumer<ProductProvider>(
      builder: (context, provider, _) {
        return Container(
          padding: const EdgeInsets.all(16),
          height: 350,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Filter Products",
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 20),
              Expanded(
                child: _buildCategoriesList(provider),
              ),
              const SizedBox(height: 10),
              _buildApplyButton(context),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategoriesList(ProductProvider provider) {
    if (provider.categories.isEmpty) {
      return const Center(child: Text("No categories available"));
    }

    return ListView.builder(
      itemCount: provider.categories.length,
      itemBuilder: (context, index) {
        final category = provider.categories[index];
        final isSelected =
            provider.selectedFilterCategories.contains(category.name);

        return ListTile(
          title: Text(category.name),
          trailing: Checkbox(
            value: isSelected,
            onChanged: (_) => provider.toggleFilterCategory(category.name),
          ),
          onTap: () => provider.toggleFilterCategory(category.name),
        );
      },
    );
  }

  Widget _buildApplyButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => Navigator.pop(context),
        child: const Text("Apply Filter"),
      ),
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
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Set Offer Prices",
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 15),
          _buildTextField(
            controller: _offerPriceController,
            label: "Offer Price",
          ),
          const SizedBox(height: 15),
          _buildTextField(
            controller: _hypermarketPriceController,
            label: "Hypermarket Offer Price",
          ),
          const SizedBox(height: 20),
          _buildSaveButton(context),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
  }) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildSaveButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => _savePrices(context),
        child: const Text("Save"),
      ),
    );
  }

  void _savePrices(BuildContext context) {
    final offerPrice = double.tryParse(_offerPriceController.text);
    final hyperPrice = double.tryParse(_hypermarketPriceController.text);

    if (offerPrice == null && hyperPrice == null) {
      return;
    }

    final provider = context.read<ProductProvider>();
    
    if (offerPrice != null) {
      provider.setOfferPrice(widget.product, offerPrice);
    }
    
    if (hyperPrice != null) {
      provider.setHyperMarketPrice(widget.product, hyperPrice);
    }

    Navigator.pop(context);
  }
}

// ==================== PRODUCT OPTIONS BOTTOM SHEET ====================
class _ProductOptionsBottomSheet extends StatelessWidget {
  final Product product;

  const _ProductOptionsBottomSheet({required this.product});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildEditOption(context),
          _buildDeleteOption(context),
          _buildVisibilityOption(context),
        ],
      ),
    );
  }

  Widget _buildEditOption(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.edit, color: Colors.blue),
      title: const Text("Edit"),
      onTap: () {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EditProducts(product: product),
          ),
        );
      },
    );
  }

  Widget _buildDeleteOption(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.delete, color: Colors.red),
      title: const Text("Delete"),
      onTap: () {
        Navigator.pop(context);
        context.read<ProductProvider>().deleteProduct(product.id);
      },
    );
  }

  Widget _buildVisibilityOption(BuildContext context) {
    return ListTile(
      leading: Icon(
        product.isHidden ? Icons.visibility_off : Icons.remove_red_eye,
        color: product.isHidden ? Colors.red : Colors.grey,
      ),
      title: Text(product.isHidden ? "Unhide" : "Hide"),
      onTap: () => _toggleVisibility(context),
    );
  }

  Future<void> _toggleVisibility(BuildContext context) async {
    Navigator.pop(context);
    
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
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: PageView.builder(
        controller: PageController(initialPage: initialIndex),
        itemCount: images.length,
        itemBuilder: (context, index) {
          return InteractiveViewer(
            clipBehavior: Clip.none,
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