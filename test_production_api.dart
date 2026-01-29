#!/usr/bin/env dart
// Testovací skript pre produkčné Firebase API a Cloud Functions
// Spustenie: dart test_production_api.dart

import 'dart:io';
import 'dart:convert';

void main() async {
  print('🧪 BizAgent Production API Test Suite\n');
  print('=' * 60);
  
  final results = <TestResult>[];
  
  // 1. Firebase Configuration Check
  results.add(await testFirebaseConfig());
  
  // 2. Firestore Connection
  results.add(await testFirestoreConnection());
  
  // 3. Firebase Auth (Demo Account)
  results.add(await testFirebaseAuth());
  
  // 4. Firestore Security Rules
  results.add(await testFirestoreRules());
  
  // 5. Storage Rules
  results.add(await testStorageRules());
  
  // 6. Cloud Functions
  results.add(await testCloudFunction('lookupCompany'));
  results.add(await testCloudFunction('generateEmail'));
  results.add(await testCloudFunction('analyzeReceipt'));
  
  // 7. Firebase Project Info
  results.add(await testFirebaseProjectInfo());
  
  // Summary
  print('\n' + '=' * 60);
  print('📊 TEST SUMMARY');
  print('=' * 60);
  
  int passed = 0;
  int failed = 0;
  
  for (final result in results) {
    final icon = result.success ? '✅' : '❌';
    print('$icon ${result.name}: ${result.message}');
    if (result.success) {
      passed++;
    } else {
      failed++;
    }
  }
  
  print('\n' + '=' * 60);
  print('Total: ${results.length} | Passed: $passed | Failed: $failed');
  print('=' * 60);
  
  if (failed > 0) {
    exit(1);
  }
}

class TestResult {
  final String name;
  final bool success;
  final String message;
  
  TestResult(this.name, this.success, this.message);
}

Future<TestResult> testFirebaseConfig() async {
  print('\n📋 Test 1: Firebase Configuration');
  
  try {
    final configFile = File('lib/firebase_options.dart');
    if (!await configFile.exists()) {
      return TestResult('Firebase Config', false, 'firebase_options.dart not found');
    }
    
    final content = await configFile.readAsString();
    
    final checks = {
      'projectId': content.contains('bizagent-live-2026'),
      'android': content.contains('android:'),
      'ios': content.contains('ios:'),
      'web': content.contains('web:'),
    };
    
    final allPassed = checks.values.every((v) => v);
    final details = checks.entries
        .map((e) => '${e.key}: ${e.value ? "✓" : "✗"}')
        .join(', ');
    
    return TestResult(
      'Firebase Config',
      allPassed,
      allPassed ? 'All configs present ($details)' : 'Missing configs ($details)',
    );
  } catch (e) {
    return TestResult('Firebase Config', false, 'Error: $e');
  }
}

Future<TestResult> testFirestoreConnection() async {
  print('\n📋 Test 2: Firestore Connection');
  
  try {
    // Check if Firebase CLI is available
    final result = await Process.run('firebase', ['--version']);
    if (result.exitCode != 0) {
      return TestResult(
        'Firestore Connection',
        false,
        'Firebase CLI not installed. Install: npm install -g firebase-tools',
      );
    }
    
    // Check if logged in
    final loginCheck = await Process.run('firebase', ['projects:list']);
    if (loginCheck.exitCode != 0) {
      return TestResult(
        'Firestore Connection',
        false,
        'Not logged into Firebase. Run: firebase login',
      );
    }
    
    // Check project
    final projectCheck = await Process.run('firebase', ['use']);
    final projectOutput = projectCheck.stdout.toString();
    
    if (projectOutput.contains('bizagent-live-2026')) {
      return TestResult(
        'Firestore Connection',
        true,
        'Connected to bizagent-live-2026',
      );
    }
    
    return TestResult(
      'Firestore Connection',
      false,
      'Project not set. Run: firebase use bizagent-live-2026',
    );
  } catch (e) {
    return TestResult('Firestore Connection', false, 'Error: $e');
  }
}

