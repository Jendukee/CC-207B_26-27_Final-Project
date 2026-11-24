# Assistant

- **Owner:** Member 1
- **Purpose:** Guest-accessible style and rental chat through the `ai-assistant` Supabase Edge Function.
- **Gemini key:** Create a key in [Google AI Studio](https://aistudio.google.com/app/apikey) and store it as a Supabase secret. Do not put it in `env.json` or Flutter code.

From the Flutter project directory, set the server-side secrets and deploy:

```sh
cp supabase/functions/.env.example supabase/functions/.env
# Put your key in supabase/functions/.env, then:
supabase secrets set --env-file supabase/functions/.env
supabase functions deploy ai-assistant
```

In the local, gitignored `env.json`, set `AI_FUNCTION_NAME` to `ai-assistant`.
The app sends requests to Supabase; the Edge Function calls Gemini and loads
public item name, size, type and price data for its response.

For local Edge Function testing, start Supabase locally and run:

```sh
supabase functions serve ai-assistant --env-file supabase/functions/.env
```

Never commit `supabase/functions/.env` or paste the Gemini key into Flutter,
`env.json`, chat, or screenshots.
