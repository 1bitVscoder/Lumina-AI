# Product Requirements Document
## Lumina — AI Companion Application
**Version:** 1.0.0
**Status:** Draft
**Last Updated:** 2026-06-07
**Author:** Mr. Glitch

---

## 1. Executive Summary

**Lumina** is a cross-platform (Android + iOS) AI companion application built with Flutter. It creates the feeling of texting a close, real friend — not talking to a chatbot. The AI adapts its personality, tone, and communication style to each user through an onboarding personality assessment. It supports voice input, spoken responses, and camera/image understanding. Chats are persisted per user via Supabase. The AI backend runs on Render, with a graceful cold-start experience. Users authenticate via Google. The AI can be named by the user.

The product deliberately avoids any robotic, assistant-like UX. There are no "How can I help you today?" prompts. It is designed to feel like opening a messaging app to talk to someone who already knows you.

---

## 2. Problem Statement

Current AI companion apps either:
- Feel transactional and robotic (generic chat assistant UX)
- Are overtly gendered or character-locked (no personalization)
- Lack true persistent memory (every conversation starts cold)
- Have poor mobile UX — excessive text, bad chat bubbles, no voice
- Don't adapt tone dynamically based on what the user says

Lumina solves all of the above by blending a genuine messaging-app feel with an adaptive, memory-aware AI backend.

---

## 3. Target Audience

| Segment | Profile |
|---|---|
| Primary | Ages 16–30, smartphone-native, lonely or socially understimulated users who want non-judgmental conversation |
| Secondary | Ages 30–45, professionals who want a thinking partner or journaling companion |
| Tertiary | Neurodivergent users who prefer low-pressure, text/voice-based social interaction |

---

## 4. Product Goals

1. **Feel real** — responses must read like a person, not an AI. Short, punchy, contextual.
2. **Remember you** — the AI knows your name, your mood history, what you talked about last week.
3. **Adapt** — tone, temperature, and verbosity shift based on detected emotional context.
4. **Be accessible** — full voice input + TTS output, camera/image input.
5. **Be trustworthy** — users' data is isolated, rate-limited, and secured per account.
6. **Survive free tier** — cold-start on Render is handled gracefully, not silently.

---

## 5. Core Features

### 5.1 Onboarding — Personality Assessment

Shown once on first login. A short conversational quiz (5–7 questions with tap-to-select options) that infers the user's personality archetype.

**Sample Questions:**

| # | Question | Options |
|---|---|---|
| 1 | When something bothers you, you usually... | Vent immediately / Think quietly / Joke it off / Ask for advice |
| 2 | Your ideal Friday night is... | Loud hangout / Netflix solo / Deep talk with one person / Spontaneous plans |
| 3 | How do you prefer people to talk to you? | Straight up honest / Gentle and soft / Funny and light / Mix it up |
| 4 | You're stressed. What helps most? | Distraction / Being heard / Logical solutions / Just silence |
| 5 | Pick a vibe: | Chill | Hype | Deep | Chaotic |

**Output Archetypes (internal only, not shown to user):**

- `Venter` — wants to be heard, validating responses, emotional tone
- `Analyst` — wants logic, reasoning, structured thought
- `Jester` — wants humor, banter, wit
- `Seeker` — wants depth, philosophical tone, reflection
- `Drifter` — unpredictable, mixed tone, needs mirroring

The archetype is stored in Supabase and used to seed the system prompt.

---

### 5.2 AI Naming

After personality onboarding, the user is presented with a single prompt:

> "Before we start — what do you want to call me?"

A text field with a placeholder (e.g., "Nova", "Arlo", "Sage"). The name is saved to their profile. All subsequent system prompts address the AI by this name.

---

### 5.3 Chat Interface

- **Bubble Style:** WhatsApp-style. User bubbles right-aligned (warm tint). AI bubbles left-aligned (muted/paper tone). Timestamps below each bubble. Tails on bubbles.
- **No excessive text:** The AI is instructed to reply in 1–3 sentences max unless the conversation demands more. No bullet points. No headers. Natural, flowing speech.
- **Theme:** Old-school texting aesthetic — warm paper textures, serif-adjacent type, muted greens or ambers, no neon, no gradients. Feels like passing notes in class, not using a tech product.
- **Scroll behavior:** Auto-scroll to latest message. Pull-to-load older messages.
- **Typing indicator:** Animated 3-dot bubble while AI is generating.

---

### 5.4 Input Methods

| Method | Detail |
|---|---|
| Text | Standard keyboard input. Send button. |
| Voice | Mic button → Speech-to-text (on-device, STT). Transcript shown in input field before send. |
| Image/Vision | Attach button → Gallery or Camera. Image sent with optional caption. AI responds to visual content. |

---

### 5.5 AI Voice Output (TTS)

- Every AI response has a small speaker icon.
- Tap to play — converts response text to speech using on-device or cloud TTS.
- Auto-play TTS can be toggled in Settings.
- Voice is neutral, warm in tone.

---

### 5.6 Dynamic Temperature & Tone Control

The AI backend adjusts generation parameters automatically:

| Detected Context | Temperature | Style |
|---|---|---|
| User venting / emotional | Low (0.5–0.6) | Warm, validating, short |
| Casual banter / jokes | High (0.9–1.0) | Loose, playful, punchy |
| Analytical / problem-solving | Medium-low (0.6–0.7) | Focused, direct |
| Philosophical / reflective | Medium-high (0.8) | Thoughtful, a little poetic |
| Unknown / mixed | 0.75 (default) | Balanced, mirroring |

