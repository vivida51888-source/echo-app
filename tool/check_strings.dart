import 'dart:convert';
import 'dart:io';

void main() {
  final path = 'lib/pages/mood_bookshelf_page.dart';
  final bytes = File(path).readAsBytesSync();
  try {
    final text = utf8.decode(bytes);
    print('Valid UTF-8, length=${text.length}');
    for (final needle in ['为书架命名', '?????', '取消', '心情月历', '心情分布']) {
      print('$needle => ${text.contains(needle)}');
    }
    final idx = text.indexOf("title: const Text(");
    print(text.substring(idx, idx + 120));
  } catch (e) {
    print('Invalid: $e');
  }
}
