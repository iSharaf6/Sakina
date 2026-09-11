export type DeletionUser = { id: string; identities?: { provider: string; id: string; identity_data?: { sub?: unknown } }[] };
export type DeletionServices = {
  authenticate: (token: string) => Promise<DeletionUser | null>;
  revokeApple: (code: string, subject: string) => Promise<void>;
  deleteUser: (id: string) => Promise<void>;
};

// Authenticate before accepting any identity information from the request body.
export async function handleDeletion(request: Request, services: DeletionServices): Promise<Response> {
  const reply = (status: number, error?: string) => Response.json(error ? { error } : { deleted: true }, {
    status, headers: { "cache-control": "no-store" },
  });
  if (request.method !== "POST") return reply(405, "method_not_allowed");
  const authorization = request.headers.get("authorization");
  if (!authorization?.startsWith("Bearer ") || authorization.length <= 7) return reply(401, "unauthorized");
  try {
    const user = await services.authenticate(authorization.slice(7));
    if (!user) return reply(401, "unauthorized");
    const apple = user.identities?.find((identity) => identity.provider === "apple");
    if (apple) {
      let body: { appleAuthorizationCode?: unknown };
      try { body = await request.json(); } catch { return reply(400, "apple_authorization_required"); }
      const code = body?.appleAuthorizationCode;
      if (typeof code !== "string" || !code.trim() || code.length > 4096) return reply(400, "apple_authorization_required");
      const subject = typeof apple.identity_data?.sub === "string" ? apple.identity_data.sub : apple.id;
      if (!subject) return reply(409, "apple_identity_unavailable");
      // A wrong Apple account or a failed revocation must never delete the user.
      try { await services.revokeApple(code, subject); }
      catch { return reply(409, "apple_revocation_failed"); }
    }
    await services.deleteUser(user.id);
    return reply(200);
  } catch { return reply(500, "deletion_failed"); }
}
