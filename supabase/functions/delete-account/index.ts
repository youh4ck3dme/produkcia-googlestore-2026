// BizAgent — GDPR / Play Store account deletion (Supabase canonical).
// Deploy: supabase functions deploy delete-account
// Client: supabase.functions.invoke('delete-account')

import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const USER_TABLES = [
  "invoices",
  "expenses",
  "user_settings",
  "bizbot_messages",
  "ai_reports",
  "notifications",
  "watched_companies",
  "trash_items",
] as const;

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "Method not allowed" }), {
      status: 405,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  const authHeader = req.headers.get("Authorization");
  if (!authHeader?.startsWith("Bearer ")) {
    return new Response(JSON.stringify({ error: "Unauthorized" }), {
      status: 401,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY") ?? "";
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

  if (!supabaseUrl || !anonKey || !serviceRoleKey) {
    return new Response(
      JSON.stringify({ error: "Server misconfigured: missing Supabase env" }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  }

  const userClient = createClient(supabaseUrl, anonKey, {
    global: { headers: { Authorization: authHeader } },
  });

  const {
    data: { user },
    error: userError,
  } = await userClient.auth.getUser();

  if (userError || !user) {
    return new Response(JSON.stringify({ error: "Unauthorized" }), {
      status: 401,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  const userId = user.id;
  const admin = createClient(supabaseUrl, serviceRoleKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });

  const deleted: Record<string, number> = {};
  const errors: string[] = [];

  for (const table of USER_TABLES) {
    const { error, count } = await admin
      .from(table)
      .delete({ count: "exact" })
      .eq("user_id", userId);

    if (error) {
      errors.push(`${table}: ${error.message}`);
      deleted[table] = 0;
    } else {
      deleted[table] = count ?? 0;
    }
  }

  try {
    const { data: listed, error: listError } = await admin.storage
      .from("receipts")
      .list(userId);

    if (listError) {
      errors.push(`storage list: ${listError.message}`);
    } else if (listed && listed.length > 0) {
      const paths = listed.map((f) => `${userId}/${f.name}`);
      const { error: removeError } = await admin.storage
        .from("receipts")
        .remove(paths);
      if (removeError) {
        errors.push(`storage remove: ${removeError.message}`);
        deleted.storage_files = 0;
      } else {
        deleted.storage_files = paths.length;
      }
    } else {
      deleted.storage_files = 0;
    }
  } catch (e) {
    errors.push(`storage: ${(e as Error).message}`);
    deleted.storage_files = 0;
  }

  const { error: deleteUserError } = await admin.auth.admin.deleteUser(userId);

  if (deleteUserError) {
    return new Response(
      JSON.stringify({
        ok: false,
        error: "Failed to delete auth user",
        detail: deleteUserError.message,
        deleted,
        partial_errors: errors,
      }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  }

  const ok = errors.length === 0;
  return new Response(
    JSON.stringify({
      ok,
      deleted,
      user_id: userId,
      partial_errors: errors.length > 0 ? errors : undefined,
    }),
    {
      status: ok ? 200 : 207,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    },
  );
});