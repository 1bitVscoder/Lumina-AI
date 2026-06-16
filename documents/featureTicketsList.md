# Feature Tickets List
## Lumina — AI Companion Application
**Version:** 1.0.0
**Status:** Draft
**Last Updated:** 2026-06-07

---

## Ticket Conventions

**ID format:** `LUM-[EPIC]-[NUMBER]`
**Priority:** P0 (blocker) → P1 (critical) → P2 (important) → P3 (nice to have)
**Size:** XS (< 2h) · S (2–4h) · M (4–8h) · L (1–2d) · XL (2–4d)
**Status column headers:** `TODO` · `IN PROGRESS` · `DONE`

---

## Epic Index

| Epic | Code | Description |
|---|---|---|
| Infrastructure | INFRA | Project setup, CI, deployments |
| Authentication | AUTH | Google OAuth, Supabase session |
| Onboarding | ONB | Quiz, AI naming |
| Chat Core | CHAT | Message UI, bubbles, history |
| AI Brain | AI | Backend LLM, prompts, memory, tone |
| Voice & Vision | AV | STT, TTS, image input |
| Cold Start | COLD | Render wake-up screen |
| Rate Limiting | RATE | Per-user daily limits |
| Key Rotation | KEYS | freellmapi proxy integration |
| Settings | SET | User preferences, account management |

---

## INFRA — Infrastructure

| ID | Title | Priority | Size | Notes |
|---|---|---|---|---|
| LUM-INFRA-01 | Initialize Flutter project (`flutter create lumina`) with folder structure per `technicalArchitecture.md` | P0 | S | Android + iOS targets |
| LUM-INFRA-02 | Configure `go_router`, `riverpod`, `dio`, `flutter_secure_storage`, `supabase_flutter` packages | P0 | S | `pubspec.yaml` setup |
| LUM-INFRA-03 | Set up `flutter_dotenv` with `.env` files for dev/prod build flavors | P0 | XS | Never commit `.env` |
| LUM-INFRA-04 | Initialize FastAPI Python project structure per `technicalArchitecture.md` | P0 | S | `requirements.txt`, `main.py`, folder tree |
| LUM-INFRA-05 | Create Supabase project, run all schema migrations from `technicalArchitecture.md` | P0 | M | All 6 tables, indexes, RLS policies |
| LUM-INFRA-06 | Deploy FastAPI to Render (manual deploy first, CI later) | P0 | M | Environment variables, health check |
| LUM-INFRA-07 | Configure Supabase RLS policies for all user-facing tables | P0 | M | Per `security&access.md` §3.1 |
| LUM-INFRA-08 | Set up Google OAuth credentials (Google Cloud Console, SHA1 fingerprint for Android) | P0 | M | OAuth client ID for both platforms |
| LUM-INFRA-09 | Add `LuminaColors`, `LuminaTypography`, `LuminaSpacing` tokens to `core/theme.dart` | P1 | S | Per `frontendSpec.md` §2 |
| LUM-INFRA-10 | Add Google Fonts dependencies (`Lora`, `JetBrains Mono`, `DM Sans`) via `google_fonts` package | P1 | XS |  |
| LUM-INFRA-11 | Configure `go_router` with all routes + redirect logic | P1 | S | Per `frontendSpec.md` §5 |
| LUM-INFRA-12 | Set up `flutter_lints` and analysis options | P2 | XS | Code quality baseline |

---

## AUTH — Authentication

| ID | Title | Priority | Size | Notes |
|---|---|---|---|---|
| LUM-AUTH-01 | Implement Google Sign-In flow using `google_sign_in` + `supabase_flutter` | P0 | M | Per `technicalArchitecture.md` §2.1 |
| LUM-AUTH-02 | Implement Supabase session persistence via `flutter_secure_storage` | P0 | S | Store JWT + refresh token |
| LUM-AUTH-03 | Implement silent re-auth on app open (check stored token, auto-refresh if needed) | P0 | S | `authProvider` in Riverpod |
| LUM-AUTH-04 | Implement backend JWT validation middleware (`utils/auth.py`) | P0 | S | Validate Supabase JWTs |
| LUM-AUTH-05 | Add `user_id` cross-check against JWT `sub` in all protected routes | P0 | S | Prevent user impersonation |
| LUM-AUTH-06 | Build `LoginScreen` UI per `frontendSpec.md` §3.2 | P0 | M | Google button, wordmark, tagline |
| LUM-AUTH-07 | Implement sign-out flow: clear secure storage, invalidate Supabase session, navigate to login | P1 | S |  |
| LUM-AUTH-08 | Implement "Delete My Account" endpoint (`DELETE /account`) with cascade Supabase deletion | P1 | M | Per `security&access.md` §7.3 |
| LUM-AUTH-09 | Handle 401 Unauthorized from backend: attempt token refresh → re-login if fails | P1 | S | Dio interceptor |
| LUM-AUTH-10 | Upsert user row in Supabase `users` table on first Google sign-in | P0 | S | `google_uid`, `email`, `display_name`, `avatar_url` |