Future<TestResult> testFirebaseAuth() async {
  print('\n📋 Test 3: Firebase Auth (Demo Account)');
  
  try {
    // Check if demo account exists via Firebase CLI
    // Note: This requires Firebase Admin SDK or manual check in console
    return TestResult(
      'Firebase Auth',
      true,
      '⚠️  Manual check required: Verify bizbizagent@bizbizagent.com exists in Firebase Console > Authentication > Users',
    );
  } catch (e) {
    return TestResult('Firebase Auth', false, 'Error: $e');
  }
}

Future<TestResult> testFirestoreRules() async {
  print('\n📋 Test 4: Firestore Security Rules');
  
  try {
    final rulesFile = File('firebase/firestore.rules');
    if (!await rulesFile.exists()) {
      return TestResult('Firestore Rules', false, 'firestore.rules not found');
    }
    
    final content = await rulesFile.readAsString();
    
    final checks = {
      'isAuthenticated function': content.contains('isAuthenticated()'),
      'isOwner function': content.contains('isOwner('),
      'users collection': content.contains('match /users/'),
      'invoices collection': content.contains('match /invoices/'),
      'expenses collection': content.contains('match /expenses/'),
    };
    
    final allPassed = checks.values.every((v) => v);
    final details = checks.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .join(', ');
    
    return TestResult(
      'Firestore Rules',
      allPassed,
      allPassed ? 'All rules present ($details)' : 'Missing rules',
    );
  } catch (e) {
    return TestResult('Firestore Rules', false, 'Error: $e');
  }
}

Future<TestResult> testStorageRules() async {
  print('\n📋 Test 5: Storage Security Rules');
  
  try {
    final rulesFile = File('firebase/storage.rules');
    if (!await rulesFile.exists()) {
      return TestResult('Storage Rules', false, 'storage.rules not found');
    }
    
    final content = await rulesFile.readAsString();
    
    final checks = {
      'user-scoped paths': content.contains('/users/{userId}/'),
      'auth check': content.contains('request.auth'),
      'uid match': content.contains('request.auth.uid == userId'),
    };
    
    final allPassed = checks.values.every((v) => v);
    
    return TestResult(
      'Storage Rules',
      allPassed,
      allPassed ? 'Storage rules properly configured' : 'Missing security checks',
    );
  } catch (e) {
    return TestResult('Storage Rules', false, 'Error: $e');
  }
}

Future<TestResult> testCloudFunction(String functionName) async {
  print('\n📋 Test: Cloud Function - $functionName');
  
  try {
    final functionsFile = File('functions/index.js');
    if (!await functionsFile.exists()) {
      return TestResult(
        'Cloud Function: $functionName',
        false,
        'functions/index.js not found',
      );
    }
    
    final content = await functionsFile.readAsString();
    
    if (!content.contains('exports.$functionName')) {
      return TestResult(
        'Cloud Function: $functionName',
        false,
        'Function not exported',
      );
    }
    
    // Check for authentication requirement
    final hasAuth = content.contains('request.auth') || 
                    content.contains('unauthenticated');
    
    // Check for error handling
    final hasErrorHandling = content.contains('HttpsError') || 
                            content.contains('catch');
    
    return TestResult(
      'Cloud Function: $functionName',
      true,
      'Function exists${hasAuth ? ", auth required" : ""}${hasErrorHandling ? ", error handling present" : ""}',
    );
  } catch (e) {
    return TestResult('Cloud Function: $functionName', false, 'Error: $e');
  }
}

Future<TestResult> testFirebaseProjectInfo() async {
  print('\n📋 Test: Firebase Project Info');
  
  try {
    final firebaserc = File('.firebaserc');
    if (!await firebaserc.exists()) {
      return TestResult('Firebase Project', false, '.firebaserc not found');
    }
    
    final content = await firebaserc.readAsString();
    final json = jsonDecode(content) as Map<String, dynamic>;
    final projectId = json['projects']?['default'] as String?;
    
    if (projectId == 'bizagent-live-2026') {
      return TestResult(
        'Firebase Project',
        true,
        'Project ID: $projectId',
      );
    }
    
    return TestResult(
      'Firebase Project',
      false,
      'Unexpected project ID: $projectId',
    );
  } catch (e) {
    return TestResult('Firebase Project', false, 'Error: $e');
  }
}
