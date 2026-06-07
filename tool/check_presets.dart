import 'dart:convert';
import 'dart:io';

void main() {
  final text = utf8.decode(File('lib/models/echo_appearance_preset.dart').readAsBytesSync());
  for (final s in ['暮纸', '暮沉', '晨雾', '雾霭', '杏白', '杏茶', '苔痕', '苔墨', '樱落', '雪净']) {
    print('"$s" => ${text.contains(s)}');
  }
}
