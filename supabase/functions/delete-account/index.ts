import { createClient } from "jsr:@supabase/supabase-js@2.112.2";

// The native client never chooses a user ID. Resolve the authenticated caller
// server-side, then delete only that account with the server's service credential.
Deno.serve(async (request) => {
  const reply = (status: number, body: object) => Response.json(body, {
    status, headers: { "cache-control": "no-store" },
  });
  if (request.method !== "POST") return reply(405, { error: "method_not_allowed" });
  const authorization = request.headers.get("authorization");
  if (!authorization?.startsWith("Bearer ")) return reply(401, { error: "unauthorized" });
  const url = Deno.env.get("SUPABASE_URL");
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!url || !serviceKey) return reply(503, { error: "unavailable" });
  const admin = createClient(url, serviceKey, { auth: { persistSession: false, autoRefreshToken: false } });
  const { data, error } = await admin.auth.getUser(authorization.slice(7));
  if (error || !data.user) return reply(401, { error: "unauthorized" });
  const result = await admin.auth.admin.deleteUser(data.user.id);
  if (result.error) return reply(500, { error: "deletion_failed" });
  return reply(200, { deleted: true });
});
