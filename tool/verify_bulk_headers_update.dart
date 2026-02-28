import 'dart:io';
import 'package:excel/excel.dart';

String _cellText(Data? cell) => cell?.value?.toString() ?? '';

void main(List<String> args) {
  if (args.length < 2) {
    stderr.writeln('usage: dart run tool/verify_bulk_headers_update.dart <original.xlsx> <updated.xlsx>');
    exit(64);
  }

  final original = Excel.decodeBytes(File(args[0]).readAsBytesSync());
  final updated = Excel.decodeBytes(File(args[1]).readAsBytesSync());
  final oSheet = original.tables[original.tables.keys.first]!;
  final uSheet = updated.tables[updated.tables.keys.first]!;

  final oRows = oSheet.rows.length;
  final uRows = uSheet.rows.length;
  final oCols = oSheet.rows.isEmpty ? 0 : oSheet.rows.first.length;
  final uCols = uSheet.rows.isEmpty ? 0 : uSheet.rows.first.length;

  var mismatches = 0;
  for (var r = 1; r < oRows && r < uRows; r++) {
    final oRow = oSheet.rows[r];
    final uRow = uSheet.rows[r];
    for (var c = 0; c < oCols; c++) {
      final ov = c < oRow.length ? _cellText(oRow[c]) : '';
      final uv = c < uRow.length ? _cellText(uRow[c]) : '';
      if (ov != uv) {
        mismatches++;
        if (mismatches <= 10) {
          stdout.writeln('Mismatch r=${r + 1} c=${c + 1}: "$ov" != "$uv"');
        }
      }
    }
  }

  stdout.writeln('original_rows=$oRows updated_rows=$uRows');
  stdout.writeln('original_header_cols=$oCols updated_header_cols=$uCols');
  stdout.writeln('data_mismatches_first_${oCols}_cols=$mismatches');
}
