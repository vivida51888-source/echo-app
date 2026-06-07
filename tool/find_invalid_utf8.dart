import 'dart:convert';
import 'dart:io';

void main() {
  final root = Directory('lib');
  for (final entity in root.listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    final bytes = entity.readAsBytesSync();
    var offset = 0;
    var global = 0;
    var invalid = false;
    while (offset < bytes.length) {
      try {
        final r = utf8.decode(bytes.sublist(offset, offset + 1), allowMalformed: false);
        final len = utf8.encode(r).length;
        offset += len;
        global += len;
      } catch (_) {
        invalid = true;
        stdout.writeln('${entity.path}: invalid at byte $offset (global~$global)');
        stdout.writeln('  bytes: ${bytes.sublist(offset, (offset + 12).clamp(0, bytes.length))}');
        // skip one byte and continue
        offset += 1;
        global += 1;
      }
    }
    if (invalid) stdout.writeln('---');
  }
}
