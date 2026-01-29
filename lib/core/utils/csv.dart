// lib/core/utils/csv.dart
class Csv {
  static String encodeRow(List<String> cols) {
    return '${cols.map(_escape).join(',')}\n';
  }

  static String encode(List<List<String>> rows) {
    final sb = StringBuffer();
    for (final r in rows) {
      sb.write(encodeRow(r));
    }
    return sb.toString();
  }

  static String _escape(String v) {
    final needsQuotes = v.contains(',') ||
        v.contains('"') ||
        v.contains('\n') ||
        v.contains('\r');
    var s = v.replaceAll('"', '""');
    if (needsQuotes) s = '"$s"';
    return s;
  }
}
