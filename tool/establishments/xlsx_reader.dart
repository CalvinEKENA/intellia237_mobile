import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

/// Lecteur minimal de classeur `.xlsx` (Office Open XML), sans dépendance :
/// un zip, des chaînes partagées et des feuilles en XML.
///
/// Suffit aux exports tabulaires (texte et nombres) ; ne lit ni formules, ni
/// styles, ni cellules fusionnées.
class XlsxWorkbook {
  XlsxWorkbook._(this.sheets);

  /// Feuilles dans l'ordre du classeur : nom → lignes → cellules.
  final Map<String, List<List<String>>> sheets;

  static XlsxWorkbook read(Uint8List bytes) {
    final files = _unzip(bytes);
    String text(String path) {
      final data = files[path];
      if (data == null) throw FormatException('Entrée absente : $path');
      final decoded = utf8.decode(data);
      return decoded.startsWith('\uFEFF') ? decoded.substring(1) : decoded;
    }

    final shared = <String>[];
    if (files.containsKey('xl/sharedStrings.xml')) {
      for (final item in RegExp(
        '<$_ns'
        r'si\b[^>]*>(.*?)</'
        '$_ns'
        r'si>',
        dotAll: true,
      ).allMatches(text('xl/sharedStrings.xml'))) {
        shared.add(
          [
            for (final t in RegExp(
              '<$_ns'
              r't(?:\s[^>]*)?>(.*?)</'
              '$_ns'
              r't>',
              dotAll: true,
            ).allMatches(item.group(1)!))
              _unescape(t.group(1)!),
          ].join(),
        );
      }
    }

    final relations = <String, String>{
      for (final rel in RegExp(
        '<$_ns'
        r'Relationship\b([^>]*)/?>',
      ).allMatches(text('xl/_rels/workbook.xml.rels')))
        _attribute(rel.group(1)!, 'Id')!: _attribute(rel.group(1)!, 'Target')!,
    };
    final sheets = <String, List<List<String>>>{};
    for (final sheet in RegExp(
      '<$_ns'
      r'sheet\b([^>]*)/?>',
    ).allMatches(text('xl/workbook.xml'))) {
      final attributes = sheet.group(1)!;
      final name = _unescape(_attribute(attributes, 'name')!);
      var target = relations[_attribute(attributes, 'r:id')!]!;
      target = target.startsWith('/')
          ? target.substring(1)
          : target.startsWith('xl/')
          ? target
          : 'xl/$target';
      sheets[name] = _rows(text(target), shared);
    }
    return XlsxWorkbook._(sheets);
  }

  static List<List<String>> _rows(String xml, List<String> shared) {
    final rows = <List<String>>[];
    for (final row in RegExp(
      '<$_ns'
      r'row\b[^>]*>(.*?)</'
      '$_ns'
      r'row>',
      dotAll: true,
    ).allMatches(xml)) {
      final cells = <int, String>{};
      for (final cell in RegExp(
        '<$_ns'
        r'c\b([^>]*?)(?:/>|>(.*?)</'
        '$_ns'
        r'c>)',
        dotAll: true,
      ).allMatches(row.group(1)!)) {
        final attributes = cell.group(1)!;
        final body = cell.group(2) ?? '';
        final reference = _attribute(attributes, 'r');
        if (reference == null) continue;
        final type = _attribute(attributes, 't');
        final value = RegExp(
          '<$_ns'
          r'v>(.*?)</'
          '$_ns'
          r'v>',
          dotAll: true,
        ).firstMatch(body)?.group(1);
        final String content;
        if (type == 's' && value != null) {
          content = shared[int.parse(value)];
        } else if (type == 'inlineStr') {
          content = [
            for (final t in RegExp(
              '<$_ns'
              r't(?:\s[^>]*)?>(.*?)</'
              '$_ns'
              r't>',
              dotAll: true,
            ).allMatches(body))
              _unescape(t.group(1)!),
          ].join();
        } else {
          content = value == null ? '' : _unescape(value);
        }
        cells[_column(reference)] = content;
      }
      if (cells.isEmpty) continue;
      final width = cells.keys.reduce((a, b) => a > b ? a : b) + 1;
      rows.add([for (var i = 0; i < width; i++) cells[i] ?? '']);
    }
    return rows;
  }

  /// Préfixe d'espace de noms facultatif (« x:sheet » comme « sheet »).
  static const _ns = r'(?:\w+:)?';

  static int _column(String reference) {
    var index = 0;
    for (final unit in reference.codeUnits) {
      if (unit < 65 || unit > 90) break;
      index = index * 26 + unit - 64;
    }
    return index - 1;
  }

  static String? _attribute(String attributes, String name) => RegExp(
    '(?:^|\\s)${RegExp.escape(name)}="([^"]*)"',
  ).firstMatch(attributes)?.group(1);

  static String _unescape(String value) => value
      .replaceAllMapped(
        RegExp(r'&#x([0-9a-fA-F]+);'),
        (m) => String.fromCharCode(int.parse(m.group(1)!, radix: 16)),
      )
      .replaceAllMapped(
        RegExp(r'&#(\d+);'),
        (m) => String.fromCharCode(int.parse(m.group(1)!)),
      )
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&apos;', "'")
      .replaceAll('&amp;', '&');

  /// Entrées d'un zip, depuis son répertoire central.
  static Map<String, Uint8List> _unzip(Uint8List bytes) {
    final data = ByteData.sublistView(bytes);
    var end = bytes.length - 22;
    while (end >= 0 && data.getUint32(end, Endian.little) != 0x06054b50) {
      end--;
    }
    if (end < 0) throw const FormatException('Zip illisible.');
    final count = data.getUint16(end + 10, Endian.little);
    var offset = data.getUint32(end + 16, Endian.little);
    final files = <String, Uint8List>{};
    for (var i = 0; i < count; i++) {
      if (data.getUint32(offset, Endian.little) != 0x02014b50) {
        throw const FormatException('Répertoire central illisible.');
      }
      final method = data.getUint16(offset + 10, Endian.little);
      final compressed = data.getUint32(offset + 20, Endian.little);
      final nameLength = data.getUint16(offset + 28, Endian.little);
      final extraLength = data.getUint16(offset + 30, Endian.little);
      final commentLength = data.getUint16(offset + 32, Endian.little);
      final local = data.getUint32(offset + 42, Endian.little);
      final name = utf8.decode(
        bytes.sublist(offset + 46, offset + 46 + nameLength),
      );
      final localName = data.getUint16(local + 26, Endian.little);
      final localExtra = data.getUint16(local + 28, Endian.little);
      final start = local + 30 + localName + localExtra;
      final raw = bytes.sublist(start, start + compressed);
      files[name] = switch (method) {
        0 => raw,
        8 => Uint8List.fromList(ZLibDecoder(raw: true).convert(raw)),
        _ => throw FormatException('Compression $method non gérée : $name'),
      };
      offset += 46 + nameLength + extraLength + commentLength;
    }
    return files;
  }
}