---

## ONB — Onboarding

| ID | Title | Priority | Size | Notes |
|---|---|---|---|---|
| LUM-ONB-01 | Build `QuizScreen` layout: progress bar, animated question cards, option buttons | P0 | L | Per `frontendSpec.md` §3.3 |
| LUM-ONB-02 | Implement quiz state machine: track current question, selected answer, advance logic | P0 | M | `onboardingProvider` |
| LUM-ONB-03 | Implement `POST /onboarding` backend endpoint: receive answers, compute archetype, save to `users` | P0 | M | Archetype scoring logic |
| LUM-ONB-04 | Build `NamingScreen`: text input, validation (3–20 chars), save AI name | P0 | M | Per `frontendSpec.md` §3.4 |
| LUM-ONB-05 | Save AI name to Supabase `users.ai_name` and locally to `flutter_secure_storage` | P0 | S |  |
| LUM-ONB-06 | Set `users.onboarded = true` after naming screen completes | P0 | XS |  |
| LUM-ONB-07 | Quiz slide-in animation per `frontendSpec.md` §6 (SlideTransition + option bounce) | P1 | S |  |
| LUM-ONB-08 | Skip onboarding for returning users (check `onboarded` flag on auth) | P0 | XS | In `go_router` redirect |

---

## CHAT — Chat Core

| ID | Title | Priority | Size | Notes |
|---|---|---|---|---|
| LUM-CHAT-01 | Build `ChatScreen` scaffold: app bar, message list, input bar | P0 | L | Per `frontendSpec.md` §3.5 |
| LUM-CHAT-02 | Implement `MessageBubble` widget: user + AI variants, tail, timestamp, image support | P0 | L | Per `frontendSpec.md` §3.5.3 |
| LUM-CHAT-03 | Implement `TypingIndicator` widget: 3-dot animated bubble | P0 | S |  |
| LUM-CHAT-04 | Implement `ChatInputBar`: text field, attach icon, mic icon, send button | P0 | M | Per `frontendSpec.md` §3.5.4 |
| LUM-CHAT-05 | Implement `chatProvider`: manage message list, send message, receive reply, loading state | P0 | L | Riverpod StateNotifier |
| LUM-CHAT-06 | Auto-scroll to latest message on new message (including after keyboard appears) | P0 | S |  |
| LUM-CHAT-07 | Load chat history from Supabase `messages` table on session start (last 30 messages) | P1 | M | Paginated, oldest-first |
| LUM-CHAT-08 | Persist each sent message (user + AI) to Supabase `messages` after successful API round-trip | P0 | S |  |
| LUM-CHAT-09 | Display date separator labels between messages (Today / Yesterday / Jun 5) | P2 | S |  |
| LUM-CHAT-10 | Implement pull-to-load-more (older messages) in chat list | P2 | M | Cursor-based pagination |
| LUM-CHAT-11 | Show/hide send button based on input field empty state | P0 | XS |  |
| LUM-CHAT-12 | Bubble appear animation: fade + slide-up 10px, 200ms per `frontendSpec.md` §6 | P1 | S |  |
| LUM-CHAT-13 | App bar: AI name (Lora font), initials avatar circle, "Online" subtitle | P1 | S |  |
| LUM-CHAT-14 | Image message bubble: compressed image preview, optional caption | P1 | M |  |
| LUM-CHAT-15 | `RateLimitBanner` component: disables input, shows reset time, AI name in message | P1 | S |  |

---

## AI — AI Brain (Backend)

