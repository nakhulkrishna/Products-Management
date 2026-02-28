import 'dart:typed_data';
import 'dart:async';

import 'package:archive/archive.dart';
import 'package:excel/excel.dart' as xls;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:products_catelogs/features/products/application/bulk_upload_background_service.dart';
import 'package:products_catelogs/features/products/presentation/widgets/add_edit_product_form_view.dart';

enum BulkUploadMode { upsert, updateOnly, createOnly }

class BulkUploadProductsView extends StatefulWidget {
  final Future<void> Function(ProductFormResult product) onUpsertOne;
  final Future<void> Function(ProductFormResult product) onUpdateOne;
  final Future<void> Function(ProductFormResult product) onCreateOne;
  final VoidCallback onBack;
  final bool inSideSheet;
  final String currencyCode;

  const BulkUploadProductsView({
    super.key,
    required this.onUpsertOne,
    required this.onUpdateOne,
    required this.onCreateOne,
    required this.onBack,
    this.inSideSheet = false,
    this.currencyCode = 'QAR',
  });

  @override
  State<BulkUploadProductsView> createState() => _BulkUploadProductsViewState();
}

class _BulkUploadProductsViewState extends State<BulkUploadProductsView> {
  final BulkUploadBackgroundService _backgroundService =
      BulkUploadBackgroundService.instance;
  bool _isParsing = false;
  bool _isUploading = false;
  String _statusMessage =
      'Select one ZIP that contains an Excel file and image files.';
  String? _selectedZipName;
  int _uploadedCount = 0;
  BulkUploadMode _mode = BulkUploadMode.upsert;

  final List<_BulkUploadRow> _rows = [];
  final List<String> _parseIssues = [];
  final List<String> _uploadIssues = [];

  @override
  void initState() {
    super.initState();
    _backgroundService.status.addListener(_onBackgroundStatusChanged);
    _syncFromStatus(_backgroundService.status.value);
  }

