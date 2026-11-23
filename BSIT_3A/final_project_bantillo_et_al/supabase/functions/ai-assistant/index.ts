// =============================================================================
// ai-assistant : Supabase Edge Function (Deno) between the app and Gemini.
//
// The Gemini key lives ONLY here, as Supabase secrets:
//   supabase secrets set GEMINI_API_KEY=... GEMINI_MODEL=...
// It never ships inside the Flutter app.
//
// Contract
//   POST { "message": "Do you have maroon gowns for a debut?" }
//   200  { "reply": "...", "ai_generated": true }
//   4xx/5xx { "error": "human readable message" }
//
// STATUS: STUB. It validates input and returns { reply: "stub" }.
// TODO(Member 1): implement generateReply() with the real Gemini call and a
// shop-specific system prompt (Orange 150 policies, pickup day before /
// return day after, sizes, prices from the items table, polite Taglish OK).
// =============================================================================

const GEMINI_API_KEY = Deno.env.get("GEMINI_API_KEY") ?? "";
const GEMINI_MODEL = Deno.env.get("GEMINI_MODEL") ?? "";

/** Requests to Gemini are aborted after this many milliseconds. */
const TIMEOUT_MS = 15_000;

/** Longest message we accept from the app. */
const MAX_MESSAGE_LENGTH = 2_000;

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

/** Builds a JSON response with CORS headers (needed for Flutter web). */
function json(body: Record<string, unknown>, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

/** Thrown when Gemini takes longer than TIMEOUT_MS. */
class TimeoutError extends Error {}

/**
 * Produces the assistant reply for one user message.
 * `signal` is aborted after TIMEOUT_MS; pass it to fetch().
 *
 * TODO(Member 1): replace the stub with a fetch() to the Gemini API using
 * GEMINI_API_KEY and GEMINI_MODEL, plus the Orange 150 system prompt.
 * Never return the API key or raw upstream errors to the client.
 */
async function generateReply(
  message: string,
  signal: AbortSignal,
): Promise<string> {
  if (signal.aborted) throw new TimeoutError();
  void message;
  return "stub";
}

/** Runs generateReply with a hard timeout. */
async function withTimeout(message: string): Promise<string> {
  const controller = new AbortController();
  let timer: number | undefined;
  const timeout = new Promise<never>((_, reject) => {
    timer = setTimeout(() => {
      controller.abort();
      reject(new TimeoutError());
    }, TIMEOUT_MS);
  });
  try {
    return await Promise.race([
      generateReply(message, controller.signal),
      timeout,
    ]);
  } finally {
    clearTimeout(timer);
  }
}

Deno.serve(async (req: Request): Promise<Response> => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return json({ error: "Method not allowed. Use POST." }, 405);
  }

  if (!GEMINI_API_KEY || !GEMINI_MODEL) {
    // The stub still answers so the app can be tested before secrets exist.
    console.warn("GEMINI_API_KEY or GEMINI_MODEL is not set.");
  }

  let body: unknown;
  try {
    body = await req.json();
  } catch {
    return json({ error: "Request body must be JSON." }, 400);
  }

  const raw = (body as { message?: unknown } | null)?.message;
  const message = typeof raw === "string" ? raw.trim() : "";
  if (!message) {
    return json({ error: "Field 'message' is required." }, 400);
  }
  if (message.length > MAX_MESSAGE_LENGTH) {
    return json(
      { error: `Message is too long (max ${MAX_MESSAGE_LENGTH} characters).` },
      400,
    );
  }

  try {
    const reply = await withTimeout(message);
    return json({ reply, ai_generated: true });
  } catch (error) {
    if (error instanceof TimeoutError) {
      return json(
        { error: "The assistant took too long to answer. Please try again." },
        504,
      );
    }
    console.error("ai-assistant failed:", error);
    return json(
      { error: "The assistant is unavailable right now. Please try again." },
      500,
    );
  }
});
