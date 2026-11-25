// Supabase Edge Function: the owner manages staff logins
// (More -> Staff accounts in the app). Deploy with:
//   supabase functions deploy manage-staff
//
// Why a function: creating, banning and changing passwords of OTHER users
// needs the service role key, which must never be in the app, env.json or
// the repo. Supabase provides it to the function as
// SUPABASE_SERVICE_ROLE_KEY; it stays on the server.
//
// Every request:
//   1. reads the caller's JWT from the Authorization header,
//   2. gets that user and checks profiles.role = 'owner'
//      (else 403 "Only the owner can manage staff accounts."),
//   3. runs ONE action from the JSON body { action, ... }:
//        create          { email, password, full_name, phone? }
//        disable         { user_id }   ban the login, keep the profile
//        enable          { user_id }   lift the ban
//        reset_password  { user_id, new_password }
//   4. answers JSON: { ok: true, ... } or { error: "<friendly text>" }.
// The whole request is limited to 15 seconds.
//
// OWNER: Member 3 (shop_dashboard).

import {
  createClient,
  type SupabaseClient,
} from "npm:@supabase/supabase-js@2.45.4";

// ---------------------------------------------------------------------------
// Configuration (all provided by Supabase to every Edge Function).
// ---------------------------------------------------------------------------
const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SUPABASE_ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY") ?? "";
const SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

/** Longest a request may take, in milliseconds. */
const TIMEOUT_MS = 15_000;

/** "Banned forever" (100 years) for disabled staff. */
const BAN_FOREVER = "876000h";

const OWNER_ONLY = "Only the owner can manage staff accounts.";

// Same rules as the app (lib/core/utils/validators.dart,
// lib/features/shop_dashboard/models/staff_member.dart).
const EMAIL_PATTERN = /^[^@\s]+@[^@\s]+\.[^@\s]+$/;
const PHONE_PATTERN = /^09[0-9]{9}$/;
const UUID_PATTERN =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

// ---------------------------------------------------------------------------
// Responses: JSON with CORS headers (the app on web calls from a browser).
// ---------------------------------------------------------------------------
const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function json(body: Record<string, unknown>, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

/** An error whose message is safe to show to the owner. */
class HttpError extends Error {
  constructor(message: string, readonly status = 400) {
    super(message);
  }
}

// ---------------------------------------------------------------------------
// Validation helpers (friendly messages, same wording as the app).
// ---------------------------------------------------------------------------

/** A trimmed string from the body, or "" when missing / not a string. */
function text(value: unknown): string {
  return typeof value === "string" ? value.trim() : "";
}

/** At least 8 characters with at least one letter and one number. */
function checkPassword(password: unknown): string {
  if (typeof password !== "string" || password.length < 8) {
    throw new HttpError("Use at least 8 characters for the password.");
  }
  if (!/[A-Za-z]/.test(password) || !/[0-9]/.test(password)) {
    throw new HttpError("The password needs at least one letter and one number.");
  }
  if (password.length > 72) {
    // Supabase Auth (bcrypt) ignores anything past 72 bytes.
    throw new HttpError("Use at most 72 characters for the password.");
  }
  return password;
}

function checkUserId(value: unknown): string {
  const id = text(value);
  if (!UUID_PATTERN.test(id)) throw new HttpError("Choose a staff account.");
  return id;
}

// ---------------------------------------------------------------------------
// Supabase clients. A custom fetch shares ONE abort signal, so every call
// made for this request stops when the 15 second limit is reached.
// ---------------------------------------------------------------------------
function clients(authorization: string, signal: AbortSignal) {
  const timedFetch: typeof fetch = (input, init) =>
    fetch(input, { ...init, signal });
  const options = {
    auth: { persistSession: false, autoRefreshToken: false },
    global: { fetch: timedFetch },
  };
  // Acts AS the caller (their JWT): used only to find out who is calling.
  const caller = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
    ...options,
    global: { ...options.global, headers: { Authorization: authorization } },
  });
  // Service role: bypasses RLS. Used only after the owner check.
  const admin = createClient(SUPABASE_URL, SERVICE_ROLE_KEY, options);
  return { caller, admin };
}

