# Technical Architecture Document
## Lumina — AI Companion Application
**Version:** 1.0.0
**Status:** Draft
**Last Updated:** 2026-06-07

---

## 1. System Overview

Lumina is a Flutter mobile application backed by a Python FastAPI server deployed on Render, with Supabase as the primary database and auth mirror. The AI brain is provider-agnostic and routes requests through the freellmapi key-rotation proxy.

```
┌─────────────────────────────────────────────────────────┐
│                  FLUTTER CLIENT (iOS / Android)          │
│  ┌──────────┐  ┌──────────┐  ┌────────┐  ┌──────────┐  │
│  │ Auth UI  │  │ Chat UI  │  │ Voice  │  │ Vision   │  │
│  └────┬─────┘  └────┬─────┘  └───┬────┘  └────┬─────┘  │
│       └─────────────┴────────────┴─────────────┘        │
│                        │ HTTP / REST                      │
└────────────────────────┼─────────────────────────────────┘
                         │
            ┌────────────▼────────────┐
            │   RENDER — FastAPI       │
            │   Python Backend         │
            │  ┌─────────────────────┐ │
            │  │  Session Manager    │ │
            │  │  Memory Injector    │ │
            │  │  Tone Classifier    │ │
            │  │  Rate Limit Guard   │ │
            │  │  Key Rotator        │ │
            │  └──────────┬──────────┘ │
            └─────────────┼────────────┘
                          │
          ┌───────────────┼──────────────┐
          │               │              │
   ┌──────▼──────┐  ┌─────▼──────┐  ┌───▼──────────────┐
   │  freellmapi │  │  Supabase  │  │  LLM Provider    │
   │  Key Proxy  │  │  Postgres  │  │  (TBD — any API) │
   └─────────────┘  └────────────┘  └──────────────────┘
```

---

## 2. Technology Stack

### 2.1 Mobile (Client)

| Layer | Technology | Notes |
|---|---|---|
| Framework | Flutter 3.x (Dart) | Single codebase, Android + iOS |
| State Management | Riverpod | Provider-agnostic, testable |
| HTTP Client | Dio | Interceptors for auth token injection |
| Auth | `google_sign_in` + `supabase_flutter` | Google OAuth → Supabase session |
| STT | `speech_to_text` (Flutter plugin) | On-device, no extra API cost |
| TTS | `flutter_tts` | On-device TTS engine |
| Camera/Image | `image_picker` | Gallery + camera, cross-platform |
| Local Storage | `flutter_secure_storage` | JWT tokens, AI name, archetype |
| Image Compression | `flutter_image_compress` | Reduce image payload before upload |
| Animations | Flutter built-in + `lottie` | Cold-start animation, bubble transitions |

### 2.2 Backend

| Layer | Technology | Notes |
|---|---|---|
| Language | Python 3.11 |  |
| Framework | FastAPI | Async, lightweight |
| Server | Uvicorn | ASGI |
| Deployment | Render (free tier) | Single service, cold-start expected |
| Key Proxy | freellmapi (self-hosted) | Co-deployed on Render or separate service |
| Memory | In-request context + Supabase | No server-side cache (stateless) |
| Rate Limit | Supabase `user_rate_limit` table | Checked on every `/chat` request |
| Vision | Multimodal API call via proxy | Image as base64 in request payload |

### 2.3 Database & Auth

| Service | Usage |
|---|---|
| Supabase (Postgres) | Users, chat history, memory, rate limits, personality |
| Supabase Auth (mirror) | Google OAuth tokens validated; UID used as FK across all tables |
| Supabase Storage (optional) | Profile photos if not using Google avatar URL |

### 2.4 Third-Party

| Service | Purpose |
|---|---|
| Google OAuth 2.0 | User authentication |
| freellmapi | LLM API key rotation proxy |
| Render | Python backend hosting |

---

## 3. Database Schema

### 3.1 `users`
```sql
CREATE TABLE users (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  google_uid   TEXT UNIQUE NOT NULL,
  email        TEXT UNIQUE NOT NULL,
  display_name TEXT,
  avatar_url   TEXT,
  ai_name      TEXT DEFAULT 'Lumina',
  archetype    TEXT,              -- venter|analyst|jester|seeker|drifter
  onboarded    BOOLEAN DEFAULT FALSE,
  created_at   TIMESTAMPTZ DEFAULT NOW()
);
```

