const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { GoogleGenerativeAI } = require("@google/generative-ai");
const { defineString } = require("firebase-functions/params");

const geminiApiKey = defineString("GEMINI_API_KEY");
const icoAtlasApiKey = defineString("ICOATLAS_API_KEY");

// Model configuration
// Updated to use currently supported models (January 2026)
const MODEL_PRIORITY = ["gemini-1.5-flash", "gemini-1.5-pro", "gemini-2.0-flash"];
const DEFAULT_MODEL = "gemini-1.5-flash";

/**
 * Generuje profesionálny e-mail na základe kontextu.
 */
exports.generateEmail = onCall({ 
  cors: [
    "https://biz-agent-web.vercel.app",
    "https://bizagent-live-2026.web.app",
    "http://localhost:3000",
    "http://localhost:62262"
  ]
}, async (request) => {
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'Funkcia musí byť volaná prihláseným používateľom.');
  }

  const { type, tone, context } = request.data;
  if (!context) {
    throw new HttpsError('invalid-argument', 'Chýba parameter "context".');
  }

  const apiKey = geminiApiKey.value();
  if (!apiKey) {
    throw new HttpsError('failed-precondition', 'Server nie je správne nakonfigurovaný (chýba API kľúč).');
  }

  try {
    const genAI = new GoogleGenerativeAI(apiKey);
    const model = genAI.getGenerativeModel({ 
      model: DEFAULT_MODEL,
      systemInstruction: "Si profesionálny biznis asistent pre slovenských podnikateľov. Tvojou úlohou je písať e-maily, ktoré sú gramaticky správne, slušné a vecne presné podľa zadaného kontextu. Používaj spisovnú slovenčinu a profesionálne formátovanie."
    });

    const prompt = `Napíš ${type} e-mail v ${tone} tóne. Kontext: ${context}`;
    
    const result = await model.generateContent(prompt);
    return { text: result.response.text() };

  } catch (error) {
    console.error("Gemini Email Error:", error);
    if (error.status === 403 || error.message.includes('API key')) {
      throw new HttpsError('permission-denied', 'Neplatný API kľúč pre AI službu.');
    }
    throw new HttpsError('internal', 'Chyba pri generovaní e-mailu: ' + error.message);
  }
});

/**
 * Parsuje text z bločku pomocou AI pre presnejšie dáta.
 */
exports.analyzeReceipt = onCall({ 
  cors: [
    "https://biz-agent-web.vercel.app",
    "https://bizagent-live-2026.web.app",
    "http://localhost:3000",
    "http://localhost:62262"
  ]
}, async (request) => {
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'Prístup odmietnutý.');
  }

  const { text } = request.data;
  if (!text) {
    throw new HttpsError('invalid-argument', 'Chýba text na analýzu.');
  }

  const apiKey = geminiApiKey.value();
  if (!apiKey) {
    throw new HttpsError('failed-precondition', 'Server nie je správne nakonfigurovaný.');
  }

  try {
    const genAI = new GoogleGenerativeAI(apiKey);
    const model = genAI.getGenerativeModel({ 
      model: DEFAULT_MODEL,
      systemInstruction: `Si expert na analýzu slovenských pokladničných dokladov. 
      Z extrahovaného textu vytiahni údaje do čistého JSONu v tejto štruktúre:
      {
        "vendor_name": "Názov obchodu",
        "ico": "XXXXXXXX (ak existuje)",
        "date": "YYYY-MM-DD",
        "total": 0.0,
        "currency": "EUR",
        "address": {
          "street": "Ulica",
          "street_number": "Číslo",
          "psc": "PSČ",
          "city": "Mesto"
        },
        "confidence": 0.9 (odhad istoty)
      }
      Ak údaj nevieš nájsť, nechaj ho null.`
    });

    const result = await model.generateContent(`Analyzuj text:\n\n${text}`);
    const jsonString = result.response.text().replace(/```json|```/g, '').trim();
    
    return JSON.parse(jsonString);
  } catch (error) {
    console.error("Gemini Receipt Error:", error);
    throw new HttpsError('internal', 'Chyba pri analýze dokladu: ' + error.message);
  }
});

/**
 * Hľadá firmu podľa IČO.
 * Používa IcoAtlas.sk API s proxy cez server-side kľúčom.
 */
