import 'package:flutter/material.dart';
import 'package:products_catelogs/features/products/data/repositories/products_repository.dart';

class CategoriesManagementView extends StatefulWidget {
  final List<ProductCategoryRecord> categories;
  final Future<void> Function(String name) onCreateCategory;
  final Future<void> Function({
    required String categoryId,
    required String newName,
  })
  onRenameCategory;
  final Future<void> Function(String categoryId) onDeleteCategory;
  final VoidCallback onBack;

  const CategoriesManagementView({
    super.key,
    required this.categories,
    required this.onCreateCategory,
    required this.onRenameCategory,
    required this.onDeleteCategory,
    required this.onBack,
  });

  @override
  State<CategoriesManagementView> createState() =>
      _CategoriesManagementViewState();
}

class _CategoriesManagementViewState extends State<CategoriesManagementView> {
  final TextEditingController _newCategoryController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  String _query = '';
  bool _busy = false;

  @override
  void dispose() {
    _newCategoryController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<ProductCategoryRecord> get _filteredCategories {
    if (_query.isEmpty) return widget.categories;
    return widget.categories
        .where((category) => category.name.toLowerCase().contains(_query))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredCategories;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 900;

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(isNarrow),
              const SizedBox(height: 12),
              _buildAddCard(isNarrow),
              const SizedBox(height: 12),
              _buildListCard(filtered),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(bool isNarrow) {
    return Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Category Management',
                style: TextStyle(
                  fontSize: 30,
                  height: 1.1,
                  color: Color(0xFF111827),
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Create and maintain backend categories for products.',
                style: TextStyle(
                  color: Color(0xFF8A94A6),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        if (!isNarrow)
          OutlinedButton.icon(
            onPressed: _busy ? null : widget.onBack,
            icon: const Icon(Icons.arrow_back_rounded),
            label: const Text('Back to Products'),
          ),
      ],
    );
  }

  Widget _buildAddCard(bool isNarrow) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: isNarrow
          ? Column(
              children: [
                TextField(
                  controller: _newCategoryController,
                  decoration: const InputDecoration(
                    labelText: 'Category Name',
                    hintText: 'Enter category',
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _busy ? null : _addCategory,
                    icon: const Icon(Icons.add_rounded),
                    label: Text(_busy ? 'Processing...' : 'Add Category'),
                  ),
                ),
              ],
            )
          : Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _newCategoryController,
                    decoration: const InputDecoration(
                      labelText: 'Category Name',
                      hintText: 'Enter category',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                FilledButton.icon(
                  onPressed: _busy ? null : _addCategory,
                  icon: const Icon(Icons.add_rounded),
                  label: Text(_busy ? 'Processing...' : 'Add Category'),
                ),
              ],
            ),
    );
  }

  Widget _buildListCard(List<ProductCategoryRecord> filtered) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _searchController,
            onChanged: (value) {
              setState(() => _query = value.trim().toLowerCase());
            },
            decoration: const InputDecoration(
              hintText: 'Search categories',
              prefixIcon: Icon(Icons.search_rounded),
            ),
          ),
          const SizedBox(height: 10),
          if (filtered.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFCFCFD),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE7ECF3)),
              ),
              child: const Text(
                'No backend categories found.',
                style: TextStyle(
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          if (filtered.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE4E8F0)),
              ),
              child: const Row(
                children: [
                  Expanded(
                    child: Text(
                      'Category Name',
                      style: TextStyle(
                        color: Color(0xFF4B5565),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  SizedBox(width: 80, child: Text('Action')),
                ],
              ),
            ),
            const SizedBox(height: 8),
            for (int i = 0; i < filtered.length; i++) ...[
              _categoryRow(filtered[i]),
              if (i != filtered.length - 1) const SizedBox(height: 8),
            ],
          ],
        ],
      ),
    );
  }

  Widget _categoryRow(ProductCategoryRecord category) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFCFCFD),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE7ECF3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              category.name,
              style: const TextStyle(
                color: Color(0xFF111827),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            onPressed: _busy ? null : () => _renameCategory(category),
            icon: const Icon(
              Icons.edit_outlined,
              size: 18,
              color: Color(0xFF374151),
            ),
          ),
          IconButton(
            onPressed: _busy ? null : () => _deleteCategory(category),
            icon: const Icon(
              Icons.delete_outline_rounded,
              size: 18,
              color: Color(0xFFE65A5A),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addCategory() async {
    final value = _newCategoryController.text.trim();
    if (value.isEmpty) return;

    setState(() => _busy = true);
    try {
      await widget.onCreateCategory(value);
      if (!mounted) return;
      _newCategoryController.clear();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Category added.')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to add category: $error')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _renameCategory(ProductCategoryRecord category) async {
    final controller = TextEditingController(text: category.name);
    final updated = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Rename Category'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Category Name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(context).pop(controller.text.trim()),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (updated == null || updated.isEmpty) return;

    setState(() => _busy = true);
    try {
      await widget.onRenameCategory(categoryId: category.id, newName: updated);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Category updated.')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to rename category: $error')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _deleteCategory(ProductCategoryRecord category) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Category'),
          content: Text('Delete "${category.name}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) return;

    setState(() => _busy = true);
    try {
      await widget.onDeleteCategory(category.id);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Category deleted.')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete category: $error')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
