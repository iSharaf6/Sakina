import { createClient } from "jsr:@supabase/supabase-js@2.112.2";
import { handleDeletion } from "./handler.ts";
import { revokeAppleAuthorization } from "./apple.ts";

Deno.serve(async (request) => {
  const url = Deno.env.get("SUPABASE_URL");
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!url || !serviceKey) return Response.json({ error: "unavailable" }, { status: 503 });
  const admin = createClient(url, serviceKey, { auth: { persistSession: false, autoRefreshToken: false } });
  return await handleDeletion(request, {
    authenticate: async (token) => {
      const { data, error } = await admin.auth.getUser(token);
      return error ? null : data.user;
    },
    revokeApple: revokeAppleAuthorization,
    deleteUser: async (id) => {
      const { error } = await admin.auth.admin.deleteUser(id);
      if (error) throw error;
    },
  });
});
