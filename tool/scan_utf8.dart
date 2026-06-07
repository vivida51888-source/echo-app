import 'dart:convert';
import 'dart:io';

void main() {
  final root = Directory('lib');
  for (final entity in root.listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    final bytes = entity.readAsBytesSync();
    try {
      utf8.decode(bytes, allowMalformed: false);
    } catch (e) {
      stdout.writeln('INVALID: ${entity.path} ($e)');
      for (var i = 0; i < bytes.length; i++) {
        if (bytes[i] == 0xEF && i + 2 < bytes.length &&
            bytes[i + 1] == 0xBF && bytes[i + 2] == 0xBD) {
          stdout.writeln('  replacement at $i');
        }
      }
    }
    final text = utf8.decode(bytes, allowMalformed: true);
    if (text.contains('�') || RegExp(r"'[^']*\?\?").hasMatch(text)) {
      stdout.writeln('SUSPICIOUS: ${entity.path}');
    }
  }
}
