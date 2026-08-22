import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:products_catelogs/features/products/data/repositories/products_repository.dart';

class CategoriesManagementView extends StatefulWidget {
  final List<ProductCategoryRecord> categories;
  final Future<void> Function(
    String name, {
    Uint8List? imageBytes,
    String? imageFileName,
  })
  onCreateCategory;
  final Future<void> Function({
    required String categoryId,
    required String newName,
  })
  onRenameCategory;
  final Future<void> Function({
    required String categoryId,
    required Uint8List imageBytes,
    required String imageFileName,
  })
  onSetCategoryImage;
  final Future<void> Function(String categoryId) onDeleteCategory;
  final VoidCallback onBack;

  const CategoriesManagementView({
    super.key,
    required this.categories,
    required this.onCreateCategory,
    required this.onRenameCategory,
    required this.onSetCategoryImage,
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
  Uint8List? _newCategoryImageBytes;
  String? _newCategoryImageName;

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
            icon: const Icon(Iconsax.arrow_left_2),
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
                _newImagePickerButton(),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _busy ? null : _addCategory,
                    icon: const Icon(Iconsax.add),
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
                _newImagePickerButton(),
                const SizedBox(width: 10),
                FilledButton.icon(
                  onPressed: _busy ? null : _addCategory,
                  icon: const Icon(Iconsax.add),
                  label: Text(_busy ? 'Processing...' : 'Add Category'),
                ),
              ],
            ),
    );
  }

  Widget _newImagePickerButton() {
    final hasImage = _newCategoryImageBytes != null;
    return OutlinedButton.icon(
      onPressed: _busy ? null : _pickNewCategoryImage,
      icon: hasImage
          ? ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.memory(
                _newCategoryImageBytes!,
                width: 22,
                height: 22,
                fit: BoxFit.cover,
              ),
            )
          : const Icon(Iconsax.gallery_add, size: 18),
      label: Text(hasImage ? 'Change Image' : 'Add Image'),
    );
  }

  Future<void> _pickNewCategoryImage() async {
    final picked = await _pickSingleImage();
    if (picked == null) return;
    setState(() {
      _newCategoryImageBytes = picked.bytes;
      _newCategoryImageName = picked.name;
    });
  }

  Future<({Uint8List bytes, String name})?> _pickSingleImage() async {
    final result = await FilePicker.platform.pickFiles(
      withData: true,
      type: FileType.image,
    );
    final file = result?.files.firstOrNull;
    final bytes = file?.bytes;
    if (file == null || bytes == null) return null;
    return (bytes: bytes, name: file.name);
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
              prefixIcon: Icon(Iconsax.search_normal),
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
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: category.imageUrl == null
                ? Container(
                    width: 36,
                    height: 36,
                    color: const Color(0xFFF3F4F6),
                    child: const Icon(
                      Iconsax.gallery,
                      size: 18,
                      color: Color(0xFF9CA3AF),
                    ),
                  )
                : Image.network(
                    category.imageUrl!,
                    width: 36,
                    height: 36,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 36,
                      height: 36,
                      color: const Color(0xFFF3F4F6),
                      child: const Icon(
                        Iconsax.gallery_slash,
                        size: 18,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              category.name,
              style: const TextStyle(
                color: Color(0xFF111827),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          PopupMenuButton<String>(
            enabled: !_busy,
            color: Colors.white,
            surfaceTintColor: Colors.white,
            elevation: 8,
            shadowColor: const Color(0x1A0F172A),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            offset: const Offset(0, 42),
            icon: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFDDE2EA)),
              ),
              child: const Icon(
                Iconsax.more,
                size: 18,
                color: Color(0xFF4B5563),
              ),
            ),
            onSelected: (value) {
              switch (value) {
                case 'rename':
                  _renameCategory(category);
                  break;
                case 'image':
                  _changeCategoryImage(category);
                  break;
                case 'delete':
                  _deleteCategory(category);
                  break;
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'rename',
                child: Row(
                  children: [
                    Icon(Iconsax.edit, size: 18, color: Color(0xFF374151)),
                    SizedBox(width: 10),
                    Text('Rename'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'image',
                child: Row(
                  children: [
                    Icon(
                      Iconsax.gallery_edit,
                      size: 18,
                      color: Color(0xFF2277B8),
                    ),
                    SizedBox(width: 10),
                    Text('Change Image'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
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
        ],
      ),
    );
  }

  Future<void> _addCategory() async {
    final value = _newCategoryController.text.trim();
    if (value.isEmpty) return;

    setState(() => _busy = true);
    try {
      await widget.onCreateCategory(
        value,
        imageBytes: _newCategoryImageBytes,
        imageFileName: _newCategoryImageName,
      );
      if (!mounted) return;
      _newCategoryController.clear();
      setState(() {
        _newCategoryImageBytes = null;
        _newCategoryImageName = null;
      });
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
    final updated = await _showRightSheet<String>(
      title: 'Rename Category',
      icon: Iconsax.edit,
      body: StatefulBuilder(
        builder: (context, setSheetState) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5EAF1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Current Name',
                    style: TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    category.name,
                    style: const TextStyle(
                      color: Color(0xFF111827),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              onChanged: (_) => setSheetState(() {}),
              decoration: const InputDecoration(
                labelText: 'New Category Name',
                hintText: 'Enter updated category name',
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Iconsax.info_circle,
                  size: 15,
                  color: Color(0xFF6B7280),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Keep names short and unique. ${controller.text.trim().length}/40',
                    style: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: () => Navigator.of(context).pop(controller.text.trim()),
          icon: const Icon(Iconsax.tick_circle, size: 16),
          label: const Text('Save'),
        ),
      ],
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

  Future<void> _changeCategoryImage(ProductCategoryRecord category) async {
    final picked = await _pickSingleImage();
    if (picked == null) return;

    setState(() => _busy = true);
    try {
      await widget.onSetCategoryImage(
        categoryId: category.id,
        imageBytes: picked.bytes,
        imageFileName: picked.name,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Category image updated.')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update category image: $error')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _deleteCategory(ProductCategoryRecord category) async {
    final shouldDelete = await _showRightSheet<bool>(
      title: 'Delete Category',
      icon: Iconsax.trash,
      iconColor: const Color(0xFFE65A5A),
      body: Text(
        'Delete "${category.name}"?\n\nThis action cannot be undone.',
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFE65A5A),
          ),
          onPressed: () => Navigator.of(context).pop(true),
          icon: const Icon(Iconsax.trash, size: 16),
          label: const Text('Delete'),
        ),
      ],
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

  Future<T?> _showRightSheet<T>({
    required String title,
    required IconData icon,
    required Widget body,
    required List<Widget> actions,
    Color iconColor = const Color(0xFF111827),
  }) {
    return showGeneralDialog<T>(
      context: context,
      barrierLabel: title,
      barrierDismissible: true,
      barrierColor: const Color(0x99000000),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Align(
          alignment: Alignment.centerRight,
          child: Material(
            color: Colors.white,
            borderRadius: const BorderRadius.horizontal(
              left: Radius.circular(18),
            ),
            child: SizedBox(
              width: MediaQuery.of(context).size.width > 620
                  ? 520
                  : MediaQuery.of(context).size.width * 0.92,
              height: double.infinity,
              child: SafeArea(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 14, 10, 12),
                      child: Row(
                        children: [
                          Icon(icon, size: 20, color: iconColor),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF111827),
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Iconsax.close_circle),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: Color(0xFFE5E8EE)),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                        child: body,
                      ),
                    ),
                    const Divider(height: 1, color: Color(0xFFE5E8EE)),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: actions,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
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
}