exports.lookupCompany = onCall({
  cors: [
    "https://biz-agent-web.vercel.app",
    "https://bizagent-live-2026.web.app",
    "http://localhost:3000",
    "http://localhost:62262"
  ]
}, async (request) => {
  // Allow unauthenticated for onboarding flow (strictly rate limited in prod)
  // For now, allow it to speed up "Magic Setup"

  const { ico } = request.data;
  if (!ico) {
    throw new HttpsError('invalid-argument', 'Chýba IČO.');
  }

  // Pad ICO to 8 digits if numeric
  const paddedIco = ico.padStart(8, '0');

  // 1. Try Mock Data (For Demo "Wow" Effect without API Key)
  const MOCK_DB = {
    '36396567': { // Google Slovakia
      name: 'Google Slovakia, s. r. o.',
      ico: '36396567',
      dic: '2020102636',
      icDph: 'SK2020102636',
      address: 'Karadžičova 8/A, Bratislava 821 08'
    },
    '35757442': { // O2 Slovakia
      name: 'O2 Slovakia, s.r.o.',
      ico: '35757442',
      dic: '2020216748',
      icDph: 'SK2020216748',
      address: 'Einsteinova 24, Bratislava 851 01'
    },
    '46113177': { // SkyToll
      name: 'SkyToll, a. s.',
      ico: '46113177',
      dic: '2023247964',
      icDph: 'SK2023247964',
      address: 'Lamačská cesta 3/B, Bratislava 841 04'
    }
  };

  const apiKey = icoAtlasApiKey.value();

  // Ak nemáme kľúč alebo je to známe testovacie IČO, vráť mock
  if (!apiKey || MOCK_DB[ico]) {
    console.log("Using Mock/Fallback for IČO:", ico);
    if (MOCK_DB[ico]) return MOCK_DB[ico];

    // Ak nemáme kľúč a nie je v mocku:
    if (!apiKey) {
       return null;
    }
  }

  // 2. Real API Call (IcoAtlas.sk)
  try {
    const response = await fetch(`https://icoatlas.sk/api/company/${paddedIco}`, {
      headers: {
        'X-Api-Key': apiKey,
        'Content-Type': 'application/json'
      }
    });

    if (response.status === 404) {
      console.log("Endpoint mismatch for IČO:", ico);
      return null;
    }

    if (response.status === 401 || response.status === 403) {
      console.error("Missing or invalid API key for IcoAtlas");
      throw new HttpsError('failed-precondition', 'Server nie je správne nakonfigurovaný (chýba alebo neplatný API kľúč pre IcoAtlas).');
    }

    if (!response.ok) {
       console.error("IcoAtlas API Error:", response.status, await response.text());
       return null;
    }

    const data = await response.json();
    if (!data) return null;

    // Map to our simplified format
    return {
      name: data.name || '',
      ico: data.ico || ico,
      dic: data.dic || '',
      icDph: data.ic_dph || '',
      address: data.address || ''
    };

  } catch (error) {
    console.error("Lookup Error:", error);
    throw new HttpsError('internal', 'Chyba pri hľadaní firmy.');
  }
});

/**
 * Univerzálna Gemini funkcia pre všeobecné AI volania (BizBot, analýzy, atď.)
 * Bezpečne volá Gemini API na serveri s tajným kľúčom.
 */
exports.generateContent = onCall({
  cors: [
    "https://biz-agent-web.vercel.app",
    "https://bizagent-live-2026.web.app",
    "http://localhost:3000",
    "http://localhost:62262"
  ]
}, async (request) => {
  // Allow unauthenticated for demo/onboarding, but rate limit in production
  // For production, consider requiring auth: if (!request.auth) { throw new HttpsError('unauthenticated', '...'); }

  const { prompt, model } = request.data;
  if (!prompt) {
    throw new HttpsError('invalid-argument', 'Chýba parameter "prompt".');
  }

  const apiKey = geminiApiKey.value();
  if (!apiKey) {
    throw new HttpsError('failed-precondition', 'Server nie je správne nakonfigurovaný (chýba API kľúč).');
  }

  // Model priority fallback
  const requestedModel = model || DEFAULT_MODEL;
  const modelsToTry = [requestedModel, ...MODEL_PRIORITY.filter(m => m !== requestedModel)];

  let lastError = null;
  for (const modelName of modelsToTry) {
    try {
      const genAI = new GoogleGenerativeAI(apiKey);
      const geminiModel = genAI.getGenerativeModel({ 
        model: modelName,
        systemInstruction: "Si expert na slovenské účtovníctvo a biznis asistenciu. Odpovedaj v slovenčine, buď presný a profesionálny."
      });

      const result = await geminiModel.generateContent(prompt);
      return { 
        text: result.response.text(),
        model: modelName
      };

    } catch (error) {
      console.error(`Gemini ${modelName} Error:`, error);
      lastError = error;
      
      if (error.status === 403 || error.message?.includes('API key')) {
        throw new HttpsError('permission-denied', 'Neplatný API kľúč pre AI službu.');
      }
      
      if (error.message?.includes('quota') || error.status === 429) {
        throw new HttpsError('resource-exhausted', 'Dosiahli ste limit bezplatných dopytov. Skúste to neskôr.');
      }

      // Try next model (continue loop)
      continue;
    }
  }

  // All models failed
  throw new HttpsError('internal', `AI Offline: Nepodarilo sa pripojiť k žiadnemu AI modelu. ${lastError?.message || 'Skúste to neskôr.'}`);
});
