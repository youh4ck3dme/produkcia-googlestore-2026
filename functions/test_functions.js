#!/usr/bin/env node
/**
 * Firebase Functions smoke test — bez live volaní (nevyžaduje credentials).
 * Canonical account deletion: Supabase edge function `delete-account`.
 */

const fs = require('fs');
const path = require('path');

const INDEX = path.join(__dirname, 'index.js');
const LEGACY_EXPORTS = [
  'generateEmail',
  'analyzeReceipt',
  'lookupCompany',
  'generateContent',
  'deleteUserData',
];

function fail(msg) {
  console.error(`❌ ${msg}`);
  process.exit(1);
}

function pass(msg) {
  console.log(`✅ ${msg}`);
}

console.log('🧪 Firebase Functions smoke test');
console.log('='.repeat(60));

if (!fs.existsSync(INDEX)) {
  fail(`Missing ${INDEX}`);
}

const src = fs.readFileSync(INDEX, 'utf8');

for (const name of LEGACY_EXPORTS) {
  const pattern = new RegExp(`exports\\.${name}\\s*=`);
  if (!pattern.test(src)) {
    fail(`Missing export: ${name}`);
  }
  pass(`export present: ${name}`);
}

if (!src.includes('deleteUserData')) {
  fail('Legacy deleteUserData not found — document migration to Supabase delete-account');
}

console.log('');
console.log('ℹ️  Legacy Firebase deleteUserData — use Supabase functions/delete-account for Play/GDPR.');
console.log('ℹ️  Live callable tests: firebase emulators:exec or manual from authenticated app.');
console.log('');
console.log('='.repeat(60));
console.log('📊 SUMMARY: all smoke checks passed');
process.exit(0);