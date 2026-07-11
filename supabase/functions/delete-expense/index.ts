// BizAgent — zmazanie výdavku + príslušných bločkov (receipts bucket).
// Deploy: supabase functions deploy delete-expense
// Client: supabase.functions.invoke('delete-expense', body: { expenseId })

import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import {
  assertOwnerReceiptPath,
  jsonResponse,
  receiptPathFromReference,
  requireAuth,
} from "../_shared/http.ts";

const EXPENSES_TABLE = "expenses";
const RECEIPTS_BUCKET = "receipts";

serve(async (req: Request) => {
  const auth = await requireAuth(req);
  if (auth instanceof Response) return auth;

  const { user, client } = auth;

  let body: { expenseId?: string };
  try {
    body = await req.json();
  } catch {
    return jsonResponse({ error: "Invalid JSON body" }, 400);
  }

  const expenseId = body.expenseId?.trim();
  if (!expenseId) {
    return jsonResponse({ error: 'Parameter "expenseId" is required' }, 400);
  }

  const { data: row, error: fetchError } = await client
    .from(EXPENSES_TABLE)
    .select("data")
    .eq("id", expenseId)
    .eq("user_id", user.id)
    .maybeSingle();

  if (fetchError) {
    return jsonResponse({ error: fetchError.message }, 500);
  }

  if (!row) {
    return jsonResponse({ error: "Expense not found" }, 404);
  }

  const data = row.data as Record<string, unknown>;
  const receiptUrls = Array.isArray(data.receiptUrls)
    ? (data.receiptUrls as string[])
    : [];

  const receiptPaths = [
    ...new Set(
      receiptUrls
        .map((url) => receiptPathFromReference(url, RECEIPTS_BUCKET))
        .filter((path): path is string =>
          !!path && assertOwnerReceiptPath(user.id, path)
        ),
    ),
  ];

  const storageErrors: string[] = [];
  if (receiptPaths.length > 0) {
    const { error: storageError } = await client.storage
      .from(RECEIPTS_BUCKET)
      .remove(receiptPaths);

    if (storageError) {
      storageErrors.push(storageError.message);
    }
  }

  const { error: deleteError } = await client
    .from(EXPENSES_TABLE)
    .delete()
    .eq("id", expenseId)
    .eq("user_id", user.id);

  if (deleteError) {
    return jsonResponse({ error: deleteError.message }, 500);
  }

  return jsonResponse({
    ok: storageErrors.length === 0,
    expenseId,
    receiptsDeleted: receiptPaths.length,
    receiptPaths,
    partial_errors: storageErrors.length > 0 ? storageErrors : undefined,
  }, storageErrors.length > 0 ? 207 : 200);
});