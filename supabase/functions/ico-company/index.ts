import { corsHeaders, jsonResponse } from "../_shared/http.ts";

const ICOATLAS_BASE =
  Deno.env.get("ICOATLAS_BASE_URL")?.replace(/\/$/, "") ||
  "https://icoatlas.sk";

function normalizeIco(raw: string): string | null {
  const digits = raw.replace(/\D/g, "");
  if (digits.length === 0 || digits.length > 8) return null;
  return digits.padStart(8, "0");
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return jsonResponse({ error: "Method not allowed" }, 405);
  }

  let ico = "";
  try {
    const body = await req.json();
    ico = String(body?.ico ?? "");
  } catch {
    return jsonResponse({ error: "Invalid JSON body" }, 400);
  }

  const normalized = normalizeIco(ico);
  if (!normalized) {
    return jsonResponse({ error: "Invalid IČO" }, 400);
  }

  const apiKey = Deno.env.get("ICOATLAS_API_KEY") ?? "";

  const headers: Record<string, string> = {
    Accept: "application/json",
    "Content-Type": "application/json",
  };
  if (apiKey.trim()) {
    headers["X-Api-Key"] = apiKey;
  }

  try {
    const response = await fetch(`${ICOATLAS_BASE}/api/company/${normalized}`, {
      headers,
    });

    if (response.status === 404) {
      return jsonResponse({ ok: false, error: "not_found" }, 404);
    }

    if (!response.ok) {
      const text = await response.text();
      console.error("IcoAtlas proxy error:", response.status, text);
      return jsonResponse({ ok: false, error: "upstream_error" }, response.status);
    }

    const payload = await response.json();
    return jsonResponse(payload);
  } catch (error) {
    console.error("IcoAtlas proxy failed:", error);
    return jsonResponse({ ok: false, error: "proxy_failed" }, 502);
  }
});