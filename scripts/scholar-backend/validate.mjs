#!/usr/bin/env node

import { readFile } from "node:fs/promises";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const root = resolve(dirname(fileURLToPath(import.meta.url)), "../..");

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

function assertIncludes(source, fragment, label) {
  assert(source.includes(fragment), `${label} is missing: ${fragment}`);
}

function assertBalancedDollarQuotes(sql, label) {
  const delimiters = sql.match(/\$[A-Za-z_0-9]*\$/g) ?? [];
  const counts = new Map();
  for (const delimiter of delimiters) {
    counts.set(delimiter, (counts.get(delimiter) ?? 0) + 1);
  }
  for (const [delimiter, count] of counts) {
    assert(count % 2 === 0, `${label} has an unbalanced ${delimiter} delimiter`);
  }
}

async function main() {
  const paths = {
    schema: resolve(
      root,
      "supabase/migrations/20260811074636_scholar_editorial_schema.sql",
    ),
    workflow: resolve(
      root,
      "supabase/migrations/20260811074804_scholar_editorial_security_and_workflow_retry.sql",
    ),
    seed: resolve(
      root,
      "supabase/migrations/20260811074900_seed_guidance_manifest_103.sql",
    ),
    syncFunction: resolve(root, "supabase/functions/sync-guidance-manifest/index.ts"),
    translationFunction: resolve(
      root,
      "supabase/functions/translate-scholar-insight/index.ts",
    ),
    manifest: resolve(root, "supabase/manifests/guidance-manifest.json"),
    profileTemplate: resolve(
      root,
      "supabase/templates/scholar-profile.json",
    ),
    action: resolve(root, ".github/workflows/sync-scholar-guidance.yml"),
  };

  const [
    schema,
    workflow,
    seed,
    syncFunction,
    translationFunction,
    manifestSource,
    profileTemplateSource,
    action,
  ] = await Promise.all(Object.values(paths).map((path) => readFile(path, "utf8")));

  assertBalancedDollarQuotes(schema, "schema migration");
  assertBalancedDollarQuotes(workflow, "workflow migration");
  assertBalancedDollarQuotes(seed, "historical manifest seed migration");
  assertIncludes(
    seed,
    "select public.sync_guidance_manifest(",
    "historical manifest seed migration",
  );

  for (const enumName of ["app_role", "insight_status", "translation_status"]) {
    assertIncludes(schema, `create type public.${enumName} as enum`, "schema migration");
  }

  for (const tableName of [
    "user_roles",
    "scholar_profiles",
    "guidance_items",
    "scholar_insights",
    "scholar_insight_revisions",
    "editorial_audit_log",
  ]) {
    assertIncludes(schema, `create table public.${tableName}`, "schema migration");
    assertIncludes(
      schema,
      `alter table public.${tableName} enable row level security`,
      "schema migration",
    );
  }

  for (const indexName of [
    "user_roles_assigned_by_idx",
    "scholar_profiles_verified_by_idx",
    "guidance_items_review_queue_idx",
    "scholar_insights_guidance_item_id_idx",
    "scholar_insights_scholar_id_idx",
    "scholar_insights_supersedes_idx",
    "scholar_insights_translation_reviewed_by_idx",
    "scholar_insights_published_by_idx",
    "scholar_insights_archived_by_idx",
    "scholar_insight_revisions_insight_idx",
    "scholar_insight_revisions_guidance_item_idx",
    "scholar_insight_revisions_scholar_idx",
  ]) {
    assertIncludes(schema, indexName, "foreign-key/index coverage");
  }

  assertIncludes(schema, "unique (situation_id, verse_key)", "guidance identity");
  assertIncludes(schema, "scholar_insights_one_working_copy_idx", "working-copy invariant");
  assertIncludes(schema, "scholar_insights_one_published_copy_idx", "publish invariant");
  assertIncludes(
    workflow,
    "scholar_insights_reference_material_shape",
    "public reference JSON shape constraint",
  );
  assertIncludes(
    workflow,
    "^https://[^[:space:]]+$",
    "public reference HTTPS-only rule",
  );
  assertIncludes(workflow, "scholar_profiles_select_public", "public profile RLS");
  assertIncludes(workflow, "create view public.public_scholar_profiles", "public profile view");
  assertIncludes(workflow, "gi.title_en as situation_title_en", "public situation title");
  assertIncludes(workflow, "new.verified := false", "profile re-verification gate");
  assertIncludes(
    workflow,
    "scholar_profiles.avatar_path is distinct from excluded.avatar_path",
    "admin portrait re-verification gate",
  );
  assertIncludes(workflow, "scholar_insights_select_published", "published insight RLS");
  assertIncludes(
    workflow,
    "where gi.id = guidance_item_id\n      and gi.active",
    "published insight active-guidance gate",
  );
  assertIncludes(workflow, "scholar_insights_update_own_work", "scholar write RLS");
  assertIncludes(
    workflow,
    "scholar_insights_select_own_work",
    "scholar working-copy read RLS",
  );
  assertIncludes(
    workflow,
    "Active scholar or admin role required",
    "revoked-role RPC gate",
  );
  assertIncludes(workflow, "(select auth.uid())", "cached auth.uid RLS pattern");
  assertIncludes(workflow, "Only an admin can publish insights", "admin publish gate");
  assert(
    !/ur\.role = 'scholar'::public\.app_role\s+ur\.role = 'scholar'::public\.app_role/.test(
      workflow,
    ),
    "Scholar role predicates must include an operator",
  );
  assertIncludes(
    workflow,
    "save_scholar_insight_draft(uuid, text, text, jsonb, integer)",
    "revision-safe draft-save RPC",
  );
  assertIncludes(
    workflow,
    "create or replace function public.create_scholar_replacement_draft",
    "atomic replacement-draft RPC",
  );
  assertIncludes(
    workflow,
    "and si.revision_number = p_expected_revision_number",
    "optimistic revision checks",
  );
  assertIncludes(
    workflow,
    "submit_scholar_insight(uuid, integer)",
    "revision-safe submit RPC",
  );
  assertIncludes(workflow, "reviewed_source_hash", "stale-source publish gate");
  assertIncludes(workflow, "translation_status <> 'reviewed'", "translation review gate");
  assertIncludes(workflow, "pg_advisory_xact_lock", "atomic manifest lock");
  assertIncludes(
    workflow,
    "p_manifest is null or jsonb_typeof(p_manifest) <> 'array'",
    "null manifest rejection",
  );
  assertIncludes(workflow, "on conflict (situation_id, verse_key)", "atomic manifest upsert");
  assertIncludes(workflow, "existing.active", "non-destructive retirement");
  assertIncludes(workflow, "scholar_avatars_insert_own", "avatar owner policy");
  assertIncludes(workflow, "storage_object_owner_id(name) = (select auth.uid())", "avatar path owner check");
  assert(
    !workflow.includes("create policy scholar_avatars_update_own") &&
      !workflow.includes("create policy scholar_avatars_delete_own"),
    "Scholars must not overwrite or delete an already public avatar in place",
  );
  assert(
    !/grant\s+update\s*\([^)]*avatar_path[^)]*\)\s*on\s+public\.scholar_profiles\s+to\s+authenticated/is.test(
      workflow,
    ),
    "Scholars must not change the reviewed avatar path",
  );

  const policyNames = [...workflow.matchAll(/create policy\s+([a-z0-9_]+)/gi)].map(
    (match) => match[1].toLowerCase(),
  );
  assert(
    policyNames.length === new Set(policyNames).size,
    "RLS policy names must be unique",
  );

  assertIncludes(
    workflow,
    "grant execute on function public.sync_guidance_manifest(jsonb) to service_role",
    "server-only sync grant",
  );
  assert(
    !/grant execute on function public\.sync_guidance_manifest\(jsonb\)\s+to\s+(anon|authenticated)/i.test(
      workflow,
    ),
    "Manifest sync must not be executable by client roles",
  );
  assert(
    !/grant\s+(insert|update|delete|all).*public\.user_roles.*authenticated/is.test(
      workflow,
    ),
    "Authenticated users must not receive user_roles write grants",
  );
  assert(
    !/grant\s+(insert|update|delete|all)[\s\S]*?on\s+public\.scholar_insights\s+to\s+authenticated/i.test(
      workflow,
    ),
    "Authenticated clients must mutate insights only through revision-safe RPCs",
  );
  for (const tableName of ["scholar_profiles", "guidance_items", "scholar_insights"]) {
    assert(
      !new RegExp(
        `grant select on table public\\.${tableName} to (?:anon|anon, authenticated)`,
        "i",
      ).test(workflow),
      `anon must receive column-scoped SELECT on ${tableName}`,
    );
  }

  assertIncludes(syncFunction, 'Deno.env.get("GUIDANCE_SYNC_TOKEN")', "sync secret");
  assertIncludes(syncFunction, 'rpc("sync_guidance_manifest"', "sync RPC call");
  assert(
    !syncFunction.includes("publish_scholar_insight"),
    "Manifest sync must never publish insights",
  );

  assertIncludes(
    translationFunction,
    'rpc(\n    "save_generated_scholar_translation"',
    "translation draft RPC",
  );
  assertIncludes(
    translationFunction,
    'Deno.env.get("SCHOLAR_DASHBOARD_ORIGINS")',
    "dashboard-origin allowlist",
  );
  assertIncludes(
    translationFunction,
    'request.method === "OPTIONS"',
    "browser CORS preflight",
  );
  assertIncludes(
    translationFunction,
    '"access-control-allow-origin"',
    "browser CORS response headers",
  );
  assertIncludes(
    translationFunction,
    "p_expected_revision_number: insight.revision_number",
    "translation revision compare-and-swap",
  );
  assertIncludes(
    translationFunction,
    "revision_number: saved.revision_number",
    "saved revision response",
  );
  assertIncludes(translationFunction, "requires_human_review: true", "human review response");
  assert(
    !translationFunction.includes("publish_scholar_insight"),
    "Translation function must never call publication",
  );

  const manifest = JSON.parse(manifestSource);
  assert(Array.isArray(manifest) && manifest.length >= 50, "Manifest is unexpectedly small");
  const seedManifestMatch = seed.match(
    /\$manifest\$\n([\s\S]*?)\n\$manifest\$::jsonb/,
  );
  assert(seedManifestMatch, "Historical manifest seed payload is missing");
  const seedManifest = JSON.parse(seedManifestMatch[1]);
  assert(
    Array.isArray(seedManifest) && seedManifest.length === 103,
    "Historical manifest seed must contain exactly 103 items",
  );
  const identities = new Set();
  for (const item of manifest) {
    const identity = `${item.situation_id}\u0000${item.verse_key}`;
    assert(!identities.has(identity), `Duplicate manifest identity: ${identity}`);
    identities.add(identity);
    assert(/^[0-9a-f]{64}$/.test(item.source_hash), `Invalid hash for ${identity}`);
  }

  const profileTemplate = JSON.parse(profileTemplateSource);
  assert(
    profileTemplate.display_name_en === "Editorial contributor",
    "Scholar profile template must use the supplied display name",
  );
  for (const unverifiedClaim of [
    "display_name_ar",
    "title_en",
    "title_ar",
    "bio_en",
    "bio_ar",
  ]) {
    assert(
      profileTemplate[unverifiedClaim] === null,
      `${unverifiedClaim} must remain null until supplied and verified`,
    );
  }

  const combined = [schema, workflow, syncFunction, translationFunction, action, profileTemplateSource]
    .join("\n");
  assert(
    !/eyJ[A-Za-z0-9_-]{30,}\.[A-Za-z0-9_-]{20,}\.[A-Za-z0-9_-]{20,}/.test(combined),
    "A JWT-like secret appears to be committed",
  );
  assert(
    !/sk-(?:proj-)?[A-Za-z0-9_-]{20,}/.test(combined),
    "An API-key-like secret appears to be committed",
  );

  assertIncludes(action, "secrets.GUIDANCE_SYNC_FUNCTION_URL", "GitHub function URL secret");
  assertIncludes(action, "secrets.GUIDANCE_SYNC_TOKEN", "GitHub sync token secret");
  assert(
    !/SUPABASE_SERVICE_ROLE_KEY\s*:/i.test(action),
    "GitHub sync should not require the database service-role key",
  );

  process.stdout.write(
    `Scholar backend validation passed (${manifest.length} manifest items, ` +
      `${policyNames.length} RLS policies).\n`,
  );
}

main().catch((error) => {
  process.stderr.write(`scholar backend validation: ${error.message}\n`);
  process.exitCode = 1;
});
