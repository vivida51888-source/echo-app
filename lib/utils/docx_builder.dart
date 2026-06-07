import 'dart:convert';

import 'package:archive/archive.dart';

/// 最小 OOXML Word 文档（UTF-8，仅纯文本段落）。
abstract final class DocxBuilder {
  static List<int> build(String text) {
    final archive = Archive();
    void addUtf8(String path, String xml) {
      final bytes = utf8.encode(xml);
      archive.addFile(ArchiveFile(path, bytes.length, bytes));
    }

    addUtf8('[Content_Types].xml', _contentTypes);
    addUtf8('_rels/.rels', _packageRels);
    addUtf8('word/_rels/document.xml.rels', _documentRels);
    addUtf8('word/document.xml', _documentXml(text));
    return ZipEncoder().encode(archive);
  }

  static const _contentTypes = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
</Types>''';

  static const _packageRels = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>
</Relationships>''';

  static const _documentRels = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"/>''';

  static String _documentXml(String text) {
    final normalized = text.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    final lines = normalized.split('\n');
    final paragraphs = StringBuffer();
    for (final line in lines) {
      paragraphs.writeln('<w:p><w:r><w:t xml:space="preserve">${_escapeXml(line)}</w:t></w:r></w:p>');
    }
    if (lines.isEmpty) {
      paragraphs.writeln('<w:p><w:r><w:t xml:space="preserve"></w:t></w:r></w:p>');
    }

    return '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:body>
$paragraphs  </w:body>
</w:document>''';
  }

  static String _escapeXml(String value) {
    return value
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }
}
