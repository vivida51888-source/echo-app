import 'dart:convert';
import 'dart:io';

void main() {
  final text = utf8.decode(File('lib/pages/mood_bookshelf_page.dart').readAsBytesSync());
  var start = 0;
  var n = 0;
  while (true) {
    final idx = text.indexOf("'??'", start);
    if (idx < 0) break;
    n++;
    print('--- match $n at $idx ---');
    print(text.substring(idx - 80, idx + 80).replaceAll('\r', '\\r').replaceAll('\n', '\\n\n'));
    start = idx + 1;
    if (n >= 6) break;
  }
}
