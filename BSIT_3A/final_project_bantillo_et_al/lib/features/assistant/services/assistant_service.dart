// Talks to the AI assistant through the Supabase Edge Function named in
// Env.aiFunctionName (default "ai-assistant"). The app NEVER calls Gemini
// directly and never holds the Gemini key.
//
// Edge function contract:
//   request  { "message": "..." }
//   success  { "reply": "...", "ai_generated": true }
//   failure  { "error": "..." }
//
// OWNER: Member 1. Every method is a stub that throws UnimplementedError
// until Member 1 implements it.

/// Sends chat messages to the ai-assistant edge function.
class AssistantService {
  /// Sends [message] and returns the assistant's reply text.
  /// Show the reply with an AiLabel. Throw a friendly error on timeout.
  Future<String> sendMessage(String message) => throw UnimplementedError(
        'TODO(Member 1): invoke the edge function via '
        'SupabaseService.client.functions.invoke(Env.aiFunctionName, ...)',
      );
}
