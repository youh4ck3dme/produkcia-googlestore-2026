const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { GoogleGenAI } = require("@google/genai");
const { defineString } = require("firebase-functions/params");

const geminiApiKey = defineString("GEMINI_API_KEY");
const icoAtlasApiKey = defineString("ICOATLAS_API_KEY");

// Model configuration
// Updated to use currently supported models (January 2026)
//
// NOTE (runtime evidence from Firebase logs):
// The legacy @google/generative-ai SDK uses the v1beta endpoint and can return 404 for models.
// We use the Google Gen AI SDK (@google/genai) which supports API version v1.
const MODEL_PRIORITY = ["gemini-2.0-flash", "gemini-1.5-flash"];
const DEFAULT_MODEL = "gemini-2.0-flash";

/**
 * Generuje profesionálny e-mail na základe kontextu.
 */
exports.generateEmail = onCall({ 
  cors: [
    "https://biz-agent-web.vercel.app",
    "https://bizagent-live-2026.web.app",
    "http://localhost:3000",
    "http://localhost:5050",
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
    const prompt = `Napíš ${type} e-mail v ${tone} tóne. Kontext: ${context}`;
    const ai = new GoogleGenAI({ vertexai: false, apiKey });
    const response = await ai.models.generateContent({
      model: DEFAULT_MODEL,
      contents: prompt,
    });
    return { text: response.text || "AI nevrátilo žiadny text." };

  } catch (error) {
    console.error("Gemini Email Error:", error);
    if (error.status === 403 || String(error.message || '').includes('API key')) {
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
    "http://localhost:5050",
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
    const ai = new GoogleGenAI({ vertexai: false, apiKey });
    const receiptPrompt = `Si expert na analýzu slovenských pokladničných dokladov.
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
  "confidence": 0.9
}
Ak údaj nevieš nájsť, nechaj ho null.

Analyzuj text:
${text}`;

    const response = await ai.models.generateContent({
      model: DEFAULT_MODEL,
      contents: receiptPrompt,
    });
    const rawText = response.text || '';
    const jsonString = rawText.replace(/```json|```/g, '').trim();
    
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
    "http://localhost:5050",
    "http://localhost:62262"
  ]
}, async (request) => {
  // Allow unauthenticated for onboarding flow (strictly rate limited in prod)
  // For now, allow it to speed up "Magic Setup"

  const { ico, full } = request.data;
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
    if (MOCK_DB[ico]) {
      const mock = MOCK_DB[ico];
      // Ensure consistent shape for premium/full payload requests.
      if (full === true) {
        return {
          ok: true,
          data: {
            ico: mock.ico,
            name: mock.name,
            dic: mock.dic,
            ic_dph: mock.icDph,
            address: mock.address,
          },
          related: [],
          meta: { mocked: true },
          message: 'MOCK',
        };
      }
      return mock;
    }

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

    const payload = await response.json();
    if (!payload) return null;

    // Expected response shape:
    // { message: string, data: object|null, related: [], meta: {...} }
    const company = payload.data;
    if (!company || typeof company !== 'object') return null;

    // Premium/full payload (closest to icoatlas.sk)
    if (full === true) {
      return {
        ok: true,
        data: company,
        related: Array.isArray(payload.related) ? payload.related : [],
        meta: payload.meta && typeof payload.meta === 'object' ? payload.meta : {},
        message: payload.message || 'OK',
      };
    }

    // Basic payload (keep backward compatibility + simple UI)
    return {
      name: company.name || '',
      ico: company.ico || ico,
      dic: company.dic || '',
      icDph: company.ic_dph || '',
      address: company.address || '',
      city: company.city || '',
      zip: company.zip || '',
      status: company.status || '',
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
    "http://localhost:5050",
    "http://localhost:62262"
  ]
}, async (request) => {
  // Allow unauthenticated for demo/onboarding, but rate limit in production
  // For production, consider requiring auth: if (!request.auth) { throw new HttpsError('unauthenticated', '...'); }

  const { prompt } = request.data;
  if (!prompt) {
    throw new HttpsError('invalid-argument', 'Chýba parameter "prompt".');
  }

  const apiKey = geminiApiKey.value();
  if (!apiKey) {
    throw new HttpsError('failed-precondition', 'Server nie je správne nakonfigurovaný (chýba API kľúč).');
  }

  // Model priority fallback (SERVER-SIDE ONLY)
  // We intentionally ignore any client-provided model to keep behavior stable and prevent breakage.
  const modelsToTry = [DEFAULT_MODEL, ...MODEL_PRIORITY.filter(m => m !== DEFAULT_MODEL)];

  let lastError = null;
  for (const modelName of modelsToTry) {
    try {
      const ai = new GoogleGenAI({ vertexai: false, apiKey });
      const response = await ai.models.generateContent({
        model: modelName,
        contents: prompt,
      });
      return { 
        text: response.text || "AI nevrátilo žiadny text.",
        model: modelName
      };

    } catch (error) {
      console.error(`Gemini ${modelName} Error:`, error);
      lastError = error;
      
      if (error.status === 403 || String(error.message || '').includes('API key')) {
        throw new HttpsError('permission-denied', 'Neplatný API kľúč pre AI službu.');
      }
      
      if (String(error.message || '').includes('quota') || error.status === 429) {
        throw new HttpsError('resource-exhausted', 'Dosiahli ste limit bezplatných dopytov. Skúste to neskôr.');
      }

      // Try next model (continue loop)
      continue;
    }
  }

  // All models failed
  throw new HttpsError('internal', `AI Offline: Nepodarilo sa pripojiť k žiadnemu AI modelu. ${lastError?.message || 'Skúste to neskôr.'}`);
});