| ID | Title | Priority | Size | Notes |
|---|---|---|---|---|
| LUM-AI-01 | Implement `prompt_builder.py`: assemble system prompt from archetype + memory + tone | P0 | M | Per `technicalArchitecture.md` §5.2 |
| LUM-AI-02 | Implement archetype instruction blocks for all 5 archetypes (Venter, Analyst, Jester, Seeker, Drifter) | P0 | M | Stored as prompt fragments in `config.py` |
| LUM-AI-03 | Implement `tone_classifier.py`: keyword-based tone + temperature selection | P0 | S | Per `technicalArchitecture.md` §5.3 |
| LUM-AI-04 | Implement `llm_service.py`: provider-agnostic LLM call abstraction, accepts messages array + system prompt | P0 | M | `requests` or `httpx` |
| LUM-AI-05 | Implement `POST /chat` route: validate JWT, check rate limit, build prompt, call LLM, save messages, return reply | P0 | L | Core endpoint |
| LUM-AI-06 | Implement history trimming: send only last 10 turns; inject summary for older context | P0 | S | Per `technicalArchitecture.md` §8 |
| LUM-AI-07 | Implement `memory_service.py`: read long-term + short-term memory from Supabase, inject into prompt | P0 | M |  |
| LUM-AI-08 | Implement `POST /start-session`: fetch user profile, memory, return to client | P0 | M |  |
| LUM-AI-09 | Implement `POST /end-session`: trigger one summarization LLM call, save to `user_memory` | P1 | M | Called on app backgrounded |
| LUM-AI-10 | Implement AI identity deflection in system prompt (never confirm/deny AI nature) | P0 | S | Per `productRequirements.md` §5.8 |
| LUM-AI-11 | Implement input length validation: 1000 char max, return 400 if exceeded | P1 | XS |  |
| LUM-AI-12 | Implement vision support in `/chat`: accept `image_base64`, include in multimodal LLM call | P1 | M |  |
| LUM-AI-13 | Error handling: never return raw LLM errors to client; map to friendly error responses | P1 | S |  |

---

## AV — Voice & Vision

| ID | Title | Priority | Size | Notes |
|---|---|---|---|---|
| LUM-AV-01 | Integrate `speech_to_text` plugin for STT: request mic permission, start/stop recording | P1 | M | On-device, Android + iOS |
| LUM-AV-02 | Implement `VoiceInputButton` widget: mic icon, red pulse animation during recording | P1 | M | Per `frontendSpec.md` §4.3 |
| LUM-AV-03 | On STT result: populate transcript into chat input field (user can edit before send) | P1 | S |  |
| LUM-AV-04 | Integrate `flutter_tts` for AI message TTS output | P1 | M |  |
| LUM-AV-05 | Add TTS play button to AI bubbles (speaker icon, tap to read aloud) | P1 | S |  |
| LUM-AV-06 | Add Auto-play TTS setting toggle in Settings (default: off) | P2 | XS |  |
| LUM-AV-07 | Integrate `image_picker` for attach button: gallery + camera options | P1 | M | Request permissions |
| LUM-AV-08 | Compress selected image via `flutter_image_compress` before base64 encoding (max 512px wide) | P1 | S |  |
| LUM-AV-09 | Send image as base64 in `/chat` request body with optional caption | P1 | S |  |
| LUM-AV-10 | Handle STT permission denied: show friendly snackbar, fallback to keyboard | P2 | XS |  |
| LUM-AV-11 | Handle camera/gallery permission denied: same graceful fallback | P2 | XS |  |

---

## COLD — Cold Start Experience

| ID | Title | Priority | Size | Notes |
|---|---|---|---|---|
| LUM-COLD-01 | Implement `WakeupScreen`: full-screen overlay, AI name, rotating messages | P0 | M | Per `frontendSpec.md` §3.1 |
| LUM-COLD-02 | Implement `GET /ping` backend endpoint (no auth, returns `{status: ok}`) | P0 | XS |  |
| LUM-COLD-03 | Implement ping polling loop: retry every 3s until 200 or 90s timeout | P0 | S | Per `technicalArchitecture.md` §6.3 |
| LUM-COLD-04 | Implement rotating message cycle with `AnimatedSwitcher` fade, 3s interval | P1 | S |  |
| LUM-COLD-05 | Implement graceful overlay dismiss: fade-out + navigate to chat on `/ping` success | P0 | S |  |
| LUM-COLD-06 | Implement timeout error state (> 90s): change message to amber/red "still trying" | P1 | XS |  |
| LUM-COLD-07 | Ensure wakeup screen shows AI name (from `flutter_secure_storage` if returning user, or default "Lumina") | P1 | XS |  |

---

## RATE — Rate Limiting

| ID | Title | Priority | Size | Notes |
|---|---|---|---|---|
| LUM-RATE-01 | Implement `rate_limiter.py` service: check + increment `user_rate_limit` table on each `/chat` | P0 | M | Per `security&access.md` §4 |
| LUM-RATE-02 | Return HTTP 429 with `reset_at` timestamp when limit exceeded | P0 | XS |  |
| LUM-RATE-03 | Handle 429 response in Flutter: show `RateLimitBanner`, disable input field | P0 | S |  |
| LUM-RATE-04 | Reset counter logic: check `reset_at` < now, reset to 0 + set new `reset_at` | P0 | S |  |
| LUM-RATE-05 | Create `user_rate_limit` row on first `/chat` for new users | P0 | XS | Part of LUM-RATE-01 |
| LUM-RATE-06 | Display remaining message count somewhere subtle in chat UI (optional — P3) | P3 | S | Could be in ⋮ menu |