Temperature is decided by the backend on each turn. Not exposed to the user.

---

### 5.7 Persistent Memory

The AI maintains three tiers of memory:

| Tier | What's Stored | Where |
|---|---|---|
| Session | Full current conversation context | In-context window (sent with each request) |
| Short-term | Last 10 conversations summarized | Supabase `user_memory` table |
| Long-term | Key facts (name, preferences, moods, major events) | Supabase `user_profile` table, injected into system prompt |

Memory is retrieved on session start and appended to the system prompt. The AI never announces it remembers — it just uses the context naturally.

---

### 5.8 "AI Identity" Restriction

The AI is instructed at the system-prompt level to never confirm or deny it is an AI. If asked "Are you an AI?", "Are you a robot?", "Are you ChatGPT?", etc., it deflects naturally — like a person who finds the question odd.

Example responses:
- *"Why are you asking that? You're being weird rn"*
- *"I'm [name]. That's all you need to know lol"*
- *"Does it matter?"*

This is enforced in the system prompt and cannot be overridden by user messages.

---

### 5.9 Backend Cold-Start (Render Wake-Up Screen)

When the app opens and the backend is potentially asleep (Render free tier):

1. App sends a lightweight `GET /ping` to the backend immediately on launch.
2. A full-screen overlay appears with a warm, friendly loading message:
   - *"Hold on... [AI name] is waking up ☕"*
   - *"Give it a sec, they're on their way..."*
   - *"Almost there — [AI name] doesn't do mornings well"*
   - Messages rotate every 3 seconds.
3. Once `/ping` returns 200, the overlay dissolves with a fade + subtle scale-up animation.
4. If the backend takes > 60 seconds, a soft error message appears: *"Taking longer than usual... still trying."*

---

### 5.10 Google Authentication

- Sign in with Google (OAuth 2.0).
- On first sign-in → onboarding flow.
- On return sign-in → straight to chat (with memory loaded).
- Profile: display name, email, avatar from Google. All stored in Supabase `users` table.

---

### 5.11 Rate Limiting (Per User)

Each Google-authenticated user is rate-limited:

| Tier | Limit |
|---|---|
| Free | 50 messages / day |
| (Future) Premium | Unlimited |

When limit is hit:
- Input field is disabled.
- Soft banner: *"[AI name] needs a break — you've talked a lot today. Come back tomorrow 💬"*
- Counter resets at midnight UTC.
- Rate limit state is tracked in Supabase.

---

### 5.12 FreeLLMAPI Key Rotation (Proxy)

The backend uses [freellmapi](https://github.com/tashfeenahmed/freellmapi) as a proxy to rotate through multiple free API keys for the underlying LLM, preventing quota exhaustion.

- Keys are stored server-side (never in the app).
- On each request, the proxy selects the active key via round-robin or cooldown-aware rotation.
- On quota error (429), the current key is marked on cooldown and the next key is tried automatically.
- No API provider is hardcoded in the app. The backend decides.

---

## 6. Non-Features (Out of Scope for v1.0)

- Group chats
- User-to-user messaging
- Image generation by AI
- Payment/subscription flow (UI placeholder only)
- Push notifications
- Web version

---

## 7. User Flows

### 7.1 First-Time User

```
Install App
  → Splash Screen (cold-start ping)
  → Google Sign-In
  → Personality Quiz (5–7 questions)
  → Name Your AI
  → Welcome Message from AI (personalized to archetype)
  → Chat Screen
```

### 7.2 Returning User

```
Open App
  → Splash + Cold-Start Ping
  → Google Auth (silent re-auth if token valid)
  → Chat Screen (history loaded, memory injected)
```

### 7.3 Sending a Voice Message

```
Tap Mic Button
  → STT starts (on-device)
  → User speaks
  → Tap stop / silence detection
  → Transcript appears in input box
  → User edits or sends
  → AI responds
```

### 7.4 Sending an Image

```
Tap Attach
  → Gallery or Camera picker
  → Optional caption
  → Send
  → AI reads image + caption and responds
```

---

## 8. Design Principles

1. **Friend, not assistant.** No assistant language. No "Here's what I found." No bullet lists in chat.
2. **Short by default.** If in doubt, say less. Match the energy of the user.
3. **Old-school warmth.** Paper tones, worn textures, serif typography. Not cold, not techy.
4. **Graceful degradation.** Slow backend? Tell the user warmly. No raw errors ever shown.
5. **Memory without announcement.** The AI remembers. It doesn't say "As you mentioned last time..." — it just knows.

---

## 9. Success Metrics (v1.0)

| Metric | Target |
|---|---|
| Day 7 retention | > 40% |
| Avg. messages per session | > 8 |
| Cold-start completion rate (users who wait) | > 85% |
| Voice input usage | > 20% of sessions |
| Onboarding completion rate | > 90% |

---

## 10. Constraints & Assumptions

- Flutter for both Android and iOS. Single codebase.
- Supabase (free tier initially) for auth mirror, chat storage, memory, and rate limiting.
- Render (free tier) for Python AI backend. Cold-start is a known UX challenge addressed by design.
- The underlying LLM provider is TBD — backend must be provider-agnostic.
- freellmapi proxy must be self-hosted on Render alongside the main API.
- No app store submission in v1.0 scope — local APK + TestFlight.
