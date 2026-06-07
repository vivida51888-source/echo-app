import 'dart:convert';
import 'dart:io';

void main() {
  final text = utf8.decode(File('lib/pages/settings_page.dart').readAsBytesSync());
  for (final s in ['设置', '时间 · 记忆', '印记 · 重要日', '偏好', '外观', '??']) {
    print('"$s" => ${text.contains(s)}');
  }
}
