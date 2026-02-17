import 'dart:io';

import 'package:archive/archive.dart';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';
import 'package:products_catelogs/products/provider/products_management_pro.dart';
import 'package:products_catelogs/theme/widgets/app_components.dart';
import 'package:products_catelogs/theme/widgets/reference_scaffold.dart';
import 'package:provider/provider.dart';

class BulkProductUploadScreen extends StatefulWidget {
  const BulkProductUploadScreen({super.key});

  @override
  State<BulkProductUploadScreen> createState() =>
      _BulkProductUploadScreenState();
}

class _BulkProductUploadScreenState extends State<BulkProductUploadScreen> {
  bool _isParsing = false;
  bool _isUploading = false;
  String _statusMessage =
      "Select a ZIP file that contains one Excel file and an images folder.";
  String? _selectedFileName;

  int _uploadedCount = 0;
  final List<_BulkUploadRow> _rows = [];
  final List<String> _parseIssues = [];
  final List<String> _uploadIssues = [];

  Directory? _workingDirectory;

  @override
  void dispose() {
    _cleanupWorkingDirectory();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canUpload = _rows.isNotEmpty && !_isParsing && !_isUploading;
    final uploadProgress = _rows.isEmpty ? 0.0 : _uploadedCount / _rows.length;

    return ReferenceScaffold(
      title: "Bulk Upload",
      subtitle: "Excel + images in one ZIP",
      body: SingleChildScrollView(
        child: Column(
          children: [
            AppSectionCard(
              title: "How to Prepare ZIP",
              subtitle: "Folder structure expected",
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text("1. Create one Excel file (.xlsx or .xls)."),
                  SizedBox(height: 4),
                  Text("2. Add an images folder with product images."),
                  SizedBox(height: 4),
                  Text("3. In Excel, keep image names in the images column."),
                  SizedBox(height: 4),
                  Text("4. ZIP the full folder and upload that ZIP."),
                ],
              ),
            ),
            const SizedBox(height: 12),
            AppSectionCard(
              title: "Actions",
              subtitle: _selectedFileName ?? "No file selected",
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isParsing || _isUploading
                          ? null
                          : _pickAndParseZip,
                      icon: const Icon(Iconsax.folder_open),
                      label: Text(
                        _isParsing ? "Parsing..." : "Select ZIP File",
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: canUpload ? _uploadAllProducts : null,
                      icon: const Icon(Iconsax.document_upload),
                      label: const Text("Upload All Products"),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _statusMessage,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (_isUploading) ...[
                    const SizedBox(height: 10),
                    LinearProgressIndicator(value: uploadProgress),
                    const SizedBox(height: 6),
                    Text(
                      "Uploaded $_uploadedCount / ${_rows.length}",
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            AppSectionCard(
              title: "Summary",
              child: Row(
                children: [
                  Expanded(
                    child: _summaryTile(
                      context,
                      title: "Ready",
                      value: _rows.length.toString(),
                      icon: Iconsax.box,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _summaryTile(
                      context,
                      title: "Parse Issues",
                      value: _parseIssues.length.toString(),
                      icon: Iconsax.warning_2,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _summaryTile(
                      context,
                      title: "Upload Issues",
                      value: _uploadIssues.length.toString(),
                      icon: Iconsax.info_circle,
                    ),
                  ),
                ],
              ),
            ),
            if (_parseIssues.isNotEmpty) ...[
              const SizedBox(height: 12),
              AppSectionCard(
                title: "Parse Issues",
                subtitle: "Fix these rows in Excel and upload again",
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _parseIssues
                      .take(20)
                      .map(
                        (issue) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text("- $issue"),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
            if (_uploadIssues.isNotEmpty) ...[
              const SizedBox(height: 12),
              AppSectionCard(
                title: "Upload Issues",
                subtitle: "Rows that failed during upload",
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _uploadIssues
                      .take(20)
                      .map(
                        (issue) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text("- $issue"),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
            if (_rows.isNotEmpty) ...[
              const SizedBox(height: 12),
              AppSectionCard(
                title: "Preview",
                subtitle: "First ${_rows.length > 10 ? 10 : _rows.length} rows",
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _rows.length > 10 ? 10 : _rows.length,
                  itemBuilder: (context, index) {
                    final row = _rows[index];
                    return AppInfoTile(
                      icon: Iconsax.box,
                      title: row.name,
                      subtitle:
                          "Row ${row.rowNumber} • ${row.itemCode} • ${row.imageFiles.length} images",
                      margin: const EdgeInsets.only(bottom: 8),
                      trailing: Text(
                        "QAR ${row.price.toStringAsFixed(2)}",
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _summaryTile(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withAlpha(10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            title,
            style: theme.textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
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
      );
    } on MissingPluginException {
      if (!mounted) return;
      const message =
          'File picker plugin is not loaded yet. Please stop the app and run it again (full restart).';
      setState(() => _statusMessage = message);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Plugin not loaded. Do a full restart (stop + run), not hot restart.',
          ),
        ),
      );
      return;
    } catch (e) {
      if (!mounted) return;
      setState(() => _statusMessage = 'File pick failed: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('File pick failed: $e')));
      return;
    }

    if (result == null || result.files.single.path == null) return;

    final zipPath = result.files.single.path!;
    final zipName = result.files.single.name;

    setState(() {
      _isParsing = true;
      _selectedFileName = zipName;
      _rows.clear();
      _parseIssues.clear();
      _uploadIssues.clear();
      _uploadedCount = 0;
      _statusMessage = "Reading ZIP and parsing Excel...";
    });

    try {
      _cleanupWorkingDirectory();
      _workingDirectory = await Directory.systemTemp.createTemp('bulk_upload_');

      final zipFile = File(zipPath);
      final bytes = await zipFile.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      File? excelFile;
      final imagePool = <String, File>{};

      for (final entry in archive) {
        if (!entry.isFile) continue;

        final outFile = File('${_workingDirectory!.path}/${entry.name}');
        outFile.parent.createSync(recursive: true);
        outFile.writeAsBytesSync(entry.content as List<int>);

        final lower = entry.name.toLowerCase();
        if (lower.endsWith('.xlsx') || lower.endsWith('.xls')) {
          excelFile ??= outFile;
        }

        if (_isImageFile(lower)) {
          imagePool[_baseName(entry.name).toLowerCase()] = outFile;
        }
      }

      if (excelFile == null) {
        throw Exception('No Excel file (.xlsx or .xls) found inside ZIP.');
      }

      final parsed = _parseExcel(excelFile, imagePool);

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
      setState(() {
        _statusMessage = 'Parse failed: $e';
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Parse failed: $e')));
    } finally {
      if (mounted) {
        setState(() => _isParsing = false);
      }
    }
  }

  _ParsedResult _parseExcel(File excelFile, Map<String, File> imagePool) {
    final issues = <String>[];
    final rows = <_BulkUploadRow>[];

    final bytes = excelFile.readAsBytesSync();
    final excel = Excel.decodeBytes(bytes);

    if (excel.tables.isEmpty) {
      throw Exception('Excel file has no sheets.');
    }

    final firstSheetName = excel.tables.keys.firstWhere(
      (name) => _normalize(name) == 'products',
      orElse: () => excel.tables.keys.first,
    );
    final sheet = excel.tables[firstSheetName];

    if (sheet == null || sheet.rows.isEmpty) {
      throw Exception('Excel sheet is empty.');
    }

    final headerRow = sheet.rows.first;
    final headerMap = <String, int>{};

    for (var i = 0; i < headerRow.length; i++) {
      final header = _normalize(_cellToString(headerRow[i]));
      if (header.isNotEmpty) {
        headerMap[header] = i;
      }
    }

    for (var rowIndex = 1; rowIndex < sheet.rows.length; rowIndex++) {
      final row = sheet.rows[rowIndex];
      final rowNumber = rowIndex + 1;

      // Template order:
      // 0 NAME, 1 itemcode, 2 price, 3 offerprice, 4 unit, 5 stock,
      // 6 description, 7 categoryid, 8 market, 9 hypermarket,
      // 10 hypermarketprice, 11 pcsprice, 12 kgprice, 13 ctnprice, 14 images
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
      final unit = _getText(row, headerMap, keys: const ['unit'], fallback: 4);
      final stockText = _getText(
        row,
        headerMap,
        keys: const ['stock'],
        fallback: 5,
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
      final hyperMarketText = _getText(
        row,
        headerMap,
        keys: const [
          'hypermarket',
          'hyper_market',
          'hyperprice',
          'hyper_price',
        ],
        fallback: 9,
      );
      final hyperMarketPriceText = _getText(
        row,
        headerMap,
        keys: const ['hypermarketprice', 'hyper_market_price'],
        fallback: 10,
      );
      final pcsPriceText = _getText(
        row,
        headerMap,
        keys: const ['pcsprice', 'pcs_price'],
        fallback: 11,
      );
      final kgPriceText = _getText(
        row,
        headerMap,
        keys: const ['kgprice', 'kg_price'],
        fallback: 12,
      );
      final ctnPriceText = _getText(
        row,
        headerMap,
        keys: const ['ctnprice', 'ctn_price', 'ctrprice', 'ctr_price'],
        fallback: 13,
      );
      final imagesText = _getText(
        row,
        headerMap,
        keys: const ['images', 'image', 'image_names', 'imagefiles'],
        fallback: 14,
      );

      if (name.isEmpty && itemCode.isEmpty) {
        continue;
      }

      final price = _toDouble(priceText);
      if (name.isEmpty || price == null) {
        issues.add('Row $rowNumber skipped: name/price is missing or invalid.');
        continue;
      }

      final normalizedItemCode = itemCode.isEmpty
          ? _generateItemCode(name: name, rowNumber: rowNumber)
          : itemCode;
      if (itemCode.isEmpty) {
        issues.add(
          'Row $rowNumber itemcode missing. Generated: $normalizedItemCode',
        );
      }

      final stock = _toInt(stockText);
      final normalizedUnit = unit.isEmpty ? 'PCS' : unit;
      final normalizedMarket = market.isEmpty ? 'Local Market' : market;
      final normalizedCategory = category.isEmpty ? 'Uncategorized' : category;

      final imageFiles = <File>[];
      if (imagesText.isNotEmpty) {
        final imageNames = imagesText
            .split(RegExp(r'[;,|]'))
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();

        for (final imageName in imageNames) {
          final file = _findImage(imageName, imagePool);
          if (file != null) {
            imageFiles.add(file);
          } else {
            issues.add('Row $rowNumber image not found: $imageName');
          }
        }
      }

      rows.add(
        _BulkUploadRow(
          rowNumber: rowNumber,
          itemCode: normalizedItemCode,
          market: normalizedMarket,
          name: name,
          price: price,
          offerPrice: _toDouble(offerPriceText),
          unit: normalizedUnit,
          stock: stock,
          description: description,
          categoryId: normalizedCategory,
          hyperMarket: _toDouble(hyperMarketText) ?? 0,
          hyperMarketPrice: _toDouble(hyperMarketPriceText),
          kgPrice: _toDouble(kgPriceText) ?? 0,
          ctnPrice: _toDouble(ctnPriceText) ?? 0,
          pcsPrice: _toDouble(pcsPriceText) ?? 0,
          imageFiles: imageFiles,
        ),
      );
    }

    return _ParsedResult(rows: rows, issues: issues);
  }

  Future<void> _uploadAllProducts() async {
    if (_rows.isEmpty || _isUploading) return;

    final provider = context.read<ProductProvider>();

    setState(() {
      _isUploading = true;
      _uploadedCount = 0;
      _uploadIssues.clear();
      _statusMessage = 'Uploading products...';
    });

    for (var index = 0; index < _rows.length; index++) {
      final row = _rows[index];

      final product = Product(
        id: '${DateTime.now().microsecondsSinceEpoch}_$index',
        itemCode: row.itemCode,
        market: row.market,
        name: row.name,
        price: row.price,
        offerPrice: row.offerPrice,
        unit: row.unit,
        stock: row.stock,
        description: row.description,
        images: const [],
        categoryId: row.categoryId,
        hyperMarket: row.hyperMarket,
        hyperMarketPrice: row.hyperMarketPrice,
        kgPrice: row.kgPrice,
        ctrPrice: row.ctnPrice,
        pcsPrice: row.pcsPrice,
      );

      try {
        await provider.addProduct(product, row.imageFiles);
      } catch (e) {
        _uploadIssues.add('Row ${row.rowNumber} failed: $e');
      }

      if (!mounted) return;
      setState(() {
        _uploadedCount = index + 1;
      });
    }

    if (!mounted) return;

    final successCount = _rows.length - _uploadIssues.length;
    setState(() {
      _isUploading = false;
      _statusMessage =
          'Upload complete. Success: $successCount, Failed: ${_uploadIssues.length}';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Bulk upload finished. Success: $successCount, Failed: ${_uploadIssues.length}',
        ),
      ),
    );
  }

  bool _isImageFile(String lowerPath) {
    return lowerPath.endsWith('.jpg') ||
        lowerPath.endsWith('.jpeg') ||
        lowerPath.endsWith('.png') ||
        lowerPath.endsWith('.webp');
  }

  String _baseName(String path) {
    final normalized = path.replaceAll('\\', '/');
    final index = normalized.lastIndexOf('/');
    if (index == -1) return normalized;
    return normalized.substring(index + 1);
  }

  File? _findImage(String name, Map<String, File> imagePool) {
    final base = _baseName(name).toLowerCase();

    final direct = imagePool[base];
    if (direct != null) return direct;

    if (!base.contains('.')) {
      const extensions = ['.jpg', '.jpeg', '.png', '.webp'];
      for (final extension in extensions) {
        final candidate = imagePool['$base$extension'];
        if (candidate != null) return candidate;
      }
    }

    return null;
  }

  String _normalize(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  String _cellToString(dynamic cell) {
    if (cell == null) return '';

    try {
      final dynamic value = cell.value;
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
      final index = headerMap[_normalize(key)];
      if (index != null && index >= 0 && index < row.length) {
        final text = _cellToString(row[index]);
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

  int _toInt(String value) {
    final number = _toDouble(value);
    if (number == null) return 0;
    return number.toInt();
  }

  String _generateItemCode({required String name, required int rowNumber}) {
    final nameSeed = name
        .toUpperCase()
        .replaceAll(RegExp(r'[^A-Z0-9]'), '')
        .padRight(4, 'X')
        .substring(0, 4);
    return 'AUTO-$nameSeed-$rowNumber';
  }

  void _cleanupWorkingDirectory() {
    final dir = _workingDirectory;
    if (dir != null && dir.existsSync()) {
      try {
        dir.deleteSync(recursive: true);
      } catch (_) {
        // ignore cleanup failures
      }
    }
    _workingDirectory = null;
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
  final String market;
  final String name;
  final double price;
  final double? offerPrice;
  final String unit;
  final int stock;
  final String description;
  final String categoryId;
  final double hyperMarket;
  final double? hyperMarketPrice;
  final double kgPrice;
  final double ctnPrice;
  final double pcsPrice;
  final List<File> imageFiles;

  _BulkUploadRow({
    required this.rowNumber,
    required this.itemCode,
    required this.market,
    required this.name,
    required this.price,
    required this.offerPrice,
    required this.unit,
    required this.stock,
    required this.description,
    required this.categoryId,
    required this.hyperMarket,
    required this.hyperMarketPrice,
    required this.kgPrice,
    required this.ctnPrice,
    required this.pcsPrice,
    required this.imageFiles,
  });
}
