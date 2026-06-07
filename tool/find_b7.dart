import 'dart:io';

void main() {
  for (final entity in Directory('lib').listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    final bytes = entity.readAsBytesSync();
    for (var i = 0; i < bytes.length; i++) {
      if (bytes[i] == 0xB7 && (i == 0 || bytes[i - 1] != 0xC2)) {
        stdout.writeln('LONE B7 ${entity.path}@$i');
        stdout.writeln('  ${bytes.sublist((i - 10).clamp(0, bytes.length), (i + 10).clamp(0, bytes.length))}');
      }
    }
  }
}