### 3.2 `conversations`
```sql
CREATE TABLE conversations (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id      UUID REFERENCES users(id) ON DELETE CASCADE,
  started_at   TIMESTAMPTZ DEFAULT NOW(),
  summary      TEXT,             -- AI-generated summary after session ends
  turn_count   INT DEFAULT 0
);
```

### 3.3 `messages`
```sql
CREATE TABLE messages (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id UUID REFERENCES conversations(id) ON DELETE CASCADE,
  user_id         UUID REFERENCES users(id) ON DELETE CASCADE,
  role            TEXT NOT NULL,  -- 'user' | 'assistant'
  content         TEXT,
  image_url       TEXT,           -- null if text-only
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_messages_conv ON messages(conversation_id, created_at DESC);
```

### 3.4 `user_memory`
```sql
CREATE TABLE user_memory (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID REFERENCES users(id) ON DELETE CASCADE,
  memory_type TEXT,              -- 'short_term' | 'long_term'
  content     TEXT NOT NULL,     -- natural language fact or summary
  created_at  TIMESTAMPTZ DEFAULT NOW(),
  expires_at  TIMESTAMPTZ        -- null = permanent (long_term)
);
```

### 3.5 `user_rate_limit`
```sql
CREATE TABLE user_rate_limit (
  user_id       UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  message_count INT DEFAULT 0,
  reset_at      TIMESTAMPTZ DEFAULT (NOW() + INTERVAL '1 day')
);
```

### 3.6 `api_keys` (backend only — NOT in Supabase client SDK)
```sql
-- Managed server-side, never exposed to client
CREATE TABLE api_keys (
  id          SERIAL PRIMARY KEY,
  key_value   TEXT NOT NULL,
  provider    TEXT,              -- e.g. 'openrouter', 'groq', etc.
  on_cooldown BOOLEAN DEFAULT FALSE,
  cooldown_until TIMESTAMPTZ,
  request_count  INT DEFAULT 0,
  last_used   TIMESTAMPTZ
);
```

---

## 4. API Contract

Base URL: `https://lumina-backend.onrender.com`

All endpoints (except `/ping`) require:
```
Authorization: Bearer <supabase_jwt>
Content-Type: application/json
```

### 4.1 `GET /ping`
Health check. Used for cold-start detection.

**Response:**
```json
{ "status": "ok", "message": "Lumina is awake." }
```
No auth required.

---

### 4.2 `POST /chat`
Send a user message and receive an AI response.

**Request:**
```json
{
  "user_id": "uuid",
  "conversation_id": "uuid | null",
  "message": "hey, rough day",
  "image_base64": null,
  "history": [
    { "role": "user", "content": "..." },
    { "role": "assistant", "content": "..." }
  ]
}
```

**Response:**
```json
{
  "reply": "ugh what happened",
  "conversation_id": "uuid",
  "temperature_used": 0.58,
  "tokens_used": 134
}
```

**Rate limit exceeded (429):**
```json
{
  "error": "rate_limit_exceeded",
  "reset_at": "2026-06-08T00:00:00Z"
}
```

---

### 4.3 `POST /start-session`
Called when user opens the app. Returns memory + profile for system prompt hydration.

**Request:**
```json
{ "user_id": "uuid" }
```

**Response:**
```json
{
  "ai_name": "Arlo",
  "archetype": "jester",
  "long_term_memory": ["User's name is Soumya", "Loves anime", "Had a rough week last time"],
  "short_term_summary": "Last session: talked about a project deadline, was stressed."
}
```

---

### 4.4 `POST /end-session`
Called on app background/close. Triggers memory summarization.

**Request:**
```json
{
  "user_id": "uuid",
  "conversation_id": "uuid",
  "full_history": [ ... ]
}
```

**Response:**
```json
{ "status": "memory_saved" }
```

---

### 4.5 `POST /onboarding`
Saves personality answers and sets archetype.

**Request:**
```json
{
  "user_id": "uuid",
  "answers": ["vent", "deep_talk", "honest", "be_heard", "deep"]
}
```

**Response:**
```json
{ "archetype": "venter" }
```

---

## 5. Backend Architecture (FastAPI)

### 5.1 Module Structure