// ---------------------------------------------------------------------------
// Step 2: the caller must be the owner. Returns the owner's user id.
// ---------------------------------------------------------------------------
async function requireOwner(
  caller: SupabaseClient,
  admin: SupabaseClient,
  authorization: string,
): Promise<string> {
  const jwt = authorization.replace(/^Bearer\s+/i, "");
  const { data, error } = await caller.auth.getUser(jwt);
  if (error || !data.user) throw new HttpError(OWNER_ONLY, 403);

  const { data: profile, error: profileError } = await admin
    .from("profiles")
    .select("role")
    .eq("id", data.user.id)
    .maybeSingle();
  if (profileError) throw new HttpError("Could not check your account.", 500);
  if (profile?.role !== "owner") throw new HttpError(OWNER_ONLY, 403);
  return data.user.id;
}

// ---------------------------------------------------------------------------
// The target of disable / enable / reset_password: must be a STAFF account
// (never the owner, never the caller, never a customer).
// ---------------------------------------------------------------------------
async function requireStaffTarget(
  admin: SupabaseClient,
  userId: string,
  ownerId: string,
): Promise<{ full_name: string | null }> {
  if (userId === ownerId) {
    throw new HttpError("You cannot change your own account here.");
  }
  const { data, error } = await admin
    .from("profiles")
    .select("role, full_name")
    .eq("id", userId)
    .maybeSingle();
  if (error) throw new HttpError("Could not load this account.", 500);
  if (!data) throw new HttpError("This account could not be found.", 404);
  if (data.role === "owner") {
    throw new HttpError("The owner account cannot be changed.");
  }
  if (data.role !== "staff") throw new HttpError("This is not a staff account.");
  return { full_name: data.full_name };
}

// ---------------------------------------------------------------------------
// Action: create a staff login.
// ---------------------------------------------------------------------------
async function createStaff(
  admin: SupabaseClient,
  body: Record<string, unknown>,
): Promise<Response> {
  // Validate everything before touching Auth.
  const email = text(body.email).toLowerCase();
  if (!EMAIL_PATTERN.test(email)) {
    throw new HttpError("Enter a valid email address.");
  }
  const password = checkPassword(body.password);
  const fullName = text(body.full_name).replace(/\s+/g, " ");
  if (!fullName) throw new HttpError("Enter the staff member's full name.");
  if (fullName.length > 120) {
    throw new HttpError("Keep the name to 120 characters or less.");
  }
  const phone = text(body.phone);
  if (phone && !PHONE_PATTERN.test(phone)) {
    throw new HttpError("Use 11 digits starting with 09, e.g. 09171234567.");
  }

  // The login, already confirmed (staff never get a confirmation email).
  const { data, error } = await admin.auth.admin.createUser({
    email,
    password,
    email_confirm: true,
    user_metadata: { full_name: fullName, ...(phone ? { phone } : {}) },
  });
  if (error || !data.user) {
    const message = (error?.message ?? "").toLowerCase();
    if (
      error?.code === "email_exists" ||
      message.includes("already been registered") ||
      message.includes("already registered") ||
      message.includes("already exists")
    ) {
      throw new HttpError("An account with this email already exists.", 409);
    }
    if (error?.code === "weak_password") {
      throw new HttpError(
        "This password is too weak. Use at least 8 characters with a letter and a number.",
      );
    }
    console.error("createUser failed:", error);
    throw new HttpError("Could not create the staff account. Please try again.", 500);
  }

  // The signup trigger (0001 handle_new_user) made a customer profile.
  // Make it staff, with the name and phone. Upsert in case the row is
  // missing.
  const userId = data.user.id;
  const { error: profileError } = await admin.from("profiles").upsert(
    {
      id: userId,
      role: "staff",
      full_name: fullName,
      phone: phone || null,
      is_disabled: false,
    },
    { onConflict: "id" },
  );
  if (profileError) {
    // Do not leave a half-made login behind: remove it again.
    console.error("profile update failed:", profileError);
    await admin.auth.admin.deleteUser(userId).catch((e) =>
      console.error("cleanup deleteUser failed:", e)
    );
    throw new HttpError("Could not create the staff account. Please try again.", 500);
  }

  return json({ ok: true, user_id: userId, email, full_name: fullName });
}

