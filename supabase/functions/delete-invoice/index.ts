// BizAgent — soft/permanent delete faktúry (trash_items + is_deleted).
// Deploy: supabase functions deploy delete-invoice
// Client: supabase.functions.invoke('delete-invoice', body: { invoiceId, mode: 'soft'|'permanent' })

import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import {
  corsHeaders,
  jsonResponse,
  requireAuth,
} from "../_shared/http.ts";

const INVOICES_TABLE = "invoices";
const TRASH_TABLE = "trash_items";
const INVOICE_COLLECTION = "soft_deleted_invoices";

serve(async (req: Request) => {
  const auth = await requireAuth(req);
  if (auth instanceof Response) return auth;

  const { user, client } = auth;

  let body: { invoiceId?: string; mode?: string; reason?: string };
  try {
    body = await req.json();
  } catch {
    return jsonResponse({ error: "Invalid JSON body" }, 400);
  }

  const invoiceId = body.invoiceId?.trim();
  const mode = body.mode === "permanent" ? "permanent" : "soft";

  if (!invoiceId) {
    return jsonResponse({ error: 'Parameter "invoiceId" is required' }, 400);
  }

  const { data: row, error: fetchError } = await client
    .from(INVOICES_TABLE)
    .select("data")
    .eq("id", invoiceId)
    .eq("user_id", user.id)
    .maybeSingle();

  if (fetchError) {
    return jsonResponse({ error: fetchError.message }, 500);
  }

  if (mode === "soft") {
    const now = new Date().toISOString();
    const itemData: Record<string, unknown> = row
      ? { ...(row.data as Record<string, unknown>) }
      : { id: invoiceId };

    itemData.deletedAt = now;
    if (body.reason) itemData.deleteReason = body.reason;

    const { error: trashError } = await client.from(TRASH_TABLE).upsert({
      id: invoiceId,
      user_id: user.id,
      collection: INVOICE_COLLECTION,
      data: itemData,
      deleted_at: now,
    });

    if (trashError) {
      return jsonResponse({ error: trashError.message }, 500);
    }

    if (row) {
      const { error: updateError } = await client
        .from(INVOICES_TABLE)
        .update({ is_deleted: true, updated_at: now })
        .eq("id", invoiceId)
        .eq("user_id", user.id);

      if (updateError) {
        return jsonResponse({ error: updateError.message }, 500);
      }
    }

    return jsonResponse({ ok: true, mode: "soft", invoiceId });
  }

  const { error: invoiceDeleteError } = await client
    .from(INVOICES_TABLE)
    .delete()
    .eq("id", invoiceId)
    .eq("user_id", user.id);

  if (invoiceDeleteError) {
    return jsonResponse({ error: invoiceDeleteError.message }, 500);
  }

  await client
    .from(TRASH_TABLE)
    .delete()
    .eq("id", invoiceId)
    .eq("user_id", user.id)
    .eq("collection", INVOICE_COLLECTION);

  return jsonResponse({ ok: true, mode: "permanent", invoiceId });
});