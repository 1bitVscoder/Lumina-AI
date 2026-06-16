# Frontend Specification
## Lumina — AI Companion Application
**Version:** 1.0.0
**Status:** Draft
**Last Updated:** 2026-06-07

---

## 1. Design Philosophy

Lumina's UI should feel like opening a worn notebook — warm, familiar, analogue. Not a tech product. Not an app. A place.

The core aesthetic is **old-school texting meets a cozy corner of the internet from 2007** — paper textures, muted ink colors, serif-adjacent type, no gradients, no glass, no neon. The kind of place where two people are genuinely talking, not performing.

Every screen should pass this test: *"Does this feel like a person, or does it feel like software?"* If it feels like software, it's wrong.

---

## 2. Design Tokens

### 2.1 Color Palette

```dart
// core/theme.dart

class LuminaColors {
  // Backgrounds
  static const background      = Color(0xFFF5F0E8); // warm off-white, aged paper
  static const backgroundDark  = Color(0xFF1E1A14); // dark ink brown (dark mode)
  static const surface         = Color(0xFFEDE7D5); // slightly darker paper
  static const surfaceDark     = Color(0xFF2A2318); // dark mode surface

  // Bubbles
  static const userBubble      = Color(0xFFD4E8C2); // muted sage green (WhatsApp user)
  static const userBubbleDark  = Color(0xFF3A5C2F); // dark mode user bubble
  static const aiBubble        = Color(0xFFFFFFFA); // near-white paper
  static const aiBubbleDark    = Color(0xFF302A20); // dark mode AI bubble

  // Text
  static const textPrimary     = Color(0xFF2C2315); // deep ink brown
  static const textSecondary   = Color(0xFF7A6E5E); // faded ink
  static const textTimestamp   = Color(0xFFA09080); // barely there
  static const textPrimaryDark = Color(0xFFF0EAD8);
  static const textSecDark     = Color(0xFFAA9E8E);

  // Accents
  static const accentAmber     = Color(0xFFD4820A); // warm amber — primary accent
  static const accentGreen     = Color(0xFF6B8F5E); // sage — secondary
  static const accentRed       = Color(0xFFB04040); // muted red — errors/warnings

  // UI Elements
  static const divider         = Color(0xFFD6CDB8);
  static const inputBackground = Color(0xFFF0EBE0);
  static const sendButton      = Color(0xFFD4820A); // amber
  static const disabled        = Color(0xFFC8C0B0);
}
```

### 2.2 Typography

```dart
class LuminaTypography {
  // Display / AI name header
  static const fontDisplay = 'Lora';        // Serif, warm, editorial

  // Body / chat text
  static const fontBody    = 'JetBrains Mono'; // Monospace — adds old-school terminal feel
                                                 // Used ONLY for AI responses
  static const fontSans    = 'DM Sans';     // User messages, UI labels

  // Sizes
  static const double sizeCaption   = 11.0;
  static const double sizeBody      = 15.0;
  static const double sizeBodyLarge = 17.0;
  static const double sizeTitle     = 20.0;
  static const double sizeHeader    = 26.0;
}
```

**Font rationale:**
- `Lora` for headers/AI name — warmth, personality, editorial feel
- `JetBrains Mono` for AI chat bubbles — subtly different from user text, adds slight distinctiveness without feeling robotic
- `DM Sans` for UI and user messages — clean, readable, modern-neutral

### 2.3 Spacing & Radius

```dart
class LuminaSpacing {
  static const double xs  = 4.0;
  static const double sm  = 8.0;
  static const double md  = 16.0;
  static const double lg  = 24.0;
  static const double xl  = 32.0;
  static const double xxl = 48.0;
}

class LuminaRadius {
  static const double bubbleUser = 18.0;  // rounded, tail bottom-right
  static const double bubbleAi   = 18.0;  // tail bottom-left
  static const double card       = 12.0;
  static const double input      = 24.0;  // pill-shaped input bar
  static const double button     = 12.0;
}
```

### 2.4 Shadows & Elevation

Minimal. One global shadow style:

```dart
BoxShadow(
  color: Color(0x18000000),
  blurRadius: 8,
  offset: Offset(0, 2),
)
```

---

## 3. Screen Specifications

### 3.1 Splash / Cold-Start Screen

**Purpose:** Show while pinging the Render backend.

**Layout:**
- Full screen, background color: `LuminaColors.background`
- Subtle paper texture overlay (SVG noise or asset image, `opacity: 0.08`)
- Center column:
  - AI name in `Lora` bold, 28sp, `textPrimary` — `"[AI Name] is waking up..."`
  - Below: rotating subtitle messages (fade crossfade every 3s):
    - *"Hold on, they don't do mornings..."*
    - *"Making coffee... probably."*
    - *"Give it a sec, almost there."*
    - *"[AI Name] is on their way."*
  - Animated indicator: three dots, slow sequential fade (not a spinner). Custom widget.
- Bottom: `"This might take a minute"` in `textTimestamp` size

**Animations:**
- Name fades in with `FadeTransition` + 300ms delay on screen mount
- Message crossfade: `AnimatedSwitcher` with `FadeTransition`, duration 400ms
- On success: entire screen fades to 0 opacity over 500ms, then Navigator pushes chat