  @override
  void dispose() {
    _backgroundService.status.removeListener(_onBackgroundStatusChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canUpload = _rows.isNotEmpty && !_isParsing && !_isUploading;
    final progress = _rows.isEmpty ? 0.0 : _uploadedCount / _rows.length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 1000 || widget.inSideSheet;
        final horizontalPadding = widget.inSideSheet ? 14.0 : 0.0;
        final topPadding = widget.inSideSheet ? 14.0 : 0.0;
        return Padding(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            topPadding,
            horizontalPadding,
            12,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _header(isNarrow),
                if (widget.inSideSheet) ...[
                  const SizedBox(height: 12),
                  _sheetIntroCard(),
                ],
                const SizedBox(height: 12),
                _card(
                  title: 'ZIP Format',
                  subtitle:
                      'Supports simple fields and full unit/pricing config.',
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('1. Keep one Excel file (.xlsx or .xls).'),
                      SizedBox(height: 4),
                      Text('2. Keep image names in Excel images column.'),
                      SizedBox(height: 4),
                      Text(
                        '3. Separate multiple image names by comma/semicolon.',
                      ),
                      SizedBox(height: 4),
                      Text(
                        '4. Optional full config columns: baseunit, saleunits, localprices, localofferprices, hyperprices, hyperofferprices, stockunit.',
                      ),
                      SizedBox(height: 4),
                      Text('5. ZIP all files and upload the ZIP file.'),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _card(
                  title: 'Actions',
                  subtitle: _selectedZipName ?? 'No ZIP selected',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownButtonFormField<BulkUploadMode>(
                        initialValue: _mode,
                        decoration: const InputDecoration(
                          labelText: 'Upload Mode',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: BulkUploadMode.upsert,
                            child: Text('Upsert (Create + Update)'),
                          ),
                          DropdownMenuItem(
                            value: BulkUploadMode.updateOnly,
                            child: Text('Update Only'),
                          ),
                          DropdownMenuItem(
                            value: BulkUploadMode.createOnly,
                            child: Text('Create Only'),
                          ),
                        ],
                        onChanged: _isParsing || _isUploading
                            ? null
                            : (value) {
                                if (value == null) return;
                                setState(() => _mode = value);
                              },
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _modeHelperText(_mode),
                        style: const TextStyle(
                          color: Color(0xFF6B7280),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _isParsing || _isUploading
                              ? null
                              : _pickAndParseZip,
                          icon: const Icon(Iconsax.folder_open),
                          label: Text(_isParsing ? 'Parsing...' : 'Select ZIP'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(46),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: canUpload ? _uploadAll : null,
                          icon: const Icon(Iconsax.cloud_add),
                          label: Text(_uploadButtonLabel(_mode)),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(46),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _statusMessage,
                        style: const TextStyle(
                          color: Color(0xFF6B7280),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (_isUploading) ...[
                        const SizedBox(height: 10),
                        LinearProgressIndicator(value: progress),
                        const SizedBox(height: 4),
                        Text(
                          'Uploaded $_uploadedCount / ${_rows.length}',
                          style: const TextStyle(
                            color: Color(0xFF4B5565),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _summaryRow(),
                if (_parseIssues.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _issuesCard('Parse Issues', _parseIssues),
                ],
                if (_uploadIssues.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _issuesCard('Upload Issues', _uploadIssues),
                ],
                if (_rows.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _previewCard(),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _header(bool isNarrow) {
    final titleStyle = TextStyle(
      fontSize: widget.inSideSheet ? 24 : 30,
      height: 1.1,
      color: const Color(0xFF111827),
      fontWeight: FontWeight.w700,
    );
    final subtitleStyle = const TextStyle(
      color: Color(0xFF8A94A6),
      fontWeight: FontWeight.w500,
    );

    if (widget.inSideSheet) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Bulk Upload Products', style: titleStyle),
                const SizedBox(height: 4),
                Text(
                  'Import products from one ZIP package.',
                  style: subtitleStyle,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: widget.onBack,
            tooltip: 'Close',
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              side: const BorderSide(color: Color(0xFFDDE2EA)),
            ),
            icon: const Icon(Iconsax.close_circle),
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Bulk Upload Products', style: titleStyle),
              const SizedBox(height: 4),
              Text(
                'Import products from Excel + ZIP images for web.',
                style: subtitleStyle,
              ),
            ],
          ),
        ),
        if (!isNarrow)
          OutlinedButton.icon(
            onPressed: widget.onBack,
            icon: const Icon(Iconsax.arrow_left_2),
            label: const Text('Back to Products'),
          ),
      ],
    );
  }

  Widget _card({
    required String title,
    String? subtitle,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(widget.inSideSheet ? 16 : 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(widget.inSideSheet ? 18 : 16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
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
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(
                color: Color(0xFF8A94A6),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _sheetIntroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFFE8F6F6), Color(0xFFF2F7FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: const Color(0xFFD7E6EF)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recommended flow',
            style: TextStyle(
              color: Color(0xFF0F172A),
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 6),
          Text(
            '1) Select ZIP  2) Review issues  3) Start upload',
            style: TextStyle(
              color: Color(0xFF334155),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _summaryTile(
          label: 'Ready',
          value: _rows.length,
          icon: Iconsax.tick_circle,
          accent: const Color(0xFF0E9F6E),
          background: const Color(0xFFECFDF3),
        ),
        _summaryTile(
          label: 'Parse Issues',
          value: _parseIssues.length,
          icon: Iconsax.warning_2,
          accent: const Color(0xFFD97706),
          background: const Color(0xFFFFF7ED),
        ),
        _summaryTile(
          label: 'Upload Issues',
          value: _uploadIssues.length,
          icon: Iconsax.close_circle,
          accent: const Color(0xFFDC2626),
          background: const Color(0xFFFEF2F2),
        ),
      ],
    );
  }

  Widget _summaryTile({
    required String label,
    required int value,
    required IconData icon,
    required Color accent,
    required Color background,
  }) {
    final tileWidth = widget.inSideSheet ? 124.0 : 160.0;
    return SizedBox(
      width: tileWidth,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            Row(
              children: [
                Icon(icon, size: 16, color: accent),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: accent,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value.toString(),
              style: const TextStyle(
                color: Color(0xFF111827),
                fontSize: 26,
                height: 1,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _issuesCard(String title, List<String> issues) {
    return _card(
      title: title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: issues
            .take(20)
            .map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text('• $e'),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _previewCard() {
    final count = _rows.length > 10 ? 10 : _rows.length;
    return _card(
      title: 'Preview',
      subtitle: 'Showing first $count rows',
      child: Column(
        children: [
          for (int i = 0; i < count; i++) ...[
            if (i != 0) const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFCFCFD),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE7ECF3)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _rows[i].name,
                          style: const TextStyle(
                            color: Color(0xFF111827),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Row ${_rows[i].rowNumber} • ${_rows[i].itemCode} • ${_rows[i].images.length} images',
                          style: const TextStyle(
                            color: Color(0xFF6B7280),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${widget.currencyCode} ${(_rows[i].localPricesByUnit[_rows[i].baseUnit] ?? 0).toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Color(0xFF111827),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _pickAndParseZip() async {
    FilePickerResult? result;
    try {
      result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['zip'],
        withData: true,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _statusMessage = 'Failed to pick ZIP: $e');
      return;
    }

    if (result == null || result.files.single.bytes == null) return;
    final zipBytes = result.files.single.bytes!;
    final zipName = result.files.single.name;

    setState(() {
      _isParsing = true;
      _selectedZipName = zipName;
      _rows.clear();
      _parseIssues.clear();
      _uploadIssues.clear();
      _uploadedCount = 0;
      _statusMessage = 'Parsing ZIP and Excel...';
    });

    try {
      // Allow one frame so the parsing state is rendered before heavy work.
      await Future<void>.delayed(Duration.zero);
      final parsed = _parseZipBytes(zipBytes);
      if (!mounted) return;
      setState(() {
        _rows
          ..clear()
          ..addAll(parsed.rows);
        _parseIssues
          ..clear()
          ..addAll(parsed.issues);
        _statusMessage =
            'Parsed ${parsed.rows.length} rows. Issues: ${parsed.issues.length}';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _statusMessage = 'Parse failed: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Parse failed: $e')));
    } finally {
      if (mounted) {
        setState(() => _isParsing = false);
      }
    }
  }

  _ParsedResult _parseZipBytes(Uint8List zipBytes) {
    final archive = ZipDecoder().decodeBytes(zipBytes);
    Uint8List? excelBytes;
    final imagePool = <String, ProductDraftImage>{};

    for (final entry in archive) {
      if (!entry.isFile) continue;
      final raw = entry.content;
      if (raw is! List<int>) continue;
      final bytes = Uint8List.fromList(raw);
      final lowerPath = entry.name.toLowerCase();
      if (lowerPath.endsWith('.xlsx') || lowerPath.endsWith('.xls')) {
        excelBytes ??= bytes;
      }
      if (_isImageFile(lowerPath)) {
        final name = _baseName(entry.name);
        imagePool[name.toLowerCase()] = ProductDraftImage(
          name: name,
          bytes: bytes,
        );
      }
    }

    if (excelBytes == null) {
      throw StateError('No Excel file found inside ZIP.');
    }

    return _parseExcelBytes(excelBytes, imagePool);
  }

  _ParsedResult _parseExcelBytes(
    Uint8List excelBytes,
    Map<String, ProductDraftImage> imagePool,
  ) {
    final issues = <String>[];
    final rows = <_BulkUploadRow>[];

    final excel = xls.Excel.decodeBytes(excelBytes);
    if (excel.tables.isEmpty) {
      throw StateError('Excel has no sheets.');
    }

    final firstSheetName = excel.tables.keys.firstWhere(
      (name) => _normalize(name) == 'products',
      orElse: () => excel.tables.keys.first,
    );
    final sheet = excel.tables[firstSheetName];
    if (sheet == null || sheet.rows.isEmpty) {
      throw StateError('Excel sheet is empty.');
    }

    final headerMap = <String, int>{};
    final headerRow = sheet.rows.first;
    for (int i = 0; i < headerRow.length; i++) {
      final key = _normalize(_cellToString(headerRow[i]));
      if (key.isNotEmpty) headerMap[key] = i;
    }

    for (int rowIndex = 1; rowIndex < sheet.rows.length; rowIndex++) {
      final row = sheet.rows[rowIndex];
      final rowNumber = rowIndex + 1;

      final name = _getText(
        row,
        headerMap,
        keys: const ['name', 'productname', 'product_name'],
        fallback: 0,
      );
      final itemCode = _getText(
        row,
        headerMap,
        keys: const ['itemcode', 'item_code', 'code'],
        fallback: 1,
      );
      final priceText = _getText(
        row,
        headerMap,
        keys: const ['price', 'baseprice', 'base_price'],
        fallback: 2,
      );
      final offerPriceText = _getText(
        row,
        headerMap,
        keys: const ['offerprice', 'offer_price'],
        fallback: 3,
      );
      final unitText = _getText(
        row,
        headerMap,
        keys: const ['unit'],
        fallback: 4,
      );
      final baseUnitText = _getText(
        row,
        headerMap,
        keys: const ['baseunit', 'base_unit'],
      );
      final saleUnitsText = _getText(
        row,
        headerMap,
        keys: const ['saleunits', 'sale_units', 'unitsconfig', 'units_config'],
      );
      final stockText = _getText(
        row,
        headerMap,
        keys: const ['stock'],
        fallback: 5,
      );
      final stockUnitText = _getText(
        row,
        headerMap,
        keys: const [
          'stockunit',
          'stock_unit',
          'initialstockunit',
          'initial_stock_unit',
        ],
      );
      final description = _getText(
        row,
        headerMap,
        keys: const ['description', 'desc'],
        fallback: 6,
      );
      final category = _getText(
        row,
        headerMap,
        keys: const ['category', 'categoryid', 'category_id'],
        fallback: 7,
      );
      final market = _getText(
        row,
        headerMap,
        keys: const ['market'],
        fallback: 8,
      );
      final hyperPriceText = _getText(
        row,
        headerMap,
        keys: const ['hypermarketprice', 'hyper_market_price'],
        fallback: 10,
      );
      final localPricesText = _getText(
        row,
        headerMap,
        keys: const [
          'localprices',
          'local_prices',
          'pricesbyunit',
          'prices_by_unit',
        ],
      );
      final localOfferPricesText = _getText(
        row,
        headerMap,
        keys: const [
          'localofferprices',
          'local_offer_prices',
          'offerpricesbyunit',
          'offer_prices_by_unit',
        ],
      );
      final hyperPricesText = _getText(
        row,
        headerMap,
        keys: const ['hyperprices', 'hyper_prices', 'hyperpricesbyunit'],
      );
      final hyperOfferPricesText = _getText(
        row,
        headerMap,
        keys: const [
          'hyperofferprices',
          'hyper_offer_prices',
          'hyperofferpricesbyunit',
        ],
      );
      final imagesText = _getText(
        row,
        headerMap,
        keys: const ['images', 'image', 'image_names', 'imagefiles'],
        fallback: 14,
      );

      if (name.isEmpty && itemCode.isEmpty) continue;

      final basePrice = _toDouble(priceText);
      if (name.isEmpty || basePrice == null) {
        issues.add('Row $rowNumber skipped: invalid name or price.');
        continue;
      }

      final code = itemCode.isEmpty
          ? _generateItemCode(name: name, rowNumber: rowNumber)
          : itemCode;
      if (itemCode.isEmpty) {
        issues.add('Row $rowNumber missing item code. Generated: $code');
      }

      final fallbackUnit = unitText.trim().isEmpty ? 'Piece' : unitText.trim();
      final baseUnit = baseUnitText.trim().isNotEmpty
          ? baseUnitText.trim()
          : fallbackUnit;
      final saleUnits = _parseSaleUnitsConfig(
        raw: saleUnitsText,
        baseUnit: baseUnit,
        fallbackUnit: fallbackUnit,
      );

      final localPricesByUnit = _parseUnitPriceMap(localPricesText, saleUnits);
      final localOfferPricesByUnit = _parseUnitPriceMap(
        localOfferPricesText,
        saleUnits,
      );
      final hyperPricesByUnit = _parseUnitPriceMap(hyperPricesText, saleUnits);
      final hyperOfferPricesByUnit = _parseUnitPriceMap(
        hyperOfferPricesText,
        saleUnits,
      );

      localPricesByUnit.putIfAbsent(baseUnit, () => basePrice);

      final legacyOffer = _toDouble(offerPriceText);
      if (legacyOffer != null) {
        localOfferPricesByUnit.putIfAbsent(baseUnit, () => legacyOffer);
      }

      final legacyHyperPrice = _toDouble(hyperPriceText);
      if (legacyHyperPrice != null) {
        hyperPricesByUnit.putIfAbsent(baseUnit, () => legacyHyperPrice);
      }
      if (legacyOffer != null) {
        hyperOfferPricesByUnit.putIfAbsent(baseUnit, () => legacyOffer);
      }

      final images = <ProductDraftImage>[];
      if (imagesText.isNotEmpty) {
        final names = imagesText
            .split(RegExp(r'[;,|]'))
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty);
        for (final imageName in names) {
          final image = _findImage(imageName, imagePool);
          if (image == null) {
            issues.add('Row $rowNumber image not found: $imageName');
          } else {
            images.add(image);
          }
        }
      }

      rows.add(
        _BulkUploadRow(
          rowNumber: rowNumber,
          itemCode: code,
          name: name,
          category: category.isEmpty ? 'Uncategorized' : category,
          market: market.isEmpty ? 'Local Market' : market,
          baseUnit: baseUnit,
          saleUnits: saleUnits,
          localPricesByUnit: localPricesByUnit,
          localOfferPricesByUnit: localOfferPricesByUnit,
          hyperPricesByUnit: hyperPricesByUnit,
          hyperOfferPricesByUnit: hyperOfferPricesByUnit,
          description: description,
          stock: _toDouble(stockText) ?? 0,
          stockUnit: stockUnitText.trim().isEmpty ? null : stockUnitText.trim(),
          legacyOfferPrice: legacyOffer,
          legacyHyperPrice: legacyHyperPrice,
          images: images,
        ),
      );
    }

    return _ParsedResult(rows: rows, issues: issues);
  }

  Future<void> _uploadAll() async {
    if (_rows.isEmpty || _isUploading) return;
    if (_backgroundService.isRunning) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Another bulk upload is already running.'),
        ),
      );
      return;
    }
    final payloads = <ProductFormResult>[];
    for (int i = 0; i < _rows.length; i++) {
      final row = _rows[i];
      final baseUnit = row.baseUnit;
      final saleUnits = row.saleUnits.isEmpty
          ? [SaleUnitConfig(unit: baseUnit, conversionToBaseUnit: 1)]
          : row.saleUnits;

      final baseLocalPrice = row.localPricesByUnit[baseUnit] ?? 0;
      final baseLocalOffer =
          row.localOfferPricesByUnit[baseUnit] ?? row.legacyOfferPrice;
      final localRows = <MarketUnitPrice>[];
      final hyperRows = <MarketUnitPrice>[];

      for (final saleUnit in saleUnits) {
        final unit = saleUnit.unit;

        final localManual = row.localPricesByUnit[unit];
        final localManualOffer = row.localOfferPricesByUnit[unit];
        final hyperManual = row.hyperPricesByUnit[unit];
        final hyperManualOffer = row.hyperOfferPricesByUnit[unit];

        localRows.add(
          MarketUnitPrice(
            unit: unit,
            overrideEnabled: localManual != null,
            manualPrice: localManual,
            manualOfferPrice: localManualOffer,
            autoPrice: null,
            autoOfferPrice: null,
          ),
        );

        hyperRows.add(
          MarketUnitPrice(
            unit: unit,
            overrideEnabled: hyperManual != null,
            manualPrice: hyperManual,
            manualOfferPrice: hyperManualOffer,
            autoPrice: null,
            autoOfferPrice: null,
          ),
        );
      }

      final stockUnit = row.stockUnit ?? baseUnit;
      final stockInBase = row.stock * _conversionForUnit(stockUnit, saleUnits);

      payloads.add(
        ProductFormResult(
          name: row.name,
          code: row.itemCode.startsWith('#')
              ? row.itemCode
              : '#${row.itemCode}',
          description: row.description,
          category: row.category,
          baseUnit: baseUnit,
          saleUnits: saleUnits,
          marketPricingByMarket: {
            'Local Market': localRows,
            'Hyper Market': hyperRows,
          },
          displayPriceQar: baseLocalPrice,
          displayOfferPriceQar: baseLocalOffer,
          initialStockInput: row.stock,
          initialStockInputUnit: stockUnit,
          initialStockInBaseUnit: stockInBase,
          existingImageUrls: const [],
          newImages: row.images,
        ),
      );
    }

    unawaited(
      _backgroundService
          .start(
            items: payloads,
            uploader: (item, index) => _uploadOneByMode(item),
          )
          .catchError((_) {}),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Bulk upload started in background. You can switch screens.',
        ),
      ),
    );
  }

  void _onBackgroundStatusChanged() {
    if (!mounted) return;
    _syncFromStatus(_backgroundService.status.value);
  }

  void _syncFromStatus(BulkUploadStatus value) {
    setState(() {
      _isUploading = value.isRunning;
      _uploadedCount = value.completed;
      _uploadIssues
        ..clear()
        ..addAll(value.errors);
      _statusMessage = value.message;
    });
  }

  Future<void> _uploadOneByMode(ProductFormResult item) {
    switch (_mode) {
      case BulkUploadMode.upsert:
        return widget.onUpsertOne(item);
      case BulkUploadMode.updateOnly:
        return widget.onUpdateOne(item);
      case BulkUploadMode.createOnly:
        return widget.onCreateOne(item);
    }
  }

  String _uploadButtonLabel(BulkUploadMode mode) {
    switch (mode) {
      case BulkUploadMode.upsert:
        return 'Upload All (Create + Update)';
      case BulkUploadMode.updateOnly:
        return 'Upload All (Update Only)';
      case BulkUploadMode.createOnly:
        return 'Upload All (Create Only)';
    }
  }

  String _modeHelperText(BulkUploadMode mode) {
    switch (mode) {
      case BulkUploadMode.upsert:
        return 'Recommended. Existing codes are updated, new codes are created.';
      case BulkUploadMode.updateOnly:
        return 'Only updates existing product codes. Missing codes will fail.';
      case BulkUploadMode.createOnly:
        return 'Only creates new product codes. Existing codes will fail.';
    }
  }

  bool _isImageFile(String path) {
    final lower = path.toLowerCase();
    return lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.webp');
  }

  ProductDraftImage? _findImage(
    String name,
    Map<String, ProductDraftImage> imagePool,
  ) {
    final base = _baseName(name).toLowerCase();
    final direct = imagePool[base];
    if (direct != null) return direct;
    if (!base.contains('.')) {
      for (final ext in const ['.jpg', '.jpeg', '.png', '.webp']) {
        final candidate = imagePool['$base$ext'];
        if (candidate != null) return candidate;
      }
    }
    return null;
  }

  String _baseName(String path) {
    final normalized = path.replaceAll('\\', '/');
    final idx = normalized.lastIndexOf('/');
    return idx == -1 ? normalized : normalized.substring(idx + 1);
  }

  String _normalize(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  String _cellToString(dynamic cell) {
    if (cell == null) return '';
    try {
      final value = cell.value;
      if (value == null) return '';
      return value.toString().trim();
    } catch (_) {
      return cell.toString().trim();
    }
  }

  String _getText(
    List<dynamic> row,
    Map<String, int> headerMap, {
    required List<String> keys,
    int? fallback,
  }) {
    for (final key in keys) {
      final idx = headerMap[_normalize(key)];
      if (idx != null && idx >= 0 && idx < row.length) {
        final text = _cellToString(row[idx]);
        if (text.isNotEmpty) return text;
      }
    }
    if (fallback != null && fallback >= 0 && fallback < row.length) {
      return _cellToString(row[fallback]);
    }
    return '';
  }

  double? _toDouble(String value) {
    final cleaned = value.trim().replaceAll(',', '');
    if (cleaned.isEmpty) return null;
    return double.tryParse(cleaned);
  }

  String _generateItemCode({required String name, required int rowNumber}) {
    final seed = name
        .toUpperCase()
        .replaceAll(RegExp(r'[^A-Z0-9]'), '')
        .padRight(4, 'X')
        .substring(0, 4);
    return 'AUTO-$seed-$rowNumber';
  }

  List<SaleUnitConfig> _parseSaleUnitsConfig({
    required String raw,
    required String baseUnit,
    required String fallbackUnit,
  }) {
    final units = <SaleUnitConfig>[];
    final seen = <String>{};

    void add(String unit, double conversion) {
      final clean = unit.trim();
      if (clean.isEmpty) return;
      final key = clean.toLowerCase();
      if (!seen.add(key)) return;
      units.add(
        SaleUnitConfig(
          unit: clean,
          conversionToBaseUnit: conversion > 0 ? conversion : 1,
        ),
      );
    }

    add(baseUnit, 1);

    if (raw.trim().isNotEmpty) {
      final entries = raw.split(RegExp(r'[;,|]'));
      for (final entry in entries) {
        final part = entry.trim();
        if (part.isEmpty) continue;
        final split = part.split(RegExp(r'[:=]'));
        if (split.length >= 2) {
          add(split[0], _toDouble(split[1]) ?? 1);
        } else {
          add(part, 1);
        }
      }
    }

    if (units.isEmpty) {
      add(fallbackUnit, 1);
    }

    return units;
  }

  Map<String, double> _parseUnitPriceMap(
    String raw,
    List<SaleUnitConfig> units,
  ) {
    final map = <String, double>{};
    if (raw.trim().isEmpty) return map;

    final entries = raw.split(RegExp(r'[;,|]'));
    for (final entry in entries) {
      final part = entry.trim();
      if (part.isEmpty) continue;
      final split = part.split(RegExp(r'[:=]'));
      if (split.length < 2) continue;

      final unitName = _resolveUnitName(split[0], units);
      final price = _toDouble(split[1]);
      if (unitName == null || price == null || price <= 0) continue;

      map[unitName] = price;
    }

    return map;
  }

  String? _resolveUnitName(String raw, List<SaleUnitConfig> units) {
    final key = raw.trim().toLowerCase();
    if (key.isEmpty) return null;

    for (final unit in units) {
      if (unit.unit.trim().toLowerCase() == key) return unit.unit;
    }
    return null;
  }

  double _conversionForUnit(String unit, List<SaleUnitConfig> units) {
    final key = unit.trim().toLowerCase();
    for (final saleUnit in units) {
      if (saleUnit.unit.trim().toLowerCase() == key) {
        return saleUnit.conversionToBaseUnit;
      }
    }
    return 1;
  }
}

class _ParsedResult {
  final List<_BulkUploadRow> rows;
  final List<String> issues;

  _ParsedResult({required this.rows, required this.issues});
}

class _BulkUploadRow {
  final int rowNumber;
  final String itemCode;
  final String name;
  final String category;
  final String market;
  final String baseUnit;
  final List<SaleUnitConfig> saleUnits;
  final Map<String, double> localPricesByUnit;
  final Map<String, double> localOfferPricesByUnit;
  final Map<String, double> hyperPricesByUnit;
  final Map<String, double> hyperOfferPricesByUnit;
  final String description;
  final double stock;
  final String? stockUnit;
  final double? legacyOfferPrice;
  final double? legacyHyperPrice;
  final List<ProductDraftImage> images;

  const _BulkUploadRow({
    required this.rowNumber,
    required this.itemCode,
    required this.name,
    required this.category,
    required this.market,
    required this.baseUnit,
    required this.saleUnits,
    required this.localPricesByUnit,
    required this.localOfferPricesByUnit,
    required this.hyperPricesByUnit,
    required this.hyperOfferPricesByUnit,
    required this.description,
    required this.stock,
    required this.stockUnit,
    required this.legacyOfferPrice,
    required this.legacyHyperPrice,
    required this.images,
  });
}
