import 'dart:convert';
import 'dart:io';

void main() {
  final backup = utf8.decode(File('tools/settings_page.dart').readAsBytesSync());
  var text = backup
      .replaceFirst(
        "import '../widgets/echo_page_header.dart';",
        "import '../widgets/echo_page_header.dart';\nimport '../widgets/echo_themed_scope.dart';",
      )
      .replaceFirst(
        'return ColoredBox(\n      color: EchoColors.appBackground,\n      child: SafeArea(',
        'return EchoPageBackground(\n      child: SafeArea(',
      )
      .replaceFirst(
        "subtitle: '纸色 · 当前\$name'",
        "subtitle: '纸色调 · 当前\$name'",
      );

  File('lib/pages/settings_page.dart').writeAsStringSync(text, encoding: utf8);
  stdout.writeln('Restored settings_page.dart from tools backup');
}