**Error state (> 90s):**
- Subtitle becomes: *"Taking longer than usual... still trying."* in `accentRed`

---

### 3.2 Login Screen

**Layout:**
- Full-screen background, same paper texture
- Top 40%: Lumina wordmark in `Lora` bold, 42sp, centered
- Below wordmark: one-line tagline in `textSecondary`, 14sp:
  - *"Someone to talk to. Always."*
- Vertical space
- Google Sign-In button:
  - White background, rounded 12px
  - Google logo SVG (official) + "Continue with Google" in `DM Sans` medium
  - Width: 80% of screen
  - Subtle drop shadow
- Bottom: tiny privacy note in `textTimestamp`

**Behavior:**
- Tapping button → Google OAuth flow
- On success → check `onboarded` flag:
  - `false` → Onboarding Quiz screen
  - `true` → Cold-start / Chat screen

---

### 3.3 Onboarding Quiz Screen

**Layout:**
- No app bar. Full immersion.
- Top: progress bar — thin amber line, animates right per question. `5px` height.
- Question card (center of screen, animate slide-in from right):
  - Question text in `Lora` regular, 20sp
  - Option buttons below — full-width, rounded `12px`, outlined with `divider` color
  - On tap: fills with `userBubble` color, brief scale animation (1.0 → 1.03 → 1.0, 150ms)
  - "Next" button appears after selection. Amber. Bottom-right.
- Last question: "Next" becomes "Done" → calls `/onboarding` API

**Animations:**
- Each question card: `SlideTransition` from right (x: 1.0 → 0.0), duration 280ms
- Option selection: `ScaleTransition` micro-bounce

---

### 3.4 AI Naming Screen

**Layout:**
- Appears after quiz, before chat.
- Simple screen. One question, centered:
  - Large text: *"Before we start..."* in `Lora`, 22sp, `textSecondary`
  - Below: *"What do you want to call me?"* in `Lora` bold, 26sp, `textPrimary`
- Text field below:
  - Pill-shaped, `inputBackground` fill
  - Placeholder: `"Nova, Arlo, Sage..."` in `textTimestamp`
  - `DM Sans`, 18sp
  - Max 20 characters
- "Let's go →" button below field. Amber fill. Saves name, goes to chat.

---

### 3.5 Chat Screen

This is the core of the app. Every detail matters.

#### 3.5.1 App Bar

```
┌──────────────────────────────────────┐
│ ←  [Avatar circle]  [AI Name]        │  ← App bar
│              Online                  │
└──────────────────────────────────────┘
```

