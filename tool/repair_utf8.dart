import 'dart:convert';
import 'dart:io';

void repair(String path) {
  final file = File(path);
  final bytes = file.readAsBytesSync();
  try {
    utf8.decode(bytes);
    stdout.writeln('OK: $path');
    return;
  } catch (e) {
    stdout.writeln('Repairing $path: $e');
  }
  final text = utf8.decode(bytes, allowMalformed: true);
  file.writeAsStringSync(text, encoding: utf8);
  stdout.writeln('Repaired $path (${text.contains('�')} replacement chars)');
}

void main() {
  for (final path in [
    'lib/pages/mood_bookshelf_page.dart',
    'lib/pages/echo_tree_page.dart',
  ]) {
    repair(path);
  }
}
