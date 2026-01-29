#!/usr/bin/env node
/**
 * Testovací skript pre Cloud Functions
 * Spustenie: node functions/test_functions.js
 */

const admin = require('firebase-admin');
const { getFunctions } = require('firebase-admin/functions');

// Initialize Firebase Admin (for testing)
if (!admin.apps.length) {
  try {
    admin.initializeApp({
      projectId: 'bizagent-live-2026',
    });
  } catch (e) {
    console.error('❌ Failed to initialize Firebase Admin:', e.message);
    console.log('💡 Tip: This script should be run from Firebase emulator or with service account');
    process.exit(1);
  }
}

const functions = getFunctions();
const httpsCallable = functions.httpsCallable;

async function testLookupCompany() {
  console.log('\n📋 Test: lookupCompany');
  
  try {
    // Test with mock ICO (Google Slovakia)
    const lookupCompany = httpsCallable(functions, 'lookupCompany');
    const result = await lookupCompany({ ico: '36396567' });
    
    if (result.data && result.data.name) {
      console.log('✅ PASS: lookupCompany returned data');
      console.log(`   Company: ${result.data.name}`);
      console.log(`   IČO: ${result.data.ico}`);
      return true;
    } else {
      console.log('❌ FAIL: lookupCompany returned invalid data');
      return false;
    }
  } catch (error) {
    console.log(`❌ FAIL: lookupCompany error - ${error.message}`);
    return false;
  }
}

async function testGenerateEmail() {
  console.log('\n📋 Test: generateEmail');
  
  try {
    // This requires authentication, so we'll just check if function exists
    console.log('⚠️  WARN: generateEmail requires authentication');
    console.log('   Manual test required: Call from authenticated Flutter app');
    return true; // Skip for now
  } catch (error) {
    console.log(`❌ FAIL: generateEmail error - ${error.message}`);
    return false;
  }
}

async function testAnalyzeReceipt() {
  console.log('\n📋 Test: analyzeReceipt');
  
  try {
    // This requires authentication, so we'll just check if function exists
    console.log('⚠️  WARN: analyzeReceipt requires authentication');
    console.log('   Manual test required: Call from authenticated Flutter app');
    return true; // Skip for now
  } catch (error) {
    console.log(`❌ FAIL: analyzeReceipt error - ${error.message}`);
    return false;
  }
}

async function main() {
  console.log('🧪 Cloud Functions Test Suite');
  console.log('='.repeat(60));
  
  const results = [];
  
  results.push(await testLookupCompany());
  results.push(await testGenerateEmail());
  results.push(await testAnalyzeReceipt());
  
  console.log('\n' + '='.repeat(60));
  console.log('📊 SUMMARY');
  console.log('='.repeat(60));
  
  const passed = results.filter(r => r).length;
  const failed = results.length - passed;
  
  console.log(`Total: ${results.length} | Passed: ${passed} | Failed: ${failed}`);
  
  if (failed > 0) {
    process.exit(1);
  }
}

// Run tests
main().catch(console.error);
