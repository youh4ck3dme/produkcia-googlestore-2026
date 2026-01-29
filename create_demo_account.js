#!/usr/bin/env node
/**
 * Skript na vytvorenie demo účtu v Firebase Authentication
 * Spustenie: node create_demo_account.js
 * 
 * POZNÁMKA: Tento skript vyžaduje Firebase Admin SDK a service account key.
 * Pre jednoduchšie použitie použite manuálny postup v create_demo_account.sh
 */

const admin = require('firebase-admin');

const PROJECT_ID = 'bizagent-live-2026';
const DEMO_EMAIL = 'bizbizagent@bizbizagent.com';
const DEMO_PASSWORD = '1369#1369#1369#';

async function createDemoAccount() {
  console.log('🔐 Vytváranie demo účtu v Firebase');
  console.log('==================================\n');
  
  // Initialize Firebase Admin
  try {
    // Try to initialize with default credentials (if running on GCP or with GOOGLE_APPLICATION_CREDENTIALS)
    if (!admin.apps.length) {
      admin.initializeApp({
        projectId: PROJECT_ID,
      });
    }
  } catch (error) {
    console.error('❌ Chyba pri inicializácii Firebase Admin:');
    console.error('   ' + error.message);
    console.error('\n💡 Riešenie:');
    console.error('   1. Nastav premennú GOOGLE_APPLICATION_CREDENTIALS na cestu k service account JSON');
    console.error('   2. Alebo použite manuálny postup: ./create_demo_account.sh');
    process.exit(1);
  }

  try {
    // Check if user already exists
    let user;
    try {
      user = await admin.auth().getUserByEmail(DEMO_EMAIL);
      console.log(`⚠️  Účet ${DEMO_EMAIL} už existuje!`);
      console.log(`   UID: ${user.uid}`);
      console.log(`   Provider: ${user.providerData[0]?.providerId || 'unknown'}`);
      
      // Update password if needed
      await admin.auth().updateUser(user.uid, {
        password: DEMO_PASSWORD,
      });
      console.log('✅ Heslo bolo aktualizované');
      
      return;
    } catch (error) {
      if (error.code !== 'auth/user-not-found') {
        throw error;
      }
    }

    // Create new user
    console.log(`📧 Vytváram účet: ${DEMO_EMAIL}`);
    user = await admin.auth().createUser({
      email: DEMO_EMAIL,
      password: DEMO_PASSWORD,
      emailVerified: false, // Don't require email verification for demo account
      disabled: false,
    });

    console.log('✅ Účet úspešne vytvorený!');
    console.log(`   UID: ${user.uid}`);
    console.log(`   Email: ${user.email}`);
    console.log(`   Provider: ${user.providerData[0]?.providerId || 'password'}`);
    console.log('\n🎉 Hotovo! Demo účet je pripravený na použitie.');
    
  } catch (error) {
    console.error('❌ Chyba pri vytváraní účtu:');
    console.error('   ' + error.message);
    
    if (error.code === 'auth/email-already-exists') {
      console.error('\n💡 Účet už existuje. Skús aktualizovať heslo manuálne.');
    } else if (error.code === 'auth/invalid-email') {
      console.error('\n💡 Neplatný email formát.');
    } else if (error.code === 'auth/weak-password') {
      console.error('\n💡 Heslo je príliš slabé.');
    }
    
    process.exit(1);
  }
}

// Run
createDemoAccount()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error('Fatal error:', error);
    process.exit(1);
  });
