// BizAgent — AI generovanie obsahu (BizBot, e-maily, analýzy).
// Mistral primárny. Gemini len ak explicitne nastavíš GEMINI_API_KEY.
//   supabase secrets set MISTRAL_API_KEY=... AI_PRIMARY=mistral
//
// Deploy:  supabase functions deploy generate-content
//
// Volanie z klienta (supabase_flutter):
//   final res = await supabase.functions.invoke('generate-content', body: {'prompt': '...'});
//   final text = res.data['text'] as String;
//
// Funkcia vyžaduje prihláseného používateľa (JWT overí Supabase automaticky,
// pokiaľ nie je nastavené --no-verify-jwt).

import { serve } from "https://deno.land/std@0.224.0/http/server.ts";

const MISTRAL_API_URL = "https://api.mistral.ai/v1/chat/completions";
const GEMINI_API_URL = (model: string, key: string) =>
  `https://generativelanguage.googleapis.com/v1/models/${model}:generateContent?key=${key}`;

const MISTRAL_MODEL = Deno.env.get("MISTRAL_MODEL") || "mistral-small-latest";
const GEMINI_MODELS = ["gemini-1.5-flash", "gemini-2.0-flash"];
const AI_PRIMARY = (Deno.env.get("AI_PRIMARY") || "mistral").toLowerCase();

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const isRetryableStatus = (s: number) =>
  s === 401 || s === 402 || s === 403 || s === 429 || s === 503;

async function runMistral(prompt: string): Promise<{ text: string; model: string; provider: string }> {
  const keys = [
    Deno.env.get("MISTRAL_API_KEY") || "",
    Deno.env.get("MISTRAL_API_KEY_BACKUP") || "",
  ].filter((k) => k.trim().length > 0);
  if (keys.length === 0) throw new Error("Mistral: chýba API kľúč");

  let lastErr: Error | null = null;
  for (let i = 0; i < keys.length; i++) {
    try {
      const resp = await fetch(MISTRAL_API_URL, {
        method: "POST",
        headers: {
          Authorization: `Bearer ${keys[i]}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          model: MISTRAL_MODEL,
          messages: [{ role: "user", content: prompt }],
          temperature: 0.7,
          max_tokens: 2000,
        }),
      });
      if (!resp.ok) {
        lastErr = new Error(`Mistral HTTP ${resp.status}`);
        if (i < keys.length - 1 && isRetryableStatus(resp.status)) continue;
        throw lastErr;
      }
      const data = await resp.json();
      const text = data.choices?.[0]?.message?.content || "AI nevrátilo žiadny text.";
      return { text, model: data.model || MISTRAL_MODEL, provider: "mistral" };
    } catch (e) {
      lastErr = e as Error;
      if (i < keys.length - 1) continue;
      throw lastErr;
    }
  }
  throw lastErr || new Error("Mistral: všetky kľúče zlyhali");
}

async function runGemini(prompt: string): Promise<{ text: string; model: string; provider: string }> {
  const key = Deno.env.get("GEMINI_API_KEY") || "";
  if (!key) throw new Error("Gemini: chýba API kľúč");

  let lastErr: Error | null = null;
  for (const model of GEMINI_MODELS) {
    try {
      const resp = await fetch(GEMINI_API_URL(model, key), {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ contents: [{ parts: [{ text: prompt }] }] }),
      });
      if (!resp.ok) {
        lastErr = new Error(`Gemini HTTP ${resp.status}`);
        continue;
      }
      const data = await resp.json();
      const text = data.candidates?.[0]?.content?.parts?.[0]?.text || "AI nevrátilo žiadny text.";
      return { text, model, provider: "gemini" };
    } catch (e) {
      lastErr = e as Error;
      continue;
    }
  }
  throw lastErr || new Error("Gemini: všetky modely zlyhali");
}

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const { prompt } = await req.json();
    if (!prompt || typeof prompt !== "string" || prompt.length > 10000) {
      return new Response(
        JSON.stringify({ error: 'Parameter "prompt" je povinný (max 10 000 znakov).' }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    const hasMistral = [
      Deno.env.get("MISTRAL_API_KEY") || "",
      Deno.env.get("MISTRAL_API_KEY_BACKUP") || "",
    ].some((k) => k.trim().length > 0);
    const hasGemini = (Deno.env.get("GEMINI_API_KEY") || "").trim().length > 0;

    const preferred = AI_PRIMARY === "gemini" && hasGemini ? "gemini" : "mistral";
    const order = preferred === "gemini"
      ? (["gemini", "mistral"] as const).filter((p) => (p === "gemini" ? hasGemini : hasMistral))
      : (["mistral", "gemini"] as const).filter((p) => (p === "mistral" ? hasMistral : hasGemini));

    if (order.length === 0) {
      return new Response(
        JSON.stringify({ error: "AI Offline: chýba MISTRAL_API_KEY." }),
        { status: 503, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    let lastErr: Error | null = null;
    for (const provider of order) {
      try {
        const result = provider === "gemini" ? await runGemini(prompt) : await runMistral(prompt);
        return new Response(JSON.stringify(result), {
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      } catch (e) {
        lastErr = e as Error;
        console.error(`${provider} zlyhal:`, (e as Error).message);
      }
    }

    return new Response(
      JSON.stringify({ error: "AI Offline: žiadny model nedostupný.", detail: lastErr?.message }),
      { status: 503, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  } catch (e) {
    return new Response(
      JSON.stringify({ error: "Neplatný request.", detail: (e as Error).message }),
      { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  }
});
