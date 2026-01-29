// ============================================
// TEST GEMINI CLOUD FUNCTION - BROWSER CONSOLE
// ============================================
// Skopírujte tento kód a vložte ho do konzoly prehliadača
// na stránke: https://biz-agent-web.vercel.app
// ============================================

(async function testGeminiCloudFunction() {
  console.log('🧪 Test Gemini Cloud Function');
  console.log('============================');
  console.log('');

  try {
    // Import Firebase Functions (ak nie je dostupný)
    if (typeof firebase === 'undefined') {
      console.error('❌ Firebase nie je načítaný!');
      console.log('Skontrolujte, či je Firebase správne inicializovaný.');
      return;
    }

    const functions = firebase.functions();
    const generateContent = functions.httpsCallable('generateContent');

    const testPrompt = 'Napíš krátku odpoveď v slovenčine: Čo je BizAgent?';
    
    console.log('💬 Prompt:', testPrompt);
    console.log('📡 Volanie Cloud Function...');
    console.log('');

    const startTime = Date.now();
    
    const result = await generateContent({
      prompt: testPrompt,
      model: 'gemini-1.5-flash'
    });

    const duration = Date.now() - startTime;

    console.log('✅ ÚSPECH!');
    console.log('');
    console.log('📊 Štatistiky:');
    console.log(`   Čas: ${duration}ms`);
    console.log(`   Model: ${result.data.model || 'N/A'}`);
    console.log('');
    console.log('📝 Odpoveď:');
    console.log(result.data.text);
    console.log('');
    console.log('📋 Kompletná odpoveď:');
    console.log(JSON.stringify(result.data, null, 2));

    return result.data.text;

  } catch (error) {
    console.error('❌ CHYBA');
    console.log('');
    
    if (error.code === 'unauthenticated') {
      console.error('⚠️  Chyba autentifikácie');
      console.log('   Funkcia vyžaduje prihlásenie.');
      console.log('   Skúste sa prihlásiť do aplikácie.');
    } else if (error.code === 'permission-denied') {
      console.error('⚠️  Prístup odmietnutý');
      console.log('   Skontrolujte CORS nastavenia alebo autentifikáciu.');
    } else if (error.code === 'failed-precondition') {
      console.error('⚠️  Server nie je správne nakonfigurovaný');
      console.log('   API kľúč nie je nastavený v Cloud Functions.');
      console.log('   Spustite: firebase functions:secrets:set GEMINI_API_KEY');
    } else if (error.code === 'resource-exhausted') {
      console.error('⚠️  Dosiahnutý limit');
      console.log('   Dosiahli ste limit bezplatných dopytov.');
      console.log('   Skúste to neskôr.');
    } else {
      console.error('⚠️  Neočakávaná chyba');
      console.log('   Kód:', error.code);
      console.log('   Správa:', error.message);
      console.log('');
      console.log('Kompletná chyba:');
      console.error(error);
    }

    return null;
  }
})();

// ============================================
// ALTERNATÍVNY TEST - PRIAMY HTTP VOLANIE
// ============================================

async function testGeminiDirectHTTP() {
  console.log('🧪 Test Gemini Cloud Function (HTTP)');
  console.log('====================================');
  console.log('');

  const url = 'https://us-central1-bizagent-live-2026.cloudfunctions.net/generateContent';
  const testData = {
    data: {
      prompt: 'Napíš krátku odpoveď v slovenčine: Čo je BizAgent?',
      model: 'gemini-1.5-flash'
    }
  };

  try {
    const response = await fetch(url, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(testData)
    });

    const result = await response.json();

    console.log('📊 Status:', response.status);
    console.log('');

    if (response.ok) {
      console.log('✅ ÚSPECH!');
      console.log('');
      console.log('📝 Odpoveď:');
      console.log(result.result?.text || result.text || JSON.stringify(result, null, 2));
    } else {
      console.log('❌ CHYBA');
      console.log('');
      console.log('Chybová správa:');
      console.log(result.error?.message || result.message || JSON.stringify(result, null, 2));
    }

    return result;

  } catch (error) {
    console.error('❌ CHYBA PRI VOLANÍ');
    console.log('');
    console.error(error);
    return null;
  }
}

// Spustenie: testGeminiDirectHTTP()
