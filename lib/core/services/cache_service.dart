import 'package:universal_io/io.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as p;

class CacheService {
  static const String _versionKey = 'app_build_version';
  // Use a unique string to trigger cleanup.
  // We can also pull this from package_info if available, but manual is safer for "light" triggers.
  static const String _currentVersion = '1.0.1+2_clean_1';

  Future<void> performLightCleanup() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastVersion = prefs.getString(_versionKey);

      if (lastVersion != _currentVersion) {
        debugPrint(
            '🧹 [CACHE] Version mismatch detected ($lastVersion -> $_currentVersion). Starting light cleanup...');

        // 1. Clear Image Cache (Safe & helpful for UI consistency)
        PaintingBinding.instance.imageCache.clear();
        PaintingBinding.instance.imageCache.clearLiveImages();

        // 2. Platform specific cleanup
        if (!kIsWeb) {
          // Clear temporary directory (safe, OS can clear this too)
          final tempDir = await getTemporaryDirectory();
          await _clearDirectory(tempDir);

          // Clear old exports directory
          final docDir = await getApplicationDocumentsDirectory();
          final exportDir = Directory(p.join(docDir.path, 'exports'));
          if (await exportDir.exists()) {
            await _clearDirectory(exportDir);
          }
        } else {
          // On Web, tell the browser to check for service worker updates
          // This is handled via index.html scripts usually, but we can log here
          debugPrint(
              '🌐 [CACHE] Web environment detected. PWA service worker should handle asset cleanup.');
        }

        await prefs.setString(_versionKey, _currentVersion);
        debugPrint('✅ [CACHE] Light cleanup complete.');
      }
    } catch (e) {
      debugPrint('⚠️ [CACHE] Error during cleanup: $e');
    }
  }

  Future<void> fullReset() async {
    debugPrint('🚀 [CACHE] STARTING FULL RESET...');
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      debugPrint('✅ [CACHE] SharedPreferences cleared.');

      if (!kIsWeb) {
        final tempDir = await getTemporaryDirectory();
        await _clearDirectory(tempDir);
        
        final docDir = await getApplicationDocumentsDirectory();
        await _clearDirectory(docDir);
      } else {
        // On web, we can't easily clear IndexedDB from here without specific packages 
        // like 'drift' or 'hive'. But we can clear standard image cache.
        PaintingBinding.instance.imageCache.clear();
        debugPrint('✅ [CACHE] Web image cache cleared.');
      }
      debugPrint('🏁 [CACHE] FULL RESET COMPLETE.');
    } catch (e) {
      debugPrint('❌ [CACHE] Full reset failed: $e');
    }
  }

  Future<void> _clearDirectory(Directory dir) async {
    try {
      if (await dir.exists()) {
        final entities = await dir.list().toList();
        for (final entity in entities) {
          try {
            if (entity is File) {
              await entity.delete();
            } else if (entity is Directory) {
              await entity.delete(recursive: true);
            }
          } catch (e) {
            // Ignore individual file errors (file might be in use)
            debugPrint('⚠️ [CACHE] Skipping ${entity.path}: $e');
          }
        }
      }
    } catch (e) {
      debugPrint('⚠️ [CACHE] Failed to clear directory ${dir.path}: $e');
    }
  }
}