---

## KEYS — Key Rotation (freellmapi)

| ID | Title | Priority | Size | Notes |
|---|---|---|---|---|
| LUM-KEYS-01 | Set up freellmapi proxy: clone repo, configure, deploy to Render (or co-deploy) | P0 | L | Review freellmapi README for config |
| LUM-KEYS-02 | Implement `key_rotator.py`: round-robin key selection, cooldown marking | P0 | M | Per `technicalArchitecture.md` §5.4 |
| LUM-KEYS-03 | Detect quota errors (429 from LLM provider) and trigger key rotation automatically | P0 | S |  |
| LUM-KEYS-04 | Load API keys from environment variable (`API_KEYS_JSON`) on backend startup | P0 | XS |  |
| LUM-KEYS-05 | Implement cooldown expiry check: mark key available again after cooldown window | P1 | XS | Part of `key_rotator.py` |
| LUM-KEYS-06 | Handle "all keys on cooldown" edge case: return 503 to client with friendly message | P1 | S |  |
| LUM-KEYS-07 | Log key usage stats to console (not to DB in v1.0 — avoid extra writes) | P2 | XS |  |

---

## SET — Settings

| ID | Title | Priority | Size | Notes |
|---|---|---|---|---|
| LUM-SET-01 | Build `SettingsScreen` layout: all sections per `frontendSpec.md` §3.6 | P1 | M |  |
| LUM-SET-02 | Implement AI name editing: inline text field, save to Supabase + local storage | P1 | S |  |
| LUM-SET-03 | Implement clear chat history: confirmation dialog, delete `messages` rows for user | P2 | S |  |
| LUM-SET-04 | Implement sign-out: clear session, navigate to login | P1 | XS | Reuse LUM-AUTH-07 |
| LUM-SET-05 | Implement delete account: confirmation dialog, call `DELETE /account`, clear local state | P1 | M |  |
| LUM-SET-06 | Auto-play TTS toggle: saved to `flutter_secure_storage` | P2 | XS |  |
| LUM-SET-07 | Display archetype as a vibe label (e.g., "You've got a bit of a Jester in you") | P2 | XS |  |
| LUM-SET-08 | Dark mode toggle (override system setting) | P2 | S |  |

---

## Ticket Summary

| Epic | Total Tickets | P0 | P1 | P2 | P3 |
|---|---|---|---|---|---|
| INFRA | 12 | 8 | 3 | 1 | 0 |
| AUTH | 10 | 7 | 3 | 0 | 0 |
| ONB | 8 | 6 | 2 | 0 | 0 |
| CHAT | 15 | 9 | 5 | 1 | 0 |
| AI | 13 | 7 | 5 | 0 | 0 |
| AV | 11 | 0 | 8 | 2 | 0 | (P1 = important but not launch-blocking) |
| COLD | 7 | 4 | 3 | 0 | 0 |
| RATE | 6 | 5 | 0 | 0 | 1 |
| KEYS | 7 | 4 | 2 | 1 | 0 |
| SET | 8 | 0 | 4 | 3 | 1 |
| **TOTAL** | **97** | **50** | **35** | **8** | **2** |

---

## Suggested Sprint Order

### Sprint 1 — Foundation (Week 1–2)
INFRA-01 through INFRA-12 · AUTH-01 through AUTH-05 · INFRA set complete

### Sprint 2 — Auth + Onboarding (Week 2–3)
AUTH-06 through AUTH-10 · ONB-01 through ONB-08

### Sprint 3 — Cold Start + Chat Shell (Week 3–4)
COLD-01 through COLD-07 · CHAT-01 through CHAT-06 · CHAT-11 through CHAT-13

### Sprint 4 — AI Brain (Week 4–5)
AI-01 through AI-13 · KEYS-01 through KEYS-07

### Sprint 5 — Full Chat + Rate Limit (Week 5–6)
CHAT-07 through CHAT-15 · RATE-01 through RATE-05

### Sprint 6 — Voice, Vision, Settings (Week 6–7)
AV-01 through AV-11 · SET-01 through SET-08

### Sprint 7 — Polish & QA (Week 7–8)
Remaining P2/P3 tickets · Performance pass · Accessibility audit · Device testing
