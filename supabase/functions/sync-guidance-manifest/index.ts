import { createClient } from "jsr:@supabase/supabase-js@2.112.2";

const MAX_BODY_BYTES = 2_000_000;
const MIN_EXPECTED_ITEMS = 50;
const MAX_EXPECTED_ITEMS = 10_000;

function jsonResponse(status: number, body: Record<string, unknown>): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      "content-type": "application/json; charset=utf-8",
      "cache-control": "no-store",
    },
  });
}

async function tokensMatch(
  candidate: string,
  expected: string,
): Promise<boolean> {
  const encoder = new TextEncoder();
  const [candidateDigest, expectedDigest] = await Promise.all([
    crypto.subtle.digest("SHA-256", encoder.encode(candidate)),
    crypto.subtle.digest("SHA-256", encoder.encode(expected)),
  ]);
  const left = new Uint8Array(candidateDigest);
  const right = new Uint8Array(expectedDigest);
  let difference = left.length ^ right.length;
  for (let index = 0; index < Math.max(left.length, right.length); index += 1) {
    difference |= (left[index] ?? 0) ^ (right[index] ?? 0);
  }
  return difference === 0;
}

function validateManifest(
  value: unknown,
): value is Array<Record<string, string>> {
  if (!Array.isArray(value)) return false;
  if (value.length < MIN_EXPECTED_ITEMS || value.length > MAX_EXPECTED_ITEMS) {
    return false;
  }

  const identities = new Set<string>();
  const requiredFields = [
    "situation_id",
    "verse_key",
    "title_en",
    "title_ar",
    "context_en",
    "context_ar",
    "surah_name_en",
    "surah_name_ar",
    "verse_ar",
    "verse_en",
    "source_hash",
  ];

  for (const entry of value) {
    if (!entry || typeof entry !== "object" || Array.isArray(entry)) {
      return false;
    }
    for (const field of requiredFields) {
      const fieldValue = (entry as Record<string, unknown>)[field];
      if (typeof fieldValue !== "string" || fieldValue.trim() === "") {
        return false;
      }
    }

    const typedEntry = entry as Record<string, string>;
    if (!/^[0-9a-f]{64}$/.test(typedEntry.source_hash)) return false;
    const identity = `${typedEntry.situation_id}\u0000${typedEntry.verse_key}`;
    if (identities.has(identity)) return false;
    identities.add(identity);
  }

  return true;
}

Deno.serve(async (request) => {
  if (request.method !== "POST") {
    return jsonResponse(405, { error: "method_not_allowed" });
  }

  const expectedToken = Deno.env.get("GUIDANCE_SYNC_TOKEN") ?? "";
  const suppliedToken = request.headers.get("x-guidance-sync-token") ?? "";
  if (
    expectedToken.length < 32 ||
    !(await tokensMatch(suppliedToken, expectedToken))
  ) {
    return jsonResponse(401, { error: "unauthorized" });
  }

  const declaredLength = Number(request.headers.get("content-length") ?? "0");
  if (Number.isFinite(declaredLength) && declaredLength > MAX_BODY_BYTES) {
    return jsonResponse(413, { error: "payload_too_large" });
  }

  const rawBody = await request.text();
  if (new TextEncoder().encode(rawBody).byteLength > MAX_BODY_BYTES) {
    return jsonResponse(413, { error: "payload_too_large" });
  }

  let payload: unknown;
  try {
    payload = JSON.parse(rawBody);
  } catch {
    return jsonResponse(400, { error: "invalid_json" });
  }

  const manifest =
    payload && typeof payload === "object" && !Array.isArray(payload)
      ? (payload as Record<string, unknown>).manifest
      : payload;

  if (!validateManifest(manifest)) {
    return jsonResponse(422, { error: "invalid_manifest" });
  }

  const supabaseURL = Deno.env.get("SUPABASE_URL");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!supabaseURL || !serviceRoleKey) {
    console.error("Manifest sync is missing required server configuration");
    return jsonResponse(500, { error: "server_misconfigured" });
  }

  const server = createClient(supabaseURL, serviceRoleKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
  const { data, error } = await server.rpc("sync_guidance_manifest", {
    p_manifest: manifest,
  });

  if (error) {
    console.error("Manifest sync RPC failed", error.code, error.message);
    return jsonResponse(500, { error: "sync_failed", code: error.code });
  }

  return jsonResponse(200, { ok: true, result: data });
});
