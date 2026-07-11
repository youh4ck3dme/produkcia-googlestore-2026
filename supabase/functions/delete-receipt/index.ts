// BizAgent — zmazanie bločku (receipt) zo Storage bucketu `receipts`.
// Deploy: supabase functions deploy delete-receipt
// Client: supabase.functions.invoke('delete-receipt', body: { paths: ['uid/file.jpg'] })
//          alebo { urls: ['https://.../receipts/uid/file.jpg'] }

import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import {
  assertOwnerReceiptPath,
  jsonResponse,
  receiptPathFromReference,
  requireAuth,
} from "../_shared/http.ts";

const RECEIPTS_BUCKET = "receipts";

serve(async (req: Request) => {
  const auth = await requireAuth(req);
  if (auth instanceof Response) return auth;

  const { user, client } = auth;

  let body: { paths?: string[]; urls?: string[] };
  try {
    body = await req.json();
  } catch {
    return jsonResponse({ error: "Invalid JSON body" }, 400);
  }

  const rawPaths = Array.isArray(body.paths) ? body.paths : [];
  const rawUrls = Array.isArray(body.urls) ? body.urls : [];

  const resolved = [
    ...new Set(
      [
        ...rawPaths,
        ...rawUrls.map((url) => receiptPathFromReference(url, RECEIPTS_BUCKET)),
      ]
        .filter((path): path is string => typeof path === "string" && path.length > 0)
        .filter((path) => assertOwnerReceiptPath(user.id, path)),
    ),
  ];

  if (resolved.length === 0) {
    return jsonResponse({
      error: 'Provide at least one owned "paths" or "urls" entry',
    }, 400);
  }

  const { error: storageError } = await client.storage
    .from(RECEIPTS_BUCKET)
    .remove(resolved);

  if (storageError) {
    return jsonResponse({ error: storageError.message }, 500);
  }

  return jsonResponse({
    ok: true,
    deleted: resolved.length,
    paths: resolved,
  });
});