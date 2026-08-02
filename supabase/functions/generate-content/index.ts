// BizAgent — AI generovanie obsahu (BizBot, OCR, Autopilot).
// Provider chain: Qwen Cloud (Alibaba) → Mistral → Gemini.
//
// Secrets:
//   supabase secrets set QWEN_API_KEY=... QWEN_MODEL=qwen-plus
//   supabase secrets set MISTRAL_API_KEY=... AI_PRIMARY=qwen
//
// Deploy: supabase functions deploy generate-content

import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import {
  filterModelOutput,
  validatePrompt,
  wrapPromptForSafety,
} from "./safety.ts";

const MISTRAL_API_URL = "https://api.mistral.ai/v1/chat/completions";
const QWEN_API_URL = Deno.env.get("QWEN_API_BASE_URL") ||
  "https://dashscope-intl.aliyuncs.com/compatible-mode/v1/chat/completions";
const GEMINI_API_URL = (model: string, key: string) =>
  `https://generativelanguage.googleapis.com/v1/models/${model}:generateContent?key=${key}`;

const MISTRAL_MODEL = Deno.env.get("MISTRAL_MODEL") || "mistral-small-latest";
const QWEN_MODEL = Deno.env.get("QWEN_MODEL") || "qwen-plus";
const QWEN_MODELS = ["qwen-plus", "qwen-turbo", "qwen-max"];
const GEMINI_MODELS = ["gemini-1.5-flash", "gemini-2.0-flash"];
const AI_PRIMARY = (Deno.env.get("AI_PRIMARY") || "qwen").toLowerCase();

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const isRetryableStatus = (s: number) =>
  s === 401 || s === 402 || s === 403 || s === 429 || s === 503;

type Provider = "qwen" | "mistral" | "gemini";

async function runQwen(
  prompt: string,
  modelHints: string[],
): Promise<{ text: string; model: string; provider: string }> {
  const key = Deno.env.get("QWEN_API_KEY") || "";
  if (!key) throw new Error("Qwen: chýba API kľúč");

  const models = [...new Set([QWEN_MODEL, ...modelHints.filter((m) => m.startsWith("qwen"))])];
  let lastErr: Error | null = null;

  for (const model of models.length > 0 ? models : QWEN_MODELS) {
    try {
      const resp = await fetch(QWEN_API_URL, {
        method: "POST",
        headers: {
          Authorization: `Bearer ${key}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          model,
          messages: [{ role: "user", content: wrapPromptForSafety(prompt) }],
          temperature: 0.7,
          max_tokens: 2000,
        }),
      });
      if (!resp.ok) {
        lastErr = new Error(`Qwen HTTP ${resp.status}`);
        if (isRetryableStatus(resp.status)) continue;
        throw lastErr;
      }
      const data = await resp.json();
      const text = filterModelOutput(
        data.choices?.[0]?.message?.content || "AI nevrátilo žiadny text.",
      );
      return { text, model: data.model || model, provider: "qwen" };
    } catch (e) {
      lastErr = e as Error;
      continue;
    }
  }
  throw lastErr || new Error("Qwen: všetky modely zlyhali");
}

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
          messages: [{ role: "user", content: wrapPromptForSafety(prompt) }],
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
      const text = filterModelOutput(
        data.choices?.[0]?.message?.content || "AI nevrátilo žiadny text.",
      );
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
        body: JSON.stringify({
          contents: [{ parts: [{ text: wrapPromptForSafety(prompt) }] }],
          safetySettings: [
            { category: "HARM_CATEGORY_HARASSMENT", threshold: "BLOCK_MEDIUM_AND_ABOVE" },
            { category: "HARM_CATEGORY_HATE_SPEECH", threshold: "BLOCK_MEDIUM_AND_ABOVE" },
            { category: "HARM_CATEGORY_SEXUALLY_EXPLICIT", threshold: "BLOCK_MEDIUM_AND_ABOVE" },
            { category: "HARM_CATEGORY_DANGEROUS_CONTENT", threshold: "BLOCK_MEDIUM_AND_ABOVE" },
          ],
        }),
      });
      if (!resp.ok) {
        lastErr = new Error(`Gemini HTTP ${resp.status}`);
        continue;
      }
      const data = await resp.json();
      const text = filterModelOutput(
        data.candidates?.[0]?.content?.parts?.[0]?.text || "AI nevrátilo žiadny text.",
      );
      return { text, model, provider: "gemini" };
    } catch (e) {
      lastErr = e as Error;
      continue;
    }
  }
  throw lastErr || new Error("Gemini: všetky modely zlyhali");
}

function buildProviderOrder(
  preferred: string,
  hasQwen: boolean,
  hasMistral: boolean,
  hasGemini: boolean,
): Provider[] {
  const available: Provider[] = [];
  if (hasQwen) available.push("qwen");
  if (hasMistral) available.push("mistral");
  if (hasGemini) available.push("gemini");

  const pref = preferred as Provider;
  if (available.includes(pref)) {
    return [pref, ...available.filter((p) => p !== pref)];
  }
  return available;
}

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const body = await req.json();
    const prompt = body?.prompt;
    const preferredProvider = (body?.provider || AI_PRIMARY || "qwen").toLowerCase();
    const modelHints = Array.isArray(body?.models)
      ? body.models.filter((m: unknown) => typeof m === "string")
      : [];

    if (!prompt || typeof prompt !== "string") {
      return new Response(
        JSON.stringify({ error: 'Parameter "prompt" je povinný (max 10 000 znakov).' }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    const promptError = validatePrompt(prompt);
    if (promptError) {
      return new Response(
        JSON.stringify({ error: promptError }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    const hasQwen = (Deno.env.get("QWEN_API_KEY") || "").trim().length > 0;
    const hasMistral = [
      Deno.env.get("MISTRAL_API_KEY") || "",
      Deno.env.get("MISTRAL_API_KEY_BACKUP") || "",
    ].some((k) => k.trim().length > 0);
    const hasGemini = (Deno.env.get("GEMINI_API_KEY") || "").trim().length > 0;

    const order = buildProviderOrder(preferredProvider, hasQwen, hasMistral, hasGemini);

    if (order.length === 0) {
      return new Response(
        JSON.stringify({ error: "AI Offline: chýba QWEN_API_KEY / MISTRAL_API_KEY." }),
        { status: 503, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    let lastErr: Error | null = null;
    for (const provider of order) {
      try {
        const result = provider === "qwen"
          ? await runQwen(prompt, modelHints)
          : provider === "gemini"
          ? await runGemini(prompt)
          : await runMistral(prompt);

        return new Response(JSON.stringify(result), {
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      } catch (e) {
        lastErr = e as Error;
        console.error(`${provider} zlyhal:`, (e as Error).message);
      }
    }

    return new Response(
      JSON.stringify({ error: "AI Offline: žiadny provider nedostupný.", detail: lastErr?.message }),
      { status: 503, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  } catch (e) {
    return new Response(
      JSON.stringify({ error: "Neplatný request.", detail: (e as Error).message }),
      { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  }
});