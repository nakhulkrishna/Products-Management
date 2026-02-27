import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class ProductFormResult {
  final String name;
  final String code;
  final String description;
  final String category;
  final String baseUnit;
  final List<SaleUnitConfig> saleUnits;
  final Map<String, List<MarketUnitPrice>> marketPricingByMarket;
  final double displayPriceQar;
  final double? displayOfferPriceQar;
  final double initialStockInput;
  final String? initialStockInputUnit;
  final double initialStockInBaseUnit;
  final List<String> existingImageUrls;
  final List<ProductDraftImage> newImages;

  const ProductFormResult({
    required this.name,
    required this.code,
    required this.description,
    required this.category,
    required this.baseUnit,
    required this.saleUnits,
    required this.marketPricingByMarket,
    required this.displayPriceQar,
    required this.displayOfferPriceQar,
    required this.initialStockInput,
    required this.initialStockInputUnit,
    required this.initialStockInBaseUnit,
    required this.existingImageUrls,
    required this.newImages,
  });
}

class ProductFormInitialData {
  final String name;
  final String code;
  final String description;
  final String category;
  final String baseUnit;
  final List<SaleUnitConfig> saleUnits;
  final Map<String, List<MarketUnitPrice>> marketPricingByMarket;
  final double initialStockInput;
  final String? initialStockInputUnit;
  final List<String> imageUrls;

  const ProductFormInitialData({
    required this.name,
    required this.code,
    required this.description,
    required this.category,
    required this.baseUnit,
    required this.saleUnits,
    required this.marketPricingByMarket,
    required this.initialStockInput,
    required this.initialStockInputUnit,
    required this.imageUrls,
  });
}

class SaleUnitConfig {
  final String unit;
  final double conversionToBaseUnit;

  const SaleUnitConfig({
    required this.unit,
    required this.conversionToBaseUnit,
  });
}

class MarketUnitPrice {
  final String unit;
  final bool overrideEnabled;
  final double? manualPrice;
  final double? manualOfferPrice;
  final double? autoPrice;
  final double? autoOfferPrice;

  const MarketUnitPrice({
    required this.unit,
    required this.overrideEnabled,
    required this.manualPrice,
    required this.manualOfferPrice,
    required this.autoPrice,
    required this.autoOfferPrice,
  });
}

class AddEditProductFormView extends StatefulWidget {
  final Set<String> existingNormalizedCodes;
  final List<String> categories;
  final Future<void> Function(ProductFormResult) onSave;
  final VoidCallback onCancel;
  final bool isEdit;
  final String? initialNormalizedCode;
  final ProductFormInitialData? initialData;

  const AddEditProductFormView({
    super.key,
    required this.existingNormalizedCodes,
    required this.categories,
    required this.onSave,
    required this.onCancel,
    this.isEdit = false,
    this.initialNormalizedCode,
    this.initialData,
  });

  @override
  State<AddEditProductFormView> createState() => _AddEditProductFormViewState();
}

class _AddEditProductFormViewState extends State<AddEditProductFormView> {
  static const _unitOptions = <String>[
    'Gram',
    'KG',
    'Piece',
    'CTN',
    'Liter',
    'Box',
  ];

  static const _markets = <String>['Hyper Market', 'Local Market'];

  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _stockController = TextEditingController();

  String? _selectedCategory;
  String? _baseUnit;
  String _selectedMarket = _markets.first;
  String? _stockUnit;
  bool _isSubmitting = false;

  final List<_SaleUnitRow> _saleUnits = <_SaleUnitRow>[];
  final List<ProductDraftImage> _images = <ProductDraftImage>[];
  final List<String> _existingImageUrls = <String>[];
  final Map<String, Map<String, _PriceOverride>> _pricingByMarket =
      <String, Map<String, _PriceOverride>>{
        _markets.first: <String, _PriceOverride>{},
        _markets.last: <String, _PriceOverride>{},
      };

