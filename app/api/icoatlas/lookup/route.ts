import { NextResponse } from "next/server";

export const runtime = "nodejs";

export async function GET(req: Request) {
  const { searchParams } = new URL(req.url);
  const icoRaw = (searchParams.get("ico") ?? "").trim();

  if (!icoRaw) {
    return NextResponse.json({ error: "Missing IČO parameter" }, { status: 400 });
  }

  const ico = icoRaw.replace(/\s+/g, "");
  const padded = /^\d+$/.test(ico) ? ico.padStart(8, "0") : ico;

  const apiKey = process.env.ICOATLAS_API_KEY;
  if (!apiKey) {
    return NextResponse.json({ error: "Server configuration error" }, { status: 500 });
  }

  const base = process.env.ICOATLAS_LOOKUP_PATH ?? "https://icoatlas.sk/api/company";
  const upstream = `${base}/${encodeURIComponent(padded)}`;

  const r = await fetch(upstream, {
    headers: {
      "Accept": "application/json",
      "X-Api-Key": apiKey,
    },
    cache: "no-store",
  });

  if (r.status === 404) return NextResponse.json({ error: "Company not found" }, { status: 404 });
  if (r.status === 401 || r.status === 403) {
    return NextResponse.json({ error: "Upstream auth error" }, { status: 502 });
  }
  if (!r.ok) {
    return NextResponse.json({ error: "External API error", status: r.status }, { status: 502 });
  }

  const data: any = await r.json();

  // Robust mapping (podporí aj rôzne štruktúry)
  const result = {
    name: data?.name ?? data?.snapshot?.name_current ?? "",
    ico: data?.ico ?? data?.identifiers?.ico ?? padded,
    dic: data?.dic ?? "",
    icDph: data?.ic_dph ?? data?.icDph ?? "",
    address:
      data?.address ??
      (data?.snapshot?.address_current
        ? [
            data.snapshot.address_current.street,
            data.snapshot.address_current.city,
          ]
            .filter(Boolean)
            .join(", ")
        : ""),
  };

  return NextResponse.json(result, { status: 200 });
}
