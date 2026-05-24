const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { GoogleGenAI } = require("@google/genai");
const { defineString } = require("firebase-functions/params");
const admin = require("firebase-admin");

if (!admin.apps.length) {
  admin.initializeApp();
}

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
    throw new HttpsError('internal', 'Chyba pri generovaní e-mailu.');
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
    throw new HttpsError('internal', 'Chyba pri analýze dokladu.');
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
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'Autentifikácia je povinná.');
  }

  const { ico, full } = request.data;
  if (!ico) {
    throw new HttpsError('invalid-argument', 'Chýba IČO.');
  }
  if (typeof ico !== 'string' || ico.length > 20 || !/^\d+$/.test(ico)) {
    throw new HttpsError('invalid-argument', 'IČO musí byť reťazec obsahujúci iba číslice (max 20 znakov).');
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
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'Autentifikácia je povinná.');
  }

  // --- Rate limiting (per-UID) ---
  // TODO: Implement Redis/Firestore-based rate limiter.
  // For now, log UID for monitoring; Cloud Functions quotas provide basic protection.
  const uid = request.auth.uid;
  console.log(`generateContent called by uid=${uid}`);

  const { prompt } = request.data;
  if (!prompt) {
    throw new HttpsError('invalid-argument', 'Chýba parameter "prompt".');
  }
  if (typeof prompt !== 'string' || prompt.length > 10000) {
    throw new HttpsError('invalid-argument', 'Parameter "prompt" musí byť reťazec s maximálnou dĺžkou 10 000 znakov.');
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
  throw new HttpsError('internal', 'AI Offline: Nepodarilo sa pripojiť k žiadnemu AI modelu. Skúste to neskôr.');
});

/**
 * Cascade-deletes all user data: Firestore documents, Storage files, and Auth record.
 * Called from client before/instead of client-side user.delete().
 *
 * Deletes from all top-level collections keyed by userId as defined in firestore.rules:
 * - users/{uid} (+ subcollections: settings, bizbot_threads/default/messages, etc.)
 * - invoices/{uid} (+ subcollections)
 * - expenses/{uid} (+ subcollections)
 * - receipts/{uid} (+ subcollections)
 * - invoice_numbering/{uid} (+ subcollections)
 * - soft_deleted_invoices/{uid}/items/*
 * - soft_deleted_bizbot_conversations/{uid}/items/*
 * - soft_deleted_notepad_items/{uid}/items/*
 * - ai_reports where userId == uid
 * - Storage: users/{uid}/**
 */
exports.deleteUserData = onCall({
  cors: [
    "https://biz-agent-web.vercel.app",
    "https://bizagent-live-2026.web.app",
    "http://localhost:3000",
    "http://localhost:5050",
    "http://localhost:62262"
  ]
}, async (request) => {
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'Autentifikácia je povinná.');
  }

  const uid = request.auth.uid;
  console.log(`deleteUserData: starting cascade deletion for uid=${uid}`);

  const db = admin.firestore();
  const storage = admin.storage().bucket();
  const auth = admin.auth();

  // Audit log: record deletion attempt BEFORE starting
  try {
    await db.doc(`deletion_audit/${uid}`).set({
      deletedAt: admin.firestore.FieldValue.serverTimestamp(),
      uid: uid,
    });
    console.log(`deleteUserData: audit log written for uid=${uid}`);
  } catch (e) {
    // Audit failure should not block deletion, but log it
    console.error(`deleteUserData: failed to write audit log:`, e.message);
  }

  let hasErrors = false;

  // 1. Delete top-level documents with subcollections using recursiveDelete
  // These are documents that act as parent containers keyed by uid
  const documentsToRecursivelyDelete = [
    `users/${uid}`,
    `invoices/${uid}`,
    `expenses/${uid}`,
    `receipts/${uid}`,
    `invoice_numbering/${uid}`,
    `soft_deleted_invoices/${uid}`,
    `soft_deleted_bizbot_conversations/${uid}`,
    `soft_deleted_notepad_items/${uid}`,
  ];

  for (const docPath of documentsToRecursivelyDelete) {
    try {
      await db.recursiveDelete(db.doc(docPath));
      console.log(`deleteUserData: recursiveDelete completed for ${docPath}`);
    } catch (e) {
      console.error(`deleteUserData: error deleting ${docPath}:`, e.message);
      hasErrors = true;
    }
  }

  // 2. Delete ai_reports where userId == uid (query-based, not path-based)
  try {
    const reportsQuery = db.collection('ai_reports').where('userId', '==', uid);
    const reports = await reportsQuery.get();
    if (!reports.empty) {
      // Delete in batches of 500 (Firestore batch limit)
      const batches = [];
      let batch = db.batch();
      let count = 0;
      for (const doc of reports.docs) {
        batch.delete(doc.ref);
        count++;
        if (count % 500 === 0) {
          batches.push(batch.commit());
          batch = db.batch();
        }
      }
      if (count % 500 !== 0) {
        batches.push(batch.commit());
      }
      await Promise.all(batches);
      console.log(`deleteUserData: deleted ${reports.size} ai_reports`);
    }
  } catch (e) {
    console.error(`deleteUserData: error deleting ai_reports:`, e.message);
    hasErrors = true;
  }

  // 3. Delete Storage files under users/{uid}/
  try {
    const [files] = await storage.getFiles({ prefix: `users/${uid}/` });
    if (files.length > 0) {
      await Promise.all(files.map((file) => file.delete()));
      console.log(`deleteUserData: deleted ${files.length} storage files`);
    }
  } catch (e) {
    console.error(`deleteUserData: storage error:`, e.message);
    hasErrors = true;
  }

  // 4. Delete Firebase Auth user
  try {
    await auth.deleteUser(uid);
    console.log(`deleteUserData: deleted auth user ${uid}`);
  } catch (e) {
    console.error(`deleteUserData: auth deletion error:`, e.message);
    hasErrors = true;
  }

  if (hasErrors) {
    console.warn(`deleteUserData: completed with errors for uid=${uid}`);
    throw new HttpsError('internal', 'Vymazanie účtu sa nepodarilo úplne dokončiť. Kontaktujte podporu.');
  }

  console.log(`deleteUserData: successfully completed for uid=${uid}`);
  return { success: true };
});
