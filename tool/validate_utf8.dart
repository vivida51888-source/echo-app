import 'dart:convert';
import 'dart:io';

void main() {
  for (final entity in Directory('lib').listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    final bytes = entity.readAsBytesSync();
    try {
      utf8.decode(bytes);
    } catch (e) {
      stdout.writeln('INVALID UTF-8: ${entity.path}');
      stdout.writeln('  $e');
    }
  }
}
