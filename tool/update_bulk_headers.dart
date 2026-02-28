import 'dart:io';
import 'package:excel/excel.dart';

String normalize(String value) => value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

void main(List<String> args) {
  if (args.length < 2) {
    stderr.writeln('usage: dart run tool/update_bulk_headers.dart <input.xlsx> <output.xlsx>');
    exit(64);
  }

  final inputPath = args[0];
  final outputPath = args[1];

  final bytes = File(inputPath).readAsBytesSync();
  final excel = Excel.decodeBytes(bytes);
  final sheetName = excel.tables.keys.firstWhere(
    (name) => normalize(name) == 'products',
    orElse: () => excel.tables.keys.first,
  );
  final sheet = excel.tables[sheetName]!;

  final existingHeader = sheet.rows.isEmpty ? <Data?>[] : sheet.rows.first;
  final renameMap = <String, String>{
    'name': 'name',
    'categoryid': 'category',
  };

  final finalHeaders = <String>[];
  final seen = <String>{};

  for (var i = 0; i < existingHeader.length; i++) {
    final raw = existingHeader[i]?.value?.toString().trim() ?? '';
    if (raw.isEmpty) {
      finalHeaders.add('');
      continue;
    }
    final norm = normalize(raw);
    final renamed = renameMap[norm] ?? raw.trim();
    finalHeaders.add(renamed);
    if (renamed.isNotEmpty) seen.add(normalize(renamed));
  }

  final requiredHeaders = <String>[
    'name',
    'itemcode',
    'price',
    'offerprice',
    'unit',
    'stock',
    'description',
    'category',
    'market',
    'hypermarketprice',
    'images',
    'baseunit',
    'saleunits',
    'localprices',
    'localofferprices',
    'hyperprices',
    'hyperofferprices',
    'stockunit',
  ];

  for (final header in requiredHeaders) {
    if (!seen.contains(normalize(header))) {
      finalHeaders.add(header);
      seen.add(normalize(header));
    }
  }

  for (var col = 0; col < finalHeaders.length; col++) {
    sheet.updateCell(
      CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0),
      TextCellValue(finalHeaders[col]),
    );
  }

  final outBytes = excel.encode();
  if (outBytes == null) {
    stderr.writeln('Failed to encode updated workbook.');
    exit(1);
  }

  File(outputPath)
    ..createSync(recursive: true)
    ..writeAsBytesSync(outBytes);

  stdout.writeln('Updated file written: $outputPath');
  stdout.writeln('Sheet: $sheetName');
  stdout.writeln('Final headers (${finalHeaders.length}):');
  for (var i = 0; i < finalHeaders.length; i++) {
    stdout.writeln('${i + 1}: ${finalHeaders[i]}');
  }
}
