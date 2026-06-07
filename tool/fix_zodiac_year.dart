import 'dart:convert';
import 'dart:io';

void main() {
  final file = File('lib/pages/mood_bookshelf_page.dart');
  var text = utf8.decode(file.readAsBytesSync());
  const old = "'\$year · \${zodiac.label}座'";
  const neu = "'\$year · \${zodiac.label}年'";
  if (text.contains(old)) {
    file.writeAsStringSync(text.replaceAll(old, neu), encoding: utf8);
    stdout.writeln('Fixed: 马座 -> 马年');
  } else {
    stdout.writeln('Pattern not found');
  }
}
