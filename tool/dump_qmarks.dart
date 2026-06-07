import 'dart:convert';
import 'dart:io';

void dumpQuestionMarks(String path) {
  final text = utf8.decode(File(path).readAsBytesSync());
  var start = 0;
  var n = 0;
  stdout.writeln('=== $path ===');
  while (true) {
    final idx = text.indexOf('?', start);
    if (idx < 0) break;
    if (text.substring(idx).startsWith('??')) {
      n++;
      stdout.writeln('--- $n at $idx ---');
      stdout.writeln(text.substring(idx - 60, idx + 60).replaceAll('\r', '').replaceAll('\n', ' '));
    }
    start = idx + 1;
  }
}

void main() {
  dumpQuestionMarks('lib/pages/mood_bookshelf_page.dart');
  dumpQuestionMarks('lib/pages/echo_tree_page.dart');
}