- Avatar: circular, 36px. Uses first letter of AI name as initials in amber circle (no real avatar).
- AI Name: `Lora` semi-bold, 17sp
- Subtitle: *"Online"* — always shown (even if backend is slow; it's a persona thing), `textSecondary`, 12sp
- Right icons: ⋮ menu → Settings

#### 3.5.2 Message List

- `ListView.builder` with `reverse: true` (latest at bottom)
- `EdgeInsets.symmetric(vertical: 4, horizontal: 10)` between bubbles
- Messages grouped by day with a centered date label:
  - *"Today"*, *"Yesterday"*, or `"Jun 5"` — in `textTimestamp`, `DM Sans`, 12sp

#### 3.5.3 Message Bubbles

**User bubble:**
```
                        ┌─────────────────────┐
                        │ hey what's up        │◄── bubble (right)
                        │                  10:42│
                        └──────────────────────┘╮ ← tail bottom-right
```
- Background: `userBubble`
- Text: `DM Sans` 15sp, `textPrimary`
- Max width: 75% of screen
- Padding: `EdgeInsets.fromLTRB(12, 8, 12, 6)`
- Timestamp: inside bubble, bottom-right, `textTimestamp`, 10sp
- Border radius: 18px all corners, bottom-right → 4px (tail effect)

**AI bubble:**
```
╰ ← tail bottom-left
┌──────────────────────┐
│ not much, what's     │
│ going on with you    │
│ 10:43                │
└──────────────────────┘
```
- Background: `aiBubble`
- Text: `JetBrains Mono` 14sp, `textPrimary`
- Max width: 78% of screen
- Border radius: 18px all corners, bottom-left → 4px (tail effect)
- Timestamp: bottom-left, `textTimestamp`, 10sp
- TTS play icon: small speaker (16px), `textSecondary`, appears after timestamp on same line

**Image bubble:**
- Same positioning rules
- `ClipRRect` with `borderRadius: 12`
- `Image.memory` with `BoxFit.cover`
- Max height: 220px
- Caption text below image if provided, same style as text bubble

**Typing indicator bubble:**
- AI-side positioning
- Three dots, each 6px circle, `textSecondary` color
- Sequential opacity animation: 0.3 → 1.0 → 0.3, staggered 200ms each

#### 3.5.4 Input Bar

```
┌────────────────────────────────────────┐
│ [📎] [  Type something...           ] [🎤] [➤]│
└────────────────────────────────────────┘
```

- Background: `surface` with top border `divider`
- TextField: pill-shaped, `inputBackground`, `DM Sans` 15sp
- Hint text: *"Type something..."* — casual, not "Enter your message"
- Attach icon (left): opens `image_picker`
- Mic icon (right of field): starts STT recording
  - During recording: mic turns red, pulsing ring animation
- Send button (rightmost): `accentAmber` circle, arrow icon
  - Disabled (grey) when field is empty
  - Animated: small scale bounce on tap
- Max lines for input field: 5. Expands vertically.

---

### 3.6 Settings Screen

Simple, clean. No deep nesting.

**Sections:**
1. **Profile** — Avatar, display name, email (read-only from Google)
2. **Your AI** — Current AI name (editable inline). Archetype label (shown as a vibe word, e.g., "You're a bit of a Jester").
3. **Chat** — Auto-play TTS (toggle). Clear chat history (with confirmation).
4. **Account** — Sign out. Delete account (red, confirmation dialog).
5. **About** — Version number, a one-liner.

---

## 4. Component Library

### 4.1 `MessageBubble`

```dart
MessageBubble({
  required String content,
  required bool isUser,
  required DateTime timestamp,
  String? imageBase64,
  VoidCallback? onTtsPlay,
})
```

### 4.2 `TypingIndicator`

```dart
TypingIndicator() // self-animating, shows when chatProvider.isTyping == true
```

### 4.3 `VoiceInputButton`

```dart
VoiceInputButton({
  required VoidCallback onStart,
  required ValueChanged<String> onResult,
})
// Manages internal recording state, exposes transcript on complete
```

### 4.4 `WakeupOverlay`

```dart
WakeupOverlay({
  required String aiName,
  required Future<void> pingFuture,
  required VoidCallback onReady,
})
```

### 4.5 `QuizCard`

```dart
QuizCard({
  required String question,
  required List<String> options,
  required ValueChanged<String> onSelect,
})
```

### 4.6 `RateLimitBanner`

```dart
RateLimitBanner({
  required String aiName,
  required DateTime resetAt,
})
// Shows at top of chat, disables input
```

---

## 5. Navigation & Routing

Using `go_router`:

```dart
final router = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (_, __) => WakeupScreen()),
    GoRoute(path: '/login', builder: (_, __) => LoginScreen()),
    GoRoute(path: '/onboarding/quiz', builder: (_, __) => QuizScreen()),
    GoRoute(path: '/onboarding/name', builder: (_, __) => NamingScreen()),
    GoRoute(path: '/chat', builder: (_, __) => ChatScreen()),
    GoRoute(path: '/settings', builder: (_, __) => SettingsScreen()),
  ],
  redirect: (context, state) {
    final isAuthed = ref.read(authProvider).isAuthenticated;
    final onboarded = ref.read(userProfileProvider).onboarded;
    if (!isAuthed) return '/login';
    if (!onboarded) return '/onboarding/quiz';
    return null;
  }
);
```

---

## 6. Animations Reference

| Animation | Widget | Curve | Duration |
|---|---|---|---|
| Screen transitions | `FadeTransition` | `easeInOut` | 300ms |
| Quiz card slide-in | `SlideTransition` | `easeOut` | 280ms |
| Option select bounce | `ScaleTransition` | `elasticOut` | 150ms |
| Bubble appear | `FadeTransition` + `SlideTransition` (y: 10→0) | `easeOut` | 200ms |
| Wakeup overlay dismiss | `FadeTransition` | `easeIn` | 500ms |
| Typing indicator dots | `AnimationController` loop | `easeInOut` | 600ms/dot |
| Send button tap | `ScaleTransition` (1.0→0.9→1.0) | `easeOut` | 120ms |
| Message rotate (wakeup) | `AnimatedSwitcher` fade | `easeInOut` | 400ms |

---

## 7. Dark Mode

All color tokens have dark counterparts (see §2.1). The app respects system theme preference by default, with a manual override toggle in Settings.

```dart
ThemeData.light().copyWith(
  scaffoldBackgroundColor: LuminaColors.background,
  // ...
)

ThemeData.dark().copyWith(
  scaffoldBackgroundColor: LuminaColors.backgroundDark,
  // ...
)
```

---

## 8. Accessibility

- All tap targets minimum 44×44px
- All text meets WCAG AA contrast ratios against respective backgrounds
- STT is an alternative to typing (accessibility parity)
- TTS is an alternative to reading (accessibility parity)
- Semantic labels on all icon buttons
- Dynamic text size support (`textScaleFactor` respected)

---

## 9. Platform-Specific Notes

### Android
- Status bar: transparent, icons dark on light theme / light on dark
- Back gesture: goes to chat (not exits app) unless on chat screen (then minimizes)
- Keyboard: `resizeToAvoidBottomInset: true` — chat scrolls up when keyboard appears

### iOS
- Safe area respected on all screens (notch + home indicator)
- Haptic feedback: `HapticFeedback.lightImpact()` on send, option select
- iOS-style text selection handles in bubbles

---

## 10. Localization (v1.0 Scope)

English only. String constants centralized in `lib/core/strings.dart` for future i18n readiness. No hardcoded strings in widgets.
