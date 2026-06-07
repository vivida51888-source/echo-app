import 'dart:convert';
import 'dart:io';

void main() {
  final text = utf8.decode(File('lib/pages/echo_tree_page.dart').readAsBytesSync());
  for (final s in ['雨露树', '雨露最多保留 2 份 · 连续记录，雨露更丰沛', '生命', '待收露', '??']) {
    print('"$s" => ${s.allMatches(text).length}');
  }
}
