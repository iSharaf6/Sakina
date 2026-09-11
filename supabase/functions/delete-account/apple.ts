import { createRemoteJWKSet, importPKCS8, jwtVerify, SignJWT } from "npm:jose@6.1.0";

const appleKeys = createRemoteJWKSet(new URL("https://appleid.apple.com/auth/keys"));

export async function revokeAppleAuthorization(code: string, expectedSubject: string) {
  const clientID = Deno.env.get("APPLE_SIGNIN_CLIENT_ID");
  const teamID = Deno.env.get("APPLE_SIGNIN_TEAM_ID");
  const keyID = Deno.env.get("APPLE_SIGNIN_KEY_ID");
  const pem = Deno.env.get("APPLE_SIGNIN_PRIVATE_KEY");
  if (!clientID || !teamID || !keyID || !pem) throw new Error("Apple revocation is not configured");
  const key = await importPKCS8(pem.replaceAll("\\n", "\n"), "ES256");
  const secret = await new SignJWT({}).setProtectedHeader({ alg: "ES256", kid: keyID })
    .setIssuer(teamID).setAudience("https://appleid.apple.com").setSubject(clientID)
    .setIssuedAt().setExpirationTime("5m").sign(key);
  const exchange = await fetch("https://appleid.apple.com/auth/token", {
    method: "POST", signal: AbortSignal.timeout(10000),
    body: new URLSearchParams({ client_id: clientID, client_secret: secret, code, grant_type: "authorization_code" }),
  });
  if (!exchange.ok) throw new Error("Apple authorization failed");
  const tokens = await exchange.json();
  if (typeof tokens.id_token !== "string" || typeof tokens.refresh_token !== "string") throw new Error("Missing Apple token");
  const { payload } = await jwtVerify(tokens.id_token, appleKeys, { issuer: "https://appleid.apple.com", audience: clientID });
  if (payload.sub !== expectedSubject) throw new Error("Apple account does not match");
  const result = await fetch("https://appleid.apple.com/auth/revoke", {
    method: "POST", signal: AbortSignal.timeout(10000),
    body: new URLSearchParams({ client_id: clientID, client_secret: secret, token: tokens.refresh_token, token_type_hint: "refresh_token" }),
  });
  if (!result.ok) throw new Error("Apple revocation failed");
  // No Apple authorization codes or tokens are logged or retained.
}