  @override
  void initState() {
    super.initState();
    _hydrateFromInitial();
    _ensurePricingRows();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _descriptionController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  List<String> get _allUnits {
    if (_baseUnit == null || _baseUnit!.isEmpty) return const [];
    final seen = <String>{};
    final units = <String>[];
    if (seen.add(_baseUnit!)) {
      units.add(_baseUnit!);
    }
    for (final row in _saleUnits) {
      final unit = row.unit.trim();
      if (unit.isEmpty) continue;
      if (seen.add(unit)) {
        units.add(unit);
      }
    }
    return units;
  }

  void _hydrateFromInitial() {
    final initial = widget.initialData;
    if (initial == null) return;

    _nameController.text = initial.name;
    _codeController.text = initial.code;
    _descriptionController.text = initial.description;
    _selectedCategory = initial.category;
    _baseUnit = initial.baseUnit;
    _stockController.text = initial.initialStockInput == 0
        ? ''
        : initial.initialStockInput.toStringAsFixed(2);
    _stockUnit = initial.initialStockInputUnit ?? initial.baseUnit;
    _existingImageUrls
      ..clear()
      ..addAll(initial.imageUrls);

    _saleUnits
      ..clear()
      ..addAll(
        initial.saleUnits
            .where((u) => u.unit != initial.baseUnit)
            .map(
              (u) => _SaleUnitRow(
                unit: u.unit,
                conversion: u.conversionToBaseUnit.toStringAsFixed(2),
              ),
            ),
      );

    _pricingByMarket
      ..clear()
      ..addAll({
        for (final entry in initial.marketPricingByMarket.entries)
          entry.key: {
            for (final row in entry.value)
              row.unit: _PriceOverride(
                overrideEnabled: row.overrideEnabled,
                price: row.manualPrice?.toStringAsFixed(2) ?? '',
                offerPrice: row.manualOfferPrice?.toStringAsFixed(2) ?? '',
              ),
          },
      });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 900;

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _headerRow(isNarrow),
              const SizedBox(height: 12),
              _sectionCard(
                title: 'Basic Information',
                subtitle: 'Add core product details before unit pricing setup.',
                child: Column(
                  children: [
                    isNarrow
                        ? Column(
                            children: [
                              _textField(
                                label: 'Product Name',
                                controller: _nameController,
                                hint: 'Enter product name',
                              ),
                              const SizedBox(height: 10),
                              _textField(
                                label: 'Product Code',
                                controller: _codeController,
                                hint: 'Unique code',
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              Expanded(
                                child: _textField(
                                  label: 'Product Name',
                                  controller: _nameController,
                                  hint: 'Enter product name',
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _textField(
                                  label: 'Product Code',
                                  controller: _codeController,
                                  hint: 'Unique code',
                                ),
                              ),
                            ],
                          ),
                    const SizedBox(height: 10),
                    _textField(
                      label: 'Product Description',
                      controller: _descriptionController,
                      hint: 'Add product details',
                      maxLines: 4,
                    ),
                    const SizedBox(height: 10),
                    isNarrow
                        ? Column(
                            children: [
                              _dropdownField<String>(
                                label: 'Category',
                                value: _selectedCategory,
                                hint: 'Select category',
                                items: widget.categories,
                                onChanged: (value) {
                                  setState(() => _selectedCategory = value);
                                },
                              ),
                              const SizedBox(height: 10),
                              _dropdownField<String>(
                                label: 'Base Unit',
                                value: _baseUnit,
                                hint: 'Select base unit',
                                items: _unitOptions,
                                onChanged: (value) {
                                  setState(() {
                                    _baseUnit = value;
                                    _saleUnits.removeWhere(
                                      (u) => u.unit == value,
                                    );
                                    _stockUnit =
                                        _stockUnit == null ||
                                            _allUnits.contains(_stockUnit)
                                        ? _stockUnit
                                        : value;
                                    _stockUnit ??= value;
                                    _ensurePricingRows();
                                  });
                                },
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              Expanded(
                                child: _dropdownField<String>(
                                  label: 'Category',
                                  value: _selectedCategory,
                                  hint: 'Select category',
                                  items: widget.categories,
                                  onChanged: (value) {
                                    setState(() => _selectedCategory = value);
                                  },
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _dropdownField<String>(
                                  label: 'Base Unit',
                                  value: _baseUnit,
                                  hint: 'Select base unit',
                                  items: _unitOptions,
                                  onChanged: (value) {
                                    setState(() {
                                      _baseUnit = value;
                                      _saleUnits.removeWhere(
                                        (u) => u.unit == value,
                                      );
                                      _stockUnit =
                                          _stockUnit == null ||
                                              _allUnits.contains(_stockUnit)
                                          ? _stockUnit
                                          : value;
                                      _stockUnit ??= value;
                                      _ensurePricingRows();
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                    const SizedBox(height: 10),
                    _buildImageUploader(),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _sectionCard(
                title: 'Sale Units',
                subtitle:
                    'Define sellable units and conversion to the selected base unit.',
                trailing: TextButton.icon(
                  onPressed: _baseUnit == null
                      ? null
                      : () {
                          setState(() {
                            _saleUnits.add(
                              _SaleUnitRow(unit: '', conversion: ''),
                            );
                          });
                        },
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add Unit'),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE4E8F0)),
                      ),
                      child: Row(
                        children: [
                          const Expanded(
                            flex: 3,
                            child: Text(
                              'Base Unit',
                              style: TextStyle(
                                color: Color(0xFF6B7280),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text(
                              _baseUnit ?? 'Not selected',
                              style: const TextStyle(
                                color: Color(0xFF111827),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const Expanded(
                            flex: 3,
                            child: Text(
                              'Conversion: 1',
                              style: TextStyle(
                                color: Color(0xFF111827),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 40),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_saleUnits.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFCFCFD),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE7ECF3)),
                        ),
                        child: Text(
                          _baseUnit == null
                              ? 'Select a base unit first, then add sale units.'
                              : 'No sale units added yet.',
                          style: const TextStyle(
                            color: Color(0xFF6B7280),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    for (int i = 0; i < _saleUnits.length; i++) ...[
                      _unitRow(i, _saleUnits[i]),
                      if (i != _saleUnits.length - 1) const SizedBox(height: 8),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _sectionCard(
                title: 'Market Pricing',
                subtitle:
                    'Set manual override pricing per market or use auto-calculated values.',
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _dropdownField<String>(
                            label: 'Market',
                            value: _selectedMarket,
                            hint: 'Select market',
                            items: _markets,
                            onChanged: (value) {
                              if (value == null) return;
                              setState(() => _selectedMarket = value);
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        OutlinedButton.icon(
                          onPressed: _copyHyperToLocal,
                          icon: const Icon(Icons.copy_rounded, size: 16),
                          label: const Text('Copy Hyper -> Local'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_allUnits.isEmpty)
                      _readonlyHint(
                        'Select base unit and sale units to configure pricing.',
                      )
                    else
                      _buildPricingTable(),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _sectionCard(
                title: 'Inventory (Optional)',
                subtitle:
                    'Enter initial stock in any unit. System stores it in base unit.',
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _textField(
                            label: 'Initial Stock',
                            controller: _stockController,
                            hint: '0',
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _dropdownField<String>(
                            label: 'Stock Unit',
                            value: _stockUnit,
                            hint: 'Select unit',
                            items: _allUnits,
                            onChanged: (value) {
                              setState(() => _stockUnit = value);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE4E8F0)),
                      ),
                      child: Text(
                        'Stored in base unit: ${_baseUnit ?? '-'} ${_computedStockInBase().toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Color(0xFF374151),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  FilledButton.icon(
                    onPressed: _isSubmitting ? null : _onSave,
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_rounded),
                    label: Text(
                      _isSubmitting
                          ? 'Saving...'
                          : (widget.isEdit ? 'Save Changes' : 'Save Product'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: _isSubmitting ? null : widget.onCancel,
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _headerRow(bool isNarrow) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.isEdit ? 'Edit Product' : 'Add Product',
                style: const TextStyle(
                  fontSize: 30,
                  height: 1.1,
                  color: Color(0xFF111827),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Configure units, market pricing, inventory, and validation rules.',
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
            onPressed: _isSubmitting ? null : widget.onCancel,
            icon: const Icon(Icons.arrow_back_rounded),
            label: const Text('Back to Product List'),
          ),
      ],
    );
  }

  Widget _buildImageUploader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Images',
                style: TextStyle(
                  color: Color(0xFF111827),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: _pickImages,
              icon: const Icon(Icons.upload_rounded),
              label: const Text('Upload Images'),
            ),
          ],
        ),
        if (_images.isEmpty && _existingImageUrls.isEmpty)
          _readonlyHint('No images uploaded yet.'),
        if (_existingImageUrls.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (int i = 0; i < _existingImageUrls.length; i++)
                _existingImagePreview(i, _existingImageUrls[i]),
            ],
          ),
        if (_existingImageUrls.isNotEmpty && _images.isNotEmpty)
          const SizedBox(height: 8),
        if (_images.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (int i = 0; i < _images.length; i++)
                _imagePreview(i, _images[i]),
            ],
          ),
      ],
    );
  }

  Widget _imagePreview(int index, ProductDraftImage image) {
    return Stack(
      children: [
        Container(
          width: 112,
          height: 112,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE5EAF1)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Image.memory(
            image.bytes,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => const ColoredBox(
              color: Color(0xFFF3F4F6),
              child: Center(child: Icon(Icons.image_not_supported_rounded)),
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: InkWell(
            onTap: () {
              setState(() => _images.removeAt(index));
            },
            child: Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: Color(0xAA111827),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close_rounded,
                size: 14,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _existingImagePreview(int index, String imageUrl) {
    return Stack(
      children: [
        Container(
          width: 112,
          height: 112,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE5EAF1)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Image.network(
            imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => const ColoredBox(
              color: Color(0xFFF3F4F6),
              child: Center(child: Icon(Icons.image_not_supported_rounded)),
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: InkWell(
            onTap: () {
              setState(() => _existingImageUrls.removeAt(index));
            },
            child: Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: Color(0xAA111827),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close_rounded,
                size: 14,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _unitRow(int index, _SaleUnitRow row) {
    final options = _availableUnitsForRow(index);
    final safeUnitValue = options.contains(row.unit) ? row.unit : null;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFFCFCFD),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE4E8F0)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: DropdownButtonFormField<String>(
              initialValue: row.unit.isEmpty ? null : safeUnitValue,
              decoration: const InputDecoration(labelText: 'Unit'),
              items: options
                  .map(
                    (unit) => DropdownMenuItem<String>(
                      value: unit,
                      child: Text(unit),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() {
                  row.unit = value ?? '';
                  _ensurePricingRows();
                });
              },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 4,
            child: TextFormField(
              initialValue: row.conversion,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Conversion to Base Unit',
                hintText: 'ex: 1000',
              ),
              onChanged: (value) {
                row.conversion = value;
              },
              onEditingComplete: () => setState(() {}),
              onTapOutside: (_) => setState(() {}),
            ),
          ),
          const SizedBox(width: 10),
          IconButton(
            onPressed: () {
              setState(() {
                _saleUnits.removeAt(index);
                _ensurePricingRows();
              });
            },
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: Color(0xFFE65A5A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingTable() {
    _ensurePricingRows();
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE4E8F0)),
          ),
          child: const Row(
            children: [
              Expanded(flex: 3, child: Text('Unit', style: _tableHeaderStyle)),
              Expanded(flex: 4, child: Text('Price', style: _tableHeaderStyle)),
              Expanded(
                flex: 4,
                child: Text('Offer Price', style: _tableHeaderStyle),
              ),
              Expanded(
                flex: 3,
                child: Text('Override', style: _tableHeaderStyle),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        for (final unit in _allUnits) ...[
          _priceRow(unit),
          if (unit != _allUnits.last) const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _priceRow(String unit) {
    final pricing = _pricingByMarket[_selectedMarket]!;
    final config = pricing[unit]!;
    final autoPrice = _autoPriceFor(_selectedMarket, unit);
    final autoOffer = _autoOfferFor(_selectedMarket, unit);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE4E8F0)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              unit,
              style: const TextStyle(
                color: Color(0xFF111827),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: config.overrideEnabled
                ? TextFormField(
                    initialValue: config.price,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: 'Price',
                      isDense: true,
                    ),
                    onChanged: (value) {
                      config.price = value;
                    },
                    onEditingComplete: () => setState(() {}),
                    onTapOutside: (_) => setState(() {}),
                  )
                : _readonlyAutoValue(autoPrice),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 4,
            child: config.overrideEnabled
                ? TextFormField(
                    initialValue: config.offerPrice,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: 'Offer Price',
                      isDense: true,
                    ),
                    onChanged: (value) {
                      config.offerPrice = value;
                    },
                    onEditingComplete: () => setState(() {}),
                    onTapOutside: (_) => setState(() {}),
                  )
                : _readonlyAutoValue(autoOffer),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Switch(
                  value: config.overrideEnabled,
                  onChanged: (value) {
                    setState(() {
                      config.overrideEnabled = value;
                    });
                  },
                ),
                const SizedBox(width: 4),
                Text(
                  config.overrideEnabled ? 'Manual' : 'Auto',
                  style: TextStyle(
                    color: config.overrideEnabled
                        ? const Color(0xFF1F8A70)
                        : const Color(0xFF6B7280),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _readonlyAutoValue(double? value) {
    return Container(
      height: 44,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6F9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5EAF1)),
      ),
      child: Text(
        value == null ? 'Auto' : 'QAR ${value.toStringAsFixed(2)}',
        style: const TextStyle(
          color: Color(0xFF6B7280),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required String subtitle,
    required Widget child,
    Widget? trailing,
  }) {
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
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xFF111827),
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF8A94A6),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _textField({
    required String label,
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(labelText: label, hintText: hint),
      onChanged: (_) => setState(() {}),
    );
  }

  Widget _dropdownField<T>({
    required String label,
    required T? value,
    required String hint,
    required List<T> items,
    required ValueChanged<T?> onChanged,
  }) {
    final uniqueItems = <T>[];
    final seen = <T>{};
    for (final item in items) {
      if (seen.add(item)) {
        uniqueItems.add(item);
      }
    }
    final T? safeValue = value != null && uniqueItems.contains(value)
        ? value
        : null;

    return DropdownButtonFormField<T>(
      initialValue: safeValue,
      decoration: InputDecoration(labelText: label),
      hint: Text(hint),
      items: uniqueItems
          .map(
            (item) =>
                DropdownMenuItem<T>(value: item, child: Text(item.toString())),
          )
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _readonlyHint(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFCFCFD),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE7ECF3)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF6B7280),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  List<String> _availableUnitsForRow(int rowIndex) {
    final selectedByOthers = <String>{};
    for (int i = 0; i < _saleUnits.length; i++) {
      if (i != rowIndex && _saleUnits[i].unit.isNotEmpty) {
        selectedByOthers.add(_saleUnits[i].unit);
      }
    }
    return _unitOptions
        .where((unit) => unit != _baseUnit && !selectedByOthers.contains(unit))
        .toList();
  }

  Future<void> _pickImages() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      withData: true,
      type: FileType.image,
    );
    if (result == null) return;

    setState(() {
      for (final file in result.files) {
        if (file.bytes == null) continue;
        _images.add(ProductDraftImage(name: file.name, bytes: file.bytes!));
      }
    });
  }

  void _ensurePricingRows() {
    final units = _allUnits.toSet();
    for (final market in _markets) {
      final marketRows = _pricingByMarket[market]!;
      marketRows.removeWhere((unit, _) => !units.contains(unit));
      for (final unit in units) {
        marketRows.putIfAbsent(unit, () => _PriceOverride.empty());
      }
    }
  }

  void _copyHyperToLocal() {
    _ensurePricingRows();
    final hyper = _pricingByMarket[_markets.first]!;
    final local = _pricingByMarket[_markets.last]!;
    setState(() {
      for (final unit in _allUnits) {
        final source = hyper[unit]!;
        local[unit] = source.copy();
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied Hyper Market prices to Local Market'),
      ),
    );
  }

  double _conversionForUnit(String unit) {
    if (_baseUnit == null) return 1;
    if (unit == _baseUnit) return 1;
    final row = _saleUnits.where((r) => r.unit == unit).firstOrNull;
    if (row == null) return 1;
    final value = double.tryParse(row.conversion.trim());
    return value == null || value <= 0 ? 1 : value;
  }

  double? _autoPriceFor(String market, String unit) {
    final base = _baseUnit;
    if (base == null) return null;
    if (unit == base) return null;
    final baseConfig = _pricingByMarket[market]![base];
    if (baseConfig == null || !baseConfig.overrideEnabled) return null;
    final basePrice = double.tryParse(baseConfig.price.trim());
    if (basePrice == null || basePrice <= 0) return null;
    return basePrice * _conversionForUnit(unit);
  }

  double? _autoOfferFor(String market, String unit) {
    final base = _baseUnit;
    if (base == null) return null;
    if (unit == base) return null;
    final baseConfig = _pricingByMarket[market]![base];
    if (baseConfig == null || !baseConfig.overrideEnabled) return null;
    final baseOffer = double.tryParse(baseConfig.offerPrice.trim());
    if (baseOffer == null || baseOffer <= 0) return null;
    return baseOffer * _conversionForUnit(unit);
  }

  double _computedStockInBase() {
    final stock = double.tryParse(_stockController.text.trim()) ?? 0;
    final unit = _stockUnit ?? _baseUnit;
    if (unit == null) return 0;
    return stock * _conversionForUnit(unit);
  }

  String _normalizeCode(String input) {
    return input.replaceAll('#', '').trim().toLowerCase();
  }

  Future<void> _onSave() async {
    if (_isSubmitting) return;
    _ensurePricingRows();
    final errors = <String>[];

    final name = _nameController.text.trim();
    final rawCode = _codeController.text.trim();
    final normalizedCode = _normalizeCode(rawCode);
    final category = _selectedCategory;
    final baseUnit = _baseUnit;

    if (name.isEmpty) errors.add('Product name is required.');
    if (rawCode.isEmpty) errors.add('Product code is required.');
    if (category == null || category.isEmpty) {
      errors.add('Category is required.');
    }
    if (baseUnit == null || baseUnit.isEmpty) {
      errors.add('Base unit is required.');
    }

    if (normalizedCode.isNotEmpty &&
        normalizedCode != widget.initialNormalizedCode &&
        widget.existingNormalizedCodes.contains(normalizedCode)) {
      errors.add('Product code must be unique.');
    }

    if (_saleUnits.isEmpty) {
      errors.add('At least one sale unit is required.');
    }

    final seen = <String>{};
    for (final row in _saleUnits) {
      if (row.unit.isEmpty) {
        errors.add('Every sale unit row must have a selected unit.');
        continue;
      }
      if (!seen.add(row.unit)) {
        errors.add('Same unit cannot be added twice.');
      }
      final conversion = double.tryParse(row.conversion.trim());
      if (conversion == null || conversion <= 0) {
        errors.add('Conversion must be greater than 0 for ${row.unit}.');
      }
    }

    if (baseUnit != null) {
      for (final market in _markets) {
        final rows = _pricingByMarket[market]!;
        var hasManual = false;
        for (final unit in _allUnits) {
          final config = rows[unit];
          final price = config == null
              ? null
              : double.tryParse(config.price.trim());
          if (config != null &&
              config.overrideEnabled &&
              price != null &&
              price > 0) {
            hasManual = true;
            break;
          }
        }
        if (!hasManual) {
          errors.add('At least one manual price is required in $market.');
        }
      }
    }

    if (errors.isNotEmpty) {
      _showValidationSideSheet(errors);
      return;
    }

    final normalizedId = rawCode.startsWith('#') ? rawCode : '#$rawCode';
    final hyperRows = _pricingByMarket[_markets.first]!;
    final baseConfig = hyperRows[baseUnit!]!;
    final manualBasePrice = double.tryParse(baseConfig.price.trim());
    final manualBaseOffer = double.tryParse(baseConfig.offerPrice.trim());
    final displayPrice = manualBasePrice ?? 0;

    final saleUnitConfigs = <SaleUnitConfig>[];
    for (final unit in _allUnits) {
      saleUnitConfigs.add(
        SaleUnitConfig(
          unit: unit,
          conversionToBaseUnit: _conversionForUnit(unit),
        ),
      );
    }

    final marketPricingByMarket = <String, List<MarketUnitPrice>>{};
    for (final market in _markets) {
      final rows = _pricingByMarket[market]!;
      final list = <MarketUnitPrice>[];
      for (final unit in _allUnits) {
        final config = rows[unit] ?? _PriceOverride.empty();
        list.add(
          MarketUnitPrice(
            unit: unit,
            overrideEnabled: config.overrideEnabled,
            manualPrice: double.tryParse(config.price.trim()),
            manualOfferPrice: double.tryParse(config.offerPrice.trim()),
            autoPrice: _autoPriceFor(market, unit),
            autoOfferPrice: _autoOfferFor(market, unit),
          ),
        );
      }
      marketPricingByMarket[market] = list;
    }

    final initialStockInput =
        double.tryParse(_stockController.text.trim()) ?? 0;

    final payload = ProductFormResult(
      name: name,
      code: normalizedId,
      description: _descriptionController.text.trim(),
      category: category!,
      baseUnit: baseUnit,
      saleUnits: saleUnitConfigs,
      marketPricingByMarket: marketPricingByMarket,
      displayPriceQar: displayPrice,
      displayOfferPriceQar: manualBaseOffer,
      initialStockInput: initialStockInput,
      initialStockInputUnit: _stockUnit,
      initialStockInBaseUnit: _computedStockInBase(),
      existingImageUrls: List<String>.from(_existingImageUrls),
      newImages: List<ProductDraftImage>.from(_images),
    );

    setState(() => _isSubmitting = true);
    try {
      await widget.onSave(payload);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save product: $error')));
      setState(() => _isSubmitting = false);
    }
  }

  Future<void> _showValidationSideSheet(List<String> errors) async {
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Validation Required',
      barrierColor: const Color(0x400F172A),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (context, _, __) {
        final width = MediaQuery.of(context).size.width;
        final sheetWidth = width > 1080 ? 520.0 : (width > 720 ? 460.0 : width);
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
                          const Expanded(
                            child: Text(
                              'Validation Required',
                              style: TextStyle(
                                color: Color(0xFF111827),
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.close_rounded, size: 20),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.all(18),
                        children: [
                          for (final e in errors.take(8))
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Text('• $e'),
                            ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                      child: SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('OK'),
                        ),
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
        final curved = CurvedAnimation(parent: animation, curve: Curves.easeOut);
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

class _SaleUnitRow {
  String unit;
  String conversion;

  _SaleUnitRow({required this.unit, required this.conversion});
}

class _PriceOverride {
  bool overrideEnabled;
  String price;
  String offerPrice;

  _PriceOverride({
    required this.overrideEnabled,
    required this.price,
    required this.offerPrice,
  });

  factory _PriceOverride.empty() {
    return _PriceOverride(overrideEnabled: false, price: '', offerPrice: '');
  }

  _PriceOverride copy() {
    return _PriceOverride(
      overrideEnabled: overrideEnabled,
      price: price,
      offerPrice: offerPrice,
    );
  }
}

class ProductDraftImage {
  final String name;
  final Uint8List bytes;

  const ProductDraftImage({required this.name, required this.bytes});
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}

const _tableHeaderStyle = TextStyle(
  color: Color(0xFF4B5565),
  fontWeight: FontWeight.w700,
  fontSize: 13,
);
