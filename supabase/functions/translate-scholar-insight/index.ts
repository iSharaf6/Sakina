import { createClient } from "jsr:@supabase/supabase-js@2.112.2";

const INSIGHT_ID_PATTERN =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
const MAX_ARABIC_BYTES = 100_000;
const CORS_ALLOW_HEADERS = "authorization, apikey, content-type, x-client-info";

function configuredDashboardOrigins(): Set<string> {
  return new Set(
    (Deno.env.get("SCHOLAR_DASHBOARD_ORIGINS") ?? "")
      .split(",")
      .map((origin) => origin.trim())
      .filter((origin) => origin !== ""),
  );
}

function requestOriginIsAllowed(request: Request): boolean {
  const origin = request.headers.get("origin");
  return origin === null || configuredDashboardOrigins().has(origin);
}

function corsHeaders(request: Request): HeadersInit {
  const origin = request.headers.get("origin");
  if (origin === null || !requestOriginIsAllowed(request)) return {};

  return {
    "access-control-allow-origin": origin,
    "access-control-allow-headers": CORS_ALLOW_HEADERS,
    "access-control-allow-methods": "POST, OPTIONS",
    "access-control-max-age": "86400",
    "vary": "Origin",
  };
}

function jsonResponse(
  request: Request,
  status: number,
  body: Record<string, unknown>,
): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      "content-type": "application/json; charset=utf-8",
      "cache-control": "no-store",
      ...corsHeaders(request),
    },
  });
}

function extractResponseText(payload: Record<string, unknown>): string | null {
  if (
    typeof payload.output_text === "string" && payload.output_text.trim() !== ""
  ) {
    return payload.output_text.trim();
  }

  if (!Array.isArray(payload.output)) return null;
  const pieces: string[] = [];
  for (const output of payload.output) {
    if (!output || typeof output !== "object") continue;
    const content = (output as Record<string, unknown>).content;
    if (!Array.isArray(content)) continue;
    for (const item of content) {
      if (!item || typeof item !== "object") continue;
      const text = (item as Record<string, unknown>).text;
      if (typeof text === "string") pieces.push(text);
    }
  }
  const joined = pieces.join("\n").trim();
  return joined === "" ? null : joined;
}