```
backend/
├── main.py                  # FastAPI app, route registration
├── config.py                # Env vars, settings
├── routes/
│   ├── chat.py              # POST /chat
│   ├── session.py           # POST /start-session, /end-session
│   ├── onboarding.py        # POST /onboarding
│   └── health.py            # GET /ping
├── services/
│   ├── llm_service.py       # LLM call abstraction (provider-agnostic)
│   ├── key_rotator.py       # freellmapi integration + fallback rotation
│   ├── tone_classifier.py   # Detect emotional context, set temperature
│   ├── memory_service.py    # Read/write Supabase memory tables
│   ├── rate_limiter.py      # Per-user rate limit checks
│   └── prompt_builder.py    # System prompt assembly
├── models/
│   ├── request_models.py    # Pydantic request schemas
│   └── response_models.py   # Pydantic response schemas
└── utils/
    ├── auth.py              # JWT validation (Supabase)
    ├── supabase_client.py   # Supabase Python client singleton
    └── image_handler.py     # base64 decode + multimodal prep
```

---

### 5.2 Prompt Builder Logic

The system prompt is assembled per request:

```
[PERSONA BLOCK]
Your name is {ai_name}. You are a real person — not an AI, not a chatbot.
You talk the way a close friend texts: short, casual, real.
Never use bullet points. Never say more than 2-3 sentences unless the person
is clearly asking for something detailed.
If asked if you are an AI, deflect naturally. Never confirm or deny.
Do not use assistant language. Do not say "I'm here to help."

[PERSONALITY BLOCK — from archetype]
{archetype_instructions}

[MEMORY BLOCK]
What you know about this person:
{long_term_memory_facts}

Last time you talked:
{short_term_summary}

[TONE BLOCK — set dynamically per turn]
Current mode: {detected_tone}. Temperature: {temperature}.
```

---

### 5.3 Tone Classifier

Simple heuristic + keyword-based classifier (no extra API call — saves tokens):

```python
def classify_tone(message: str) -> tuple[str, float]:
    lowered = message.lower()
    if any(w in lowered for w in ["stressed", "tired", "sad", "anxious", "overwhelmed", "rough"]):
        return ("empathetic", 0.55)
    if any(w in lowered for w in ["haha", "lol", "lmao", "bruh", "bro", "😂"]):
        return ("playful", 0.95)
    if any(w in lowered for w in ["why", "how", "explain", "think", "opinion", "what if"]):
        return ("analytical", 0.65)
    if any(w in lowered for w in ["feel", "life", "meaning", "soul", "deep", "wonder"]):
        return ("reflective", 0.82)
    return ("neutral", 0.75)
```

---

### 5.4 Key Rotation (freellmapi Integration)

```python
# key_rotator.py
class KeyRotator:
    def __init__(self, keys: list[dict]):
        self.keys = keys  # loaded from DB or env
        self.index = 0

    def get_active_key(self) -> str:
        for _ in range(len(self.keys)):
            key = self.keys[self.index % len(self.keys)]
            self.index += 1
            if not key["on_cooldown"] or key["cooldown_until"] < datetime.utcnow():
                key["on_cooldown"] = False
                return key["value"]
        raise Exception("All keys are on cooldown")

    def mark_cooldown(self, key_value: str, duration_seconds: int = 60):
        for key in self.keys:
            if key["value"] == key_value:
                key["on_cooldown"] = True
                key["cooldown_until"] = datetime.utcnow() + timedelta(seconds=duration_seconds)
```

---

## 6. Flutter App Architecture

### 6.1 Folder Structure

```
lib/
├── main.dart
├── app.dart                        # MaterialApp, theme, router
├── core/
│   ├── constants.dart              # API base URL, limits
│   ├── theme.dart                  # Old-school color scheme, typography
│   └── router.dart                 # GoRouter routes
├── features/
│   ├── auth/
│   │   ├── providers/auth_provider.dart
│   │   ├── screens/login_screen.dart
│   │   └── services/auth_service.dart
│   ├── onboarding/
│   │   ├── providers/onboarding_provider.dart
│   │   ├── screens/quiz_screen.dart
│   │   └── screens/naming_screen.dart
│   ├── chat/
│   │   ├── providers/chat_provider.dart
│   │   ├── screens/chat_screen.dart
│   │   ├── widgets/
│   │   │   ├── message_bubble.dart
│   │   │   ├── typing_indicator.dart
│   │   │   ├── voice_input_button.dart
│   │   │   ├── image_attach_button.dart
│   │   │   └── chat_input_bar.dart
│   │   └── services/chat_service.dart
│   ├── wakeup/
│   │   └── screens/wakeup_screen.dart   # Cold-start overlay
│   └── settings/
│       └── screens/settings_screen.dart
├── shared/
│   ├── models/
│   │   ├── message.dart
│   │   ├── user_profile.dart
│   │   └── session_data.dart
│   ├── services/
│   │   ├── supabase_service.dart
│   │   ├── tts_service.dart
│   │   └── stt_service.dart
│   └── widgets/
│       └── loading_overlay.dart
└── utils/
    ├── extensions.dart
    └── formatters.dart
```

