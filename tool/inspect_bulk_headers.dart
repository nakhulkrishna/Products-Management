import 'dart:io';
import 'package:excel/excel.dart';

void main(List<String> args) {
  if (args.isEmpty) {
    stderr.writeln('usage: dart run tool/inspect_bulk_headers.dart <xlsx-path>');
    exit(64);
  }
  final path = args.first;
  final bytes = File(path).readAsBytesSync();
  final excel = Excel.decodeBytes(bytes);
  final first = excel.tables.keys.first;
  final sheet = excel.tables[first]!;
  final header = sheet.rows.isEmpty ? <Data?>[] : sheet.rows.first;
  stdout.writeln('sheet=$first rows=${sheet.maxRows}');
  for (var i = 0; i < header.length; i++) {
    final v = header[i]?.value?.toString() ?? '';
    stdout.writeln('${i + 1}: $v');
  }
}
