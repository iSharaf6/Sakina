import { handleDeletion, type DeletionServices, type DeletionUser } from "./handler.ts";
const assert = (condition: unknown, message = "assertion failed") => { if (!condition) throw new Error(message); };
const appleUser: DeletionUser = { id: "signed-in-user", identities: [{ provider: "apple", id: "identity-row", identity_data: { sub: "apple-subject" } }] };
function fixture(user: DeletionUser | null = appleUser, rejectRevocation = false) {
  const calls: string[] = [];
  const services: DeletionServices = {
    authenticate: async (token) => { calls.push(`authenticate:${token}`); return user; },
    revokeApple: async (code, subject) => { calls.push(`revoke:${code}:${subject}`); if (rejectRevocation) throw new Error("Apple rejected proof"); },
    deleteUser: async (id) => { calls.push(`delete:${id}`); },
  };
  return { services, calls };
}
const request = (body: unknown = {}, token = "session") => new Request("https://example.test", {
  method: "POST", headers: token ? { authorization: `Bearer ${token}` } : {}, body: JSON.stringify(body),
});
Deno.test("missing authentication never calls a backend", async () => {
  const f = fixture(); assert((await handleDeletion(request({}, ""), f.services)).status === 401); assert(f.calls.length === 0);
});
Deno.test("invalid session cannot revoke or delete", async () => {
  const f = fixture(null); assert((await handleDeletion(request(), f.services)).status === 401); assert(f.calls.length === 1);
});
Deno.test("GET cannot delete an account", async () => {
  const f = fixture(); assert((await handleDeletion(new Request("https://example.test"), f.services)).status === 405); assert(f.calls.length === 0);
});
Deno.test("Apple identity requires fresh authorization even when linked to email", async () => {
  const f = fixture({ ...appleUser, identities: [{ provider: "email", id: "email" }, ...appleUser.identities!] });
  assert((await handleDeletion(request({ userID: "victim" }), f.services)).status === 400); assert(f.calls.length === 1);
});
Deno.test("failed Apple revocation preserves the Supabase account", async () => {
  const f = fixture(appleUser, true); assert((await handleDeletion(request({ appleAuthorizationCode: "fresh-code" }), f.services)).status === 409);
  assert(!f.calls.some((call) => call.startsWith("delete:")));
});
Deno.test("Apple revocation precedes deletion and uses the authenticated identity", async () => {
  const f = fixture(); const result = await handleDeletion(request({ appleAuthorizationCode: "fresh-code", userID: "victim", appleSubject: "victim-apple" }), f.services);
  assert(result.status === 200); assert(f.calls.join("|") === "authenticate:session|revoke:fresh-code:apple-subject|delete:signed-in-user");
});
Deno.test("email deletion ignores a caller-supplied target user", async () => {
  const f = fixture({ id: "signed-in-user", identities: [{ provider: "email", id: "email" }] });
  assert((await handleDeletion(request({ userID: "victim" }), f.services)).status === 200);
  assert(f.calls.join("|") === "authenticate:session|delete:signed-in-user");
});
Deno.test("malformed Apple proof fails without deleting", async () => {
  for (const code of [null, 123, "", " ", "a".repeat(4097)]) {
    const f = fixture(); assert((await handleDeletion(request({ appleAuthorizationCode: code }), f.services)).status === 400); assert(f.calls.length === 1);
  }
});
Deno.test("feedback is optional and is recorded without identity after deletion", async () => {
  const f = fixture({ id: "caller" });
  f.services.saveFeedback = async (reason, feedback) => { f.calls.push(`feedback:${reason}:${feedback.length}`); };
  assert((await handleDeletion(request({ reason: "technical", feedback: "a".repeat(1200), userID: "victim" }), f.services)).status === 200);
  assert(f.calls.join("|") === "authenticate:session|delete:caller|feedback:technical:1000");
});
Deno.test("feedback storage failure cannot block deletion", async () => {
  const f = fixture({ id: "caller" });
  f.services.saveFeedback = async () => { throw new Error("offline"); };
  assert((await handleDeletion(request({ feedback: "A suggestion" }), f.services)).status === 200);
});
Deno.test("blank feedback never creates a retained record", async () => {
  const f = fixture({ id: "caller" });
  f.services.saveFeedback = async () => { throw new Error("must not be called"); };
  assert((await handleDeletion(request({ reason: "invalid-reason", feedback: " " }), f.services)).status === 200);
  assert(f.calls.join("|") === "authenticate:session|delete:caller");
});