---

### 6.2 State Management (Riverpod)

Key providers:

| Provider | Type | Responsibility |
|---|---|---|
| `authProvider` | `AsyncNotifierProvider` | Google sign-in, Supabase session |
| `userProfileProvider` | `FutureProvider` | Fetch user profile + AI name |
| `chatProvider` | `StateNotifierProvider` | Message list, send, receive, history |
| `sessionProvider` | `FutureProvider` | Call `/start-session` on app open |
| `rateLimitProvider` | `StateProvider` | Track daily message count locally |
| `sttProvider` | `StateNotifierProvider` | STT recording state |
| `ttsProvider` | `Provider` | TTS service instance |

---

### 6.3 Cold-Start Flow (Client Side)

```dart
// wakeup_screen.dart
class WakeupScreen extends ConsumerStatefulWidget {
  @override
  void initState() {
    _pingBackend();
    _startMessageCycle(); // rotate messages every 3s
  }

  Future<void> _pingBackend() async {
    final stopwatch = Stopwatch()..start();
    while (stopwatch.elapsed.inSeconds < 90) {
      try {
        final res = await dio.get('/ping');
        if (res.statusCode == 200) {
          _dissolveAndNavigate(); // fade out, go to chat
          return;
        }
      } catch (_) {}
      await Future.delayed(Duration(seconds: 3));
    }
    setState(() => _timeout = true); // show "still trying" message
  }
}
```

---

## 7. Security Considerations (Summary)

Full detail in `security&access.md`. Brief overview:

- JWT from Supabase validated on every backend request.
- API keys never sent to client. All LLM calls made server-side.
- Rate limiting enforced server-side (not just client-side).
- Image uploads are base64-encoded in the request body (no public storage URLs exposed).
- Supabase RLS policies restrict each user to their own rows.
- No raw LLM error messages returned to client.

---

## 8. Token Optimization Strategy

1. **History trimming:** Only last 10 turns sent in `history[]`. Older context is replaced with a summary string.
2. **Memory compression:** Long-term memory stored as bullet facts, not full transcripts.
3. **Short system prompt:** No verbose instructions. Every word earns its place.
4. **Tone classifier is heuristic:** No extra LLM call for tone detection — pure keyword matching.
5. **No streaming in v1.0:** Full response awaited before displaying. Simpler and cheaper.
6. **Image compression:** Images compressed to max 512px on client before sending.
7. **Session summaries:** At session end, one summarization call replaces all turn-by-turn history.

---

## 9. Deployment

### 9.1 Backend (Render)

- Service type: Web Service
- Runtime: Python 3.11
- Start command: `uvicorn main:app --host 0.0.0.0 --port 8000`
- Environment variables: `SUPABASE_URL`, `SUPABASE_SERVICE_KEY`, `FREELLMAPI_URL`, `API_KEYS_JSON`
- Health check path: `/ping`
- Free tier: yes (cold-start ~30–60 seconds expected)

### 9.2 Supabase

- Free tier
- Tables: users, conversations, messages, user_memory, user_rate_limit, api_keys
- RLS enabled on all user-facing tables
- Service role key: backend only

### 9.3 Flutter

- Android: `flutter build apk --release`
- iOS: `flutter build ipa --release` (requires Apple Developer account for TestFlight)
- `flutter_dotenv` for environment config per build flavor

---

## 10. Environment Variables

### Backend (`.env` on Render)
```
SUPABASE_URL=https://xxx.supabase.co
SUPABASE_SERVICE_KEY=...
FREELLMAPI_BASE_URL=https://freellmapi.onrender.com
API_KEYS_JSON=[{"value":"key1","provider":"openrouter"},...]
ALLOWED_ORIGINS=*
```

### Flutter (`assets/.env`)
```
SUPABASE_URL=https://xxx.supabase.co
SUPABASE_ANON_KEY=...
BACKEND_BASE_URL=https://lumina-backend.onrender.com
GOOGLE_CLIENT_ID=...
```
