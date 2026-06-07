import 'dart:convert';
import 'dart:io';

void main() {
  final file = File('lib/pages/mood_bookshelf_page.dart');
  var text = utf8.decode(file.readAsBytesSync());
  const pairs = [
    ["'\$year \uFFFD \${zodiac.label}?'", "'\$year · \${zodiac.label}座'"],
    ["'\$year � \${zodiac.label}?'", "'\$year · \${zodiac.label}座'"],
    ["return '\$time \uFFFD \$preview';", "return '\$time · \$preview';"],
    ["return '\$time � \$preview';", "return '\$time · \$preview';"],
  ];
  var changed = false;
  for (final pair in pairs) {
    if (text.contains(pair[0])) {
      text = text.replaceAll(pair[0], pair[1]);
      changed = true;
    }
  }
  if (changed) {
    file.writeAsStringSync(text, encoding: utf8);
    stdout.writeln('Fixed mood_bookshelf_page.dart');
  } else {
    stdout.writeln('No mood_bookshelf changes');
  }
}
