import 'dart:convert';
import 'dart:io';

void main() {
  final text = utf8.decode(File('lib/pages/mood_bookshelf_page.dart').readAsBytesSync());
  for (final s in ['\$year · \${zodiac.label}座', '�', '?座']) {
    print('"$s" => ${text.contains(s)}');
  }
  final idx = text.indexOf('zodiac.label');
  print(text.substring(idx - 15, idx + 25));
}
