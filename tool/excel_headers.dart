import 'dart:io';
import 'package:excel/excel.dart';

void main(List<String> args) {
  if (args.isEmpty) {
    stderr.writeln('usage: dart run tool/excel_headers.dart <xlsx-path>');
    exit(2);
  }
  final file = File(args[0]);
  final bytes = file.readAsBytesSync();
  final excel = Excel.decodeBytes(bytes);
  if (excel.tables.isEmpty) {
    stdout.writeln('No sheets');
    return;
  }
  final firstName = excel.tables.keys.first;
  final sheet = excel.tables[firstName]!;
  stdout.writeln('Sheet: $firstName');
  if (sheet.rows.isEmpty) {
    stdout.writeln('No rows');
    return;
  }
  final row = sheet.rows.first;
  for (var i = 0; i < row.length; i++) {
    final v = row[i]?.value?.toString() ?? '';
    stdout.writeln('$i: $v');
  }
}
