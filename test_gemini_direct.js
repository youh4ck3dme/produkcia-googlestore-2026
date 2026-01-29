// Priamy test Gemini API cez Cloud Functions
// Spustiť: node test_gemini_direct.js

const https = require('https');

const PROJECT_ID = 'bizagent-live-2026';
const FUNCTION_NAME = 'generateContent';
const FUNCTION_URL = `https://us-central1-${PROJECT_ID}.cloudfunctions.net/${FUNCTION_NAME}`;

const testPrompt = 'Napíš krátku odpoveď v slovenčine: Čo je BizAgent?';

const testData = JSON.stringify({
  data: {
    prompt: testPrompt,
    model: 'gemini-1.5-flash'
  }
});

console.log('🧪 Test Gemini Cloud Function');
console.log('============================');
console.log('');
console.log(`📋 Projekt: ${PROJECT_ID}`);
console.log(`🔗 URL: ${FUNCTION_URL}`);
console.log(`💬 Prompt: "${testPrompt}"`);
console.log('');

const options = {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Content-Length': Buffer.byteLength(testData)
  }
};

const req = https.request(FUNCTION_URL, options, (res) => {
  let data = '';

  res.on('data', (chunk) => {
    data += chunk;
  });

  res.on('end', () => {
    console.log(`📊 Status: ${res.statusCode}`);
    console.log('');

    if (res.statusCode === 200) {
      try {
        const result = JSON.parse(data);
        console.log('✅ ÚSPECH!');
        console.log('');
        console.log('📝 Odpoveď:');
        console.log(result.result?.text || result.text || data);
      } catch (e) {
        console.log('⚠️  Neočakávaný formát odpovede:');
        console.log(data);
      }
    } else {
      console.log('❌ CHYBA');
      console.log('');
      try {
        const error = JSON.parse(data);
        console.log('Chybová správa:');
        console.log(error.error?.message || error.message || data);
      } catch (e) {
        console.log('Odpoveď:');
        console.log(data);
      }
    }
  });
});

req.on('error', (error) => {
  console.log('❌ CHYBA PRI VOLANÍ');
  console.log('');
  console.error(error.message);
});

req.write(testData);
req.end();
