import 'dart:io';

void main() {
  final root = Directory('lib');
  var cumulative = 0;
  for (final entity in root.listSync(recursive: true)..sort((a, b) => a.path.compareTo(b.path))) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    final bytes = entity.readAsBytesSync();
    for (var i = 0; i < bytes.length - 2; i++) {
      if (bytes[i] == 0xB7 && bytes[i + 1] == 0x20 && bytes[i + 2] == 0x3F) {
        stdout.writeln('MATCH ${entity.path} local=$i cumulative~${cumulative + i}');
        stdout.writeln('  context: ${String.fromCharCodes(bytes.sublist((i - 20).clamp(0, bytes.length), (i + 30).clamp(0, bytes.length)))}');
      }
      // also find lone 0x3F replacing chinese - pattern like ? followed by more ?
      if (bytes[i] == 0x3F && i > 0 && bytes[i - 1] >= 0x80) {
        // continuation of corrupted multibyte
      }
    }
    cumulative += bytes.length + 1; // +1 for path separator approximation
  }

  // Also scan each file for invalid utf8 using convert
  for (final entity in root.listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    final bytes = entity.readAsBytesSync();
    var i = 0;
    while (i < bytes.length) {
      final b = bytes[i];
      if (b <= 0x7F) {
        i++;
        continue;
      }
      if (b >= 0xC2 && b <= 0xDF) {
        if (i + 1 >= bytes.length || !_isContinuation(bytes[i + 1])) {
          stdout.writeln('BAD2 ${entity.path}@$i: ${bytes.sublist(i, (i + 8).clamp(0, bytes.length))}');
          i++;
          continue;
        }
        i += 2;
        continue;
      }
      if (b >= 0xE0 && b <= 0xEF) {
        if (i + 2 >= bytes.length ||
            !_isContinuation(bytes[i + 1]) ||
            !_isContinuation(bytes[i + 2])) {
          stdout.writeln('BAD3 ${entity.path}@$i: ${bytes.sublist(i, (i + 8).clamp(0, bytes.length))}');
          i++;
          continue;
        }
        i += 3;
        continue;
      }
      if (b >= 0xF0 && b <= 0xF4) {
        if (i + 3 >= bytes.length ||
            !_isContinuation(bytes[i + 1]) ||
            !_isContinuation(bytes[i + 2]) ||
            !_isContinuation(bytes[i + 3])) {
          stdout.writeln('BAD4 ${entity.path}@$i: ${bytes.sublist(i, (i + 8).clamp(0, bytes.length))}');
          i++;
          continue;
        }
        i += 4;
        continue;
      }
      if (b == 0xC0 || b == 0xC1 || (b >= 0xF5 && b <= 0xFF)) {
        stdout.writeln('BAD1 ${entity.path}@$i: byte=$b');
        i++;
        continue;
      }
      // 0x80-0xBF without lead byte, or 0xB7 as orphan
      stdout.writeln('ORPHAN ${entity.path}@$i: byte=$b ctx=${bytes.sublist(i, (i + 6).clamp(0, bytes.length))}');
      i++;
    }
  }
}

bool _isContinuation(int b) => b >= 0x80 && b <= 0xBF;
