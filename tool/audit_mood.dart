import 'dart:convert';
import 'dart:io';

void main() {
  final text = utf8.decode(File('lib/pages/mood_bookshelf_page.dart').readAsBytesSync());
  for (final needle in [
    '为书架命名',
    '恢复默认',
    '取消',
    '保存',
    '写下的日子会在这里，排成一年的书架',
    '心情月历',
    '心情分布',
    '📖',
    '??',
    '恢复默认',
  ]) {
    print('${needle.codeUnits.length} chars "$needle" => count ${needle.allMatches(text).length}');
  }
}
