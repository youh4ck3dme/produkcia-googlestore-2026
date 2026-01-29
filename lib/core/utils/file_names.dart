// lib/core/utils/file_names.dart
class FileNames {
  static String safe(String name) {
    // remove risky chars for file systems
    return name
        .replaceAll(RegExp(r'[<>:"/\\|?*\n\r\t]'), '_')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
