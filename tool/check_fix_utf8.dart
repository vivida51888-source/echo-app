import 'dart:convert';
import 'dart:io';

void main() {
  final text = utf8.decode(File('tool/fix_utf8.dart').readAsBytesSync());
  final idx = text.indexOf("'为书架命名'");
  print('为书架命名 in fix_utf8.dart: ${idx >= 0}');
  if (idx >= 0) print(text.substring(idx - 20, idx + 30));
}