// ---------------------------------------------------------------------------
// Action: disable (ban) or enable (unban) a staff login. The profile and
// every booking stay; only signing in is blocked.
// ---------------------------------------------------------------------------
async function setDisabled(
  admin: SupabaseClient,
  body: Record<string, unknown>,
  ownerId: string,
  disabled: boolean,
): Promise<Response> {
  const userId = checkUserId(body.user_id);
  await requireStaffTarget(admin, userId, ownerId);

  const { error } = await admin.auth.admin.updateUserById(userId, {
    ban_duration: disabled ? BAN_FOREVER : "none",
  });
  if (error) {
    console.error("ban change failed:", error);
    throw new HttpError(
      disabled
        ? "Could not disable this account. Please try again."
        : "Could not enable this account. Please try again.",
      500,
    );
  }

  const { error: flagError } = await admin
    .from("profiles")
    .update({ is_disabled: disabled })
    .eq("id", userId);
  if (flagError) {
    // Keep Auth and the flag in step: undo the ban change.
    console.error("is_disabled update failed:", flagError);
    await admin.auth.admin
      .updateUserById(userId, { ban_duration: disabled ? "none" : BAN_FOREVER })
      .catch((e) => console.error("ban rollback failed:", e));
    throw new HttpError("Could not update this account. Please try again.", 500);
  }

  return json({ ok: true, user_id: userId, is_disabled: disabled });
}

// ---------------------------------------------------------------------------
// Action: set a new password for a staff login.
// ---------------------------------------------------------------------------
async function resetPassword(
  admin: SupabaseClient,
  body: Record<string, unknown>,
  ownerId: string,
): Promise<Response> {
  const userId = checkUserId(body.user_id);
  const password = checkPassword(body.new_password);
  await requireStaffTarget(admin, userId, ownerId);

  const { error } = await admin.auth.admin.updateUserById(userId, { password });
  if (error) {
    if (error.code === "weak_password") {
      throw new HttpError(
        "This password is too weak. Use at least 8 characters with a letter and a number.",
      );
    }
    console.error("password reset failed:", error);
    throw new HttpError("Could not change the password. Please try again.", 500);
  }
  return json({ ok: true, user_id: userId });
}

// ---------------------------------------------------------------------------
// Entry point.
// ---------------------------------------------------------------------------
Deno.serve(async (req: Request): Promise<Response> => {
  // Browser pre-flight.
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return json({ error: "Use POST." }, 405);

  // Misconfigured deployment: say so without revealing anything.
  if (!SUPABASE_URL || !SUPABASE_ANON_KEY || !SERVICE_ROLE_KEY) {
    console.error("manage-staff: missing Supabase environment variables");
    return json({ error: "Staff management is not set up on the server." }, 500);
  }

  // Step 1: the caller's JWT.
  const authorization = req.headers.get("Authorization") ?? "";
  if (!/^Bearer\s+\S+/i.test(authorization)) return json({ error: OWNER_ONLY }, 403);

  // The 15 second limit for everything below.
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), TIMEOUT_MS);

  try {
    // The body: { action, ... }.
    let body: Record<string, unknown>;
    try {
      const parsed = await req.json();
      if (typeof parsed !== "object" || parsed === null || Array.isArray(parsed)) {
        throw new Error("not an object");
      }
      body = parsed as Record<string, unknown>;
    } catch {
      throw new HttpError("The request was not understood.");
    }

    const { caller, admin } = clients(authorization, controller.signal);

    // Step 2: owner only.
    const ownerId = await requireOwner(caller, admin, authorization);

    // Step 3: the action.
    switch (text(body.action)) {
      case "create":
        return await createStaff(admin, body);
      case "disable":
        return await setDisabled(admin, body, ownerId, true);
      case "enable":
        return await setDisabled(admin, body, ownerId, false);
      case "reset_password":
        return await resetPassword(admin, body, ownerId);
      default:
        throw new HttpError("Unknown action.");
    }
  } catch (error) {
    // Step 4: friendly errors only; details go to the function logs.
    if (error instanceof HttpError) {
      return json({ error: error.message }, error.status);
    }
    if (controller.signal.aborted) {
      return json({ error: "The server took too long. Please try again." }, 504);
    }
    console.error("manage-staff failed:", error);
    return json({ error: "Something went wrong. Please try again." }, 500);
  } finally {
    clearTimeout(timer);
  }
});