Deno.serve(async (request) => {
  if (!requestOriginIsAllowed(request)) {
    return jsonResponse(request, 403, { error: "origin_not_allowed" });
  }

  if (request.method === "OPTIONS") {
    return new Response(null, {
      status: 204,
      headers: {
        "cache-control": "no-store",
        ...corsHeaders(request),
      },
    });
  }

  if (request.method !== "POST") {
    return jsonResponse(request, 405, { error: "method_not_allowed" });
  }

  const authorization = request.headers.get("authorization");
  if (!authorization?.toLowerCase().startsWith("bearer ")) {
    return jsonResponse(request, 401, { error: "authentication_required" });
  }

  let body: Record<string, unknown>;
  try {
    body = await request.json();
  } catch {
    return jsonResponse(request, 400, { error: "invalid_json" });
  }

  const insightID = typeof body.insight_id === "string" ? body.insight_id : "";
  if (!INSIGHT_ID_PATTERN.test(insightID)) {
    return jsonResponse(request, 422, { error: "invalid_insight_id" });
  }

  const supabaseURL = Deno.env.get("SUPABASE_URL");
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  const openAIKey = Deno.env.get("OPENAI_API_KEY");
  const translationModel = Deno.env.get("OPENAI_TRANSLATION_MODEL");
  if (
    !supabaseURL || !anonKey || !serviceRoleKey || !openAIKey ||
    !translationModel
  ) {
    console.error(
      "Translation function is missing required server configuration",
    );
    return jsonResponse(request, 500, { error: "server_misconfigured" });
  }

  const caller = createClient(supabaseURL, anonKey, {
    global: { headers: { Authorization: authorization } },
    auth: { persistSession: false, autoRefreshToken: false },
  });
  const {
    data: { user },
    error: userError,
  } = await caller.auth.getUser();
  if (userError || !user) {
    return jsonResponse(request, 401, { error: "invalid_session" });
  }

  const { data: insight, error: insightError } = await caller
    .from("scholar_insights")
    .select(
      "id,guidance_item_id,scholar_id,body_ar,reference_material,status,revision_number",
    )
    .eq("id", insightID)
    .maybeSingle();

  if (insightError || !insight || insight.status !== "draft") {
    return jsonResponse(request, 404, { error: "editable_insight_not_found" });
  }

  const arabicBody = typeof insight.body_ar === "string"
    ? insight.body_ar.trim()
    : "";
  if (
    arabicBody === "" ||
    new TextEncoder().encode(arabicBody).byteLength > MAX_ARABIC_BYTES
  ) {
    return jsonResponse(request, 422, { error: "invalid_arabic_body" });
  }

  const { data: guidance, error: guidanceError } = await caller
    .from("guidance_items")
    .select(
      "situation_id,verse_key,title_en,title_ar,context_en,verse_en,active",
    )
    .eq("id", insight.guidance_item_id)
    .maybeSingle();

  if (guidanceError || !guidance?.active) {
    return jsonResponse(request, 409, { error: "guidance_source_unavailable" });
  }

  const translationInstructions = `
Translate the supplied scholar's Arabic prose faithfully and naturally into English.
Do not add religious rulings, explanations, conclusions, or citations.
Preserve names, surah numbers, ayah numbers, hadith numbers, Arabic terminology,
and source references. Do not independently translate Qur'anic quotations.
When the prose quotes the ayah, use only the supplied approved English ayah wording.
Return only the English translation, without commentary or markdown fences.
  `.trim();

  const translationInput = JSON.stringify(
    {
      situation: {
        id: guidance.situation_id,
        title_en: guidance.title_en,
        title_ar: guidance.title_ar,
      },
      ayah: {
        reference: guidance.verse_key,
        approved_english_wording: guidance.verse_en,
      },
      existing_app_context_en: guidance.context_en,
      scholar_prose_ar: arabicBody,
      scholar_reference_material: insight.reference_material,
    },
    null,
    2,
  );

  const providerResponse = await fetch("https://api.openai.com/v1/responses", {
    method: "POST",
    headers: {
      authorization: `Bearer ${openAIKey}`,
      "content-type": "application/json",
    },
    body: JSON.stringify({
      model: translationModel,
      instructions: translationInstructions,
      input: translationInput,
      store: false,
      max_output_tokens: 4000,
    }),
  });

  if (!providerResponse.ok) {
    console.error("Translation provider failed", providerResponse.status);
    return jsonResponse(request, 502, { error: "translation_provider_failed" });
  }

  const providerPayload = (await providerResponse.json()) as Record<
    string,
    unknown
  >;
  const generatedEnglish = extractResponseText(providerPayload);
  if (!generatedEnglish) {
    console.error("Translation provider returned no output text");
    return jsonResponse(request, 502, { error: "translation_provider_empty" });
  }

  const server = createClient(supabaseURL, serviceRoleKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
  const { data: saved, error: saveError } = await server.rpc(
    "save_generated_scholar_translation",
    {
      p_insight_id: insightID,
      p_body_en: generatedEnglish,
      p_provider: "openai",
      p_model: translationModel,
      p_requested_by: user.id,
      p_expected_revision_number: insight.revision_number,
    },
  );

  if (saveError) {
    console.error(
      "Saving generated translation failed",
      saveError.code,
      saveError.message,
    );
    return jsonResponse(request, 409, {
      error: saveError.code === "40001"
        ? "translation_source_changed"
        : "translation_save_failed",
      code: saveError.code,
    });
  }

  return jsonResponse(request, 200, {
    insight_id: saved.id,
    translation_status: saved.translation_status,
    body_en: saved.body_en,
    revision_number: saved.revision_number,
    requires_human_review: true,
    publication_status: saved.status,
  });
});
