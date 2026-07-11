import { createClient, type SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";

export const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

export function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

export type AuthContext = {
  user: { id: string };
  client: SupabaseClient;
};

export async function requireAuth(
  req: Request,
): Promise<AuthContext | Response> {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return jsonResponse({ error: "Method not allowed" }, 405);
  }

  const authHeader = req.headers.get("Authorization");
  if (!authHeader?.startsWith("Bearer ")) {
    return jsonResponse({ error: "Unauthorized" }, 401);
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY") ?? "";

  if (!supabaseUrl || !anonKey) {
    return jsonResponse({ error: "Server misconfigured: missing Supabase env" }, 500);
  }

  const client = createClient(supabaseUrl, anonKey, {
    global: { headers: { Authorization: authHeader } },
  });

  const {
    data: { user },
    error: userError,
  } = await client.auth.getUser();

  if (userError || !user) {
    return jsonResponse({ error: "Unauthorized" }, 401);
  }

  return { user, client };
}

export function receiptPathFromReference(
  urlOrPath: string,
  bucket = "receipts",
): string | null {
  if (!urlOrPath) return null;
  if (!urlOrPath.includes("://")) return urlOrPath;

  try {
    const uri = new URL(urlOrPath);
    const segments = uri.pathname.split("/").filter(Boolean);
    const bucketIndex = segments.indexOf(bucket);
    if (bucketIndex >= 0 && bucketIndex + 1 < segments.length) {
      return segments.slice(bucketIndex + 1).join("/");
    }
  } catch {
    // fall through
  }

  const marker = `/${bucket}/`;
  const idx = urlOrPath.indexOf(marker);
  if (idx >= 0) {
    return urlOrPath.substring(idx + marker.length).split("?")[0];
  }

  return null;
}

export function assertOwnerReceiptPath(userId: string, path: string): boolean {
  return path.startsWith(`${userId}/`);
}