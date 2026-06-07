import 'dart:io';

void main() {
  final files = Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  var offset = 0;
  for (final f in files) {
    final bytes = f.readAsBytesSync();
    final start = offset;
    final end = offset + bytes.length;
    if (38008 >= start && 38008 < end) {
      final local = 38008 - start;
      stdout.writeln('idx 38008 is in ${f.path} local=$local');
      stdout.writeln('bytes: ${bytes.sublist((local - 5).clamp(0, bytes.length), (local + 15).clamp(0, bytes.length))}');
      stdout.writeln('text: ${String.fromCharCodes(bytes.sublist((local - 20).clamp(0, bytes.length), (local + 40).clamp(0, bytes.length)))}');
    }
    offset = end + 1;
  }
}
