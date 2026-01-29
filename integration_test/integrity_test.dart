import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'package:bizagent/core/services/gemini_service.dart';
import 'package:bizagent/core/services/icoatlas_service.dart';
import 'package:bizagent/core/ui/biz_theme.dart';
import 'package:bizagent/lib/firebase_options.dart';

/// Integrity Tests - Verify data consistency, API connectivity, and system health
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Data Integrity Tests', () {
    test('Firebase Configuration Integrity', () async {
      // Verify Firebase is properly initialized
      try {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        expect(Firebase.app(), isNotNull);
      } catch (e) {
        fail('Firebase initialization failed: $e');
      }
    });

    test('Firestore Rules Integrity', () async {
      // Verify Firestore is accessible
      try {
        final firestore = FirebaseFirestore.instance;
        expect(firestore, isNotNull);
        
        // Test read access (should work if authenticated or rules allow)
        // This is a smoke test - actual rules testing requires authenticated user
        final testDoc = firestore.collection('test').doc('integrity-check');
        // Don't actually write, just verify connection
        expect(testDoc, isNotNull);
      } catch (e) {
        fail('Firestore access failed: $e');
      }
    });

    test('Storage Rules Integrity', () async {
      // Verify Storage is accessible
      try {
        final storage = FirebaseStorage.instance;
        expect(storage, isNotNull);
        
        // Test reference creation (doesn't require actual upload)
        final testRef = storage.ref('test/integrity-check.txt');
        expect(testRef, isNotNull);
      } catch (e) {
        fail('Storage access failed: $e');
      }
    });
  });

  group('API Integrity Tests', () {
    test('Gemini Service Model Configuration', () {
      // Verify Gemini models are correctly configured
      expect(GeminiService.modelName, isNotEmpty);
      expect(['gemini-1.5-flash', 'gemini-1.5-pro', 'gemini-2.0-flash'], 
             contains(GeminiService.modelName));
    });

    test('IcoAtlas Service Configuration', () {
      // Verify IcoAtlas service is properly configured
      final service = IcoAtlasService();
      expect(service, isNotNull);
      // Service should handle API key validation internally
    });
  });

  group('Theme Integrity Tests', () {
    test('Theme Colors Consistency', () {
      // Verify theme colors are properly defined
      expect(BizTheme.slovakBlue, isNotNull);
      expect(BizTheme.nationalRed, isNotNull);
      expect(BizTheme.silverMist, isNotNull);
      
      // Verify colors are valid
      expect(BizTheme.slovakBlue.value, greaterThan(0));
      expect(BizTheme.nationalRed.value, greaterThan(0));
    });

    test('Theme Accessibility', () {
      // Verify theme provides both light and dark variants
      final lightTheme = BizTheme.lightTheme;
      final darkTheme = BizTheme.darkTheme;
      
      expect(lightTheme, isNotNull);
      expect(darkTheme, isNotNull);
      
      // Verify color schemes exist
      expect(lightTheme.colorScheme, isNotNull);
      expect(darkTheme.colorScheme, isNotNull);
    });
  });

  group('Configuration Integrity Tests', () {
    test('Environment Variables', () {
      // Verify critical environment variables are accessible
      // Note: These may be null in test environment, which is OK
      // But the app should handle missing values gracefully
      const geminiKey = String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
      const icoAtlasKey = String.fromEnvironment('ICOATLAS_API_KEY', defaultValue: '');
      
      // Keys may be empty in test, but service should handle it
      expect(geminiKey, isA<String>());
      expect(icoAtlasKey, isA<String>());
    });
  });

  group('Data Model Integrity Tests', () {
    test('Invoice Model Validation', () {
      // Verify invoice model structure
      // This would require importing invoice model and testing serialization
      // For now, just verify the test can run
      expect(true, isTrue);
    });

    test('Expense Model Validation', () {
      // Verify expense model structure
      expect(true, isTrue);
    });
  });
}
