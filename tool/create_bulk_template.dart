import 'dart:io';

import 'package:excel/excel.dart';

void main(List<String> args) {
  final outputPath = args.isNotEmpty ? args[0] : 'products_bulk_template.xlsx';

  final headers = <String>[
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

  final excel = Excel.createExcel();
  final defaultSheet = excel.getDefaultSheet();
  final sheetName = 'products';

  final sheet = excel[sheetName];
  if (defaultSheet != null && defaultSheet != sheetName) {
    excel.delete(defaultSheet);
  }

  sheet.appendRow(headers.map(TextCellValue.new).toList());
  sheet.appendRow([
    TextCellValue('Sample Premium Rice 5kg'),
    TextCellValue('DUMMY-001'),
    DoubleCellValue(24.5),
    DoubleCellValue(21),
    TextCellValue('Piece'),
    DoubleCellValue(120),
    TextCellValue('Sample product for bulk upload testing'),
    TextCellValue('Groceries'),
    TextCellValue('Local Market'),
    DoubleCellValue(23),
    TextCellValue('sample_rice_front.jpg;sample_rice_back.jpg'),
    TextCellValue('Piece'),
    TextCellValue('Piece:1;Pack:3;Carton:12'),
    TextCellValue('Piece:24.5;Pack:70;Carton:280'),
    TextCellValue('Piece:21;Pack:65;Carton:260'),
    TextCellValue('Piece:23;Pack:68;Carton:270'),
    TextCellValue('Piece:20.5;Pack:63;Carton:250'),
    TextCellValue('Piece'),
  ]);

  final bytes = excel.encode();
  if (bytes == null || bytes.isEmpty) {
    stderr.writeln('Failed to encode Excel template.');
    exit(1);
  }

  File(outputPath)
    ..createSync(recursive: true)
    ..writeAsBytesSync(bytes);

  stdout.writeln('Created template: $outputPath');
  stdout.writeln('Sheet: $sheetName');
  stdout.writeln('Headers (${headers.length}):');
  for (var i = 0; i < headers.length; i++) {
    stdout.writeln('${i + 1}: ${headers[i]}');
  }
}
