# Walkthrough: Sprint 1 to 6 — Foundations, Auth, Onboarding, Chat, Brain, Voice, Vision, and Settings

This document details the work accomplished during **Sprint 1 to 6** of the Lumina AI Companion application. It outlines the structure of the mobile client, python backend, database schemas, and how to verify that everything works correctly.

---

## 1. Project Structure

The project is organized as follows:
```
Lumina/
├── client/              # Flutter Mobile Application
│   └── lib/
│       ├── core/        # Router, Theme, Network Dio provider
│       ├── features/    # Auth, Onboarding, Chat, Settings, Wakeup
│       └── shared/      # Shared models (UserProfile, Message)
├── backend/             # Python FastAPI backend
│   ├── models/          # Request schemas (ChatRequest, OnboardingRequest)
│   ├── routes/          # Health ping, Onboarding, Session start/end, Chat, Account
│   ├── services/        # Prompt building, Key rotator, Tone classifier, LLM service, Rate limiter, Memory service
│   └── utils/           # JWT Auth validation, Supabase admin client
├── database/            # Database schemas & migrations (schema.sql)
└── documents/           # Project specifications & ticket lists
```

---

## 2. Sprint 5 & 6 Additions & Code References

### 2.1 Backend Enhancements (`/backend`)
- **LLM Upgrade ([services/llm_service.py](file:///c:/Users/soumya/.gemini/antigravity/scratch/Lumina/backend/services/llm_service.py)):** Switched LLM routes to use **Gemini 2.5 Flash** (`gemini-2.5-flash`).
- **Daily Rate Limiting ([services/rate_limiter.py](file:///c:/Users/soumya/.gemini/antigravity/scratch/Lumina/backend/services/rate_limiter.py)):** Enforces a user limit of 50 messages/day resetting at midnight UTC.
- **Account Deletion ([routes/account.py](file:///c:/Users/soumya/.gemini/antigravity/scratch/Lumina/backend/routes/account.py)):** Exposes `DELETE /account` to remove user record in the `users` table (cascading database-wide to wipe chat history, memories, and rate limits) and deletes the user auth profile via `supabase.auth.admin.delete_user`.
- **Vision Image Storage ([routes/chat.py](file:///c:/Users/soumya/.gemini/antigravity/scratch/Lumina/backend/routes/chat.py)):** Stores incoming image base64 data directly inside `messages.image_url` on user chat message insertions.

### 2.2 Client-Side Chat Sync & Lock UI (`/client`)
- **History Sync & REST Post ([features/chat/providers/chat_provider.dart](file:///c:/Users/soumya/.gemini/antigravity/scratch/Lumina/client/lib/features/chat/providers/chat_provider.dart)):**
  - Restores the last 30 messages from Supabase on startup.
  - Sends text + base64 image strings to backend `/chat`.
  - Captures 429 status and parses `reset_at` to disable chat input.
  - Offers `clearHistory()` utilizing cascading deletes.
- **Countdown Banner ([features/chat/widgets/rate_limit_banner.dart](file:///c:/Users/soumya/.gemini/antigravity/scratch/Lumina/client/lib/features/chat/widgets/rate_limit_banner.dart)):** Displays ticking count in `HH:MM:SS` format.
- **Image Pick & Compress ([features/chat/widgets/chat_input_bar.dart](file:///c:/Users/soumya/.gemini/antigravity/scratch/Lumina/client/lib/features/chat/widgets/chat_input_bar.dart)):** Integrates `image_picker` and `flutter_image_compress` (min 512px, 85% JPEG). Displays interactive thumbnail preview with a cancel button.

### 2.3 Audio Infrastructure (`/client`)
- **Text-to-Speech ([features/chat/providers/tts_provider.dart](file:///c:/Users/soumya/.gemini/antigravity/scratch/Lumina/client/lib/features/chat/providers/tts_provider.dart)):** Wraps `flutter_tts` to read AI responses on tapping speaker icons or automatically when `autoplayTts` setting is enabled.
- **Speech-to-Text ([features/chat/widgets/voice_input_button.dart](file:///c:/Users/soumya/.gemini/antigravity/scratch/Lumina/client/lib/features/chat/widgets/voice_input_button.dart)):** Captures voice inputs, showing a glowing, red pulsing ring animation when recording.

### 2.4 ChatGPT-Style Live Voice Mode (`/client`)
- **Voice Overlay ([features/chat/screens/live_voice_overlay.dart](file:///c:/Users/soumya/.gemini/antigravity/scratch/Lumina/client/lib/features/chat/screens/live_voice_overlay.dart)):** Immersive voice screen triggered from the headphones icon button in `ChatScreen` App Bar.
- **Reactive Voice Orb**: Displays a glowing animated gradient mesh changing behavior based on conversation states:
  - *Listening*: Slow sage-green breathing pulse.
  - *Thinking*: Multi-layered rotating purple mesh.
  - *Speaking*: Amber waves.
- **Tap to Interrupt**: Tapping the central orb stops TTS immediately and restarts microphone listening.

### 2.5 Preferences & Settings Screen (`/client`)
- **Settings Screen ([features/settings/screens/settings_screen.dart](file:///c:/Users/soumya/.gemini/antigravity/scratch/Lumina/client/lib/features/settings/screens/settings_screen.dart)):**
  - *Profile Card*: Displays user's Google name, email, and photo.
  - *Your AI*: Inline renamed input fields synchronized database-wide, displaying companion archetype descriptions.
  - *Preferences*: Segmented dropdown selection of App Theme (Light / Dark / System Default) and Auto-play voice switcher.
  - *Actions*: Clear history confirmation alerts, local sign-out, and Delete My Account cascading wipe triggers.

### 2.6 Post-Launch UI Polishing & Google Auth Setup (`/client`)
- **Login UI Contrast & Themes ([auth/screens/login_screen.dart](file:///c:/Users/soumya/.gemini/antigravity/scratch/Lumina/client/lib/features/auth/screens/login_screen.dart)):**
  - Configured title, subtitle, and footer texts to dynamically read the theme brightness and switch between light and dark high-contrast colors (`textPrimary`/`textPrimaryDark` and `textSecondary`/`textSecDark`), solving contrast issues on dark backgrounds.
- **Official Google Logo SVG ([assets/google_logo.svg](file:///c:/Users/soumya/.gemini/antigravity/scratch/Lumina/client/assets/google_logo.svg)):**
  - Integrated the official Google "G" logo SVG asset using the `flutter_svg` package, replacing the previous custom-drawn and distorted painter.
- **Google Sign-In Configurations**:
  - Extracted debug SHA-1/SHA-256 certificate fingerprints and configured the Web Client ID for proper OAuth flow with Supabase and Android Google Play Services.

### 2.7 Transient Guest Login Mode (`/client` & `/backend`)
- **Guest Authentication Service ([auth_service.dart](file:///c:/Users/soumya/.gemini/antigravity/scratch/Lumina/client/lib/features/auth/services/auth_service.dart)):**
  - Added support for Supabase anonymous sign-in, letting guest users bypass Google play services credentials.
- **Transient Data Cleanups ([auth_provider.dart](file:///c:/Users/soumya/.gemini/antigravity/scratch/Lumina/client/lib/features/auth/providers/auth_provider.dart)):**
  - App startup automatically detects if the previous active session belongs to a guest user and triggers backend account deletion (`DELETE /account`) and signs them out cleanly. This prevents guest data from persisting across runs.
  - Logging out of a guest session triggers a cascading backend `DELETE /account` call, immediately freeing public and auth table storage space in Supabase.
- **Onboarding Unique Guest Mappings ([onboarding.py](file:///c:/Users/soumya/.gemini/antigravity/scratch/Lumina/backend/routes/onboarding.py)):**
  - Automatically generates a unique, non-null mock email `guest_<UUID>@lumina.ai` and default display name `Guest` during upsert to satisfy constraints of the public `users` database table.
- **Interactive UI Additions ([login_screen.dart](file:///c:/Users/soumya/.gemini/antigravity/scratch/Lumina/client/lib/features/auth/screens/login_screen.dart) & [settings_screen.dart](file:///c:/Users/soumya/.gemini/antigravity/scratch/Lumina/client/lib/features/settings/screens/settings_screen.dart)):**
  - Added a secondary outlined "Continue as Guest" button to the login page.
  - Profile cards display friendly guest placeholders instead of empty text.

### 2.8 Onboarding Welcome Screen, Swipe Gestures, & Answer Editing (`/client` & `/backend`)
- **Backend Bypass Support ([onboarding.py](file:///c:/Users/soumya/.gemini/antigravity/scratch/Lumina/backend/routes/onboarding.py)):**
  - Modified the onboarding submission route to check if the quiz responses list `answers` is empty. If empty, the system automatically assigns the default `"drifter"` archetype and bypasses calculations.
- **Client Onboarding State ([onboarding_provider.dart](file:///c:/Users/soumya/.gemini/antigravity/scratch/Lumina/client/lib/features/onboarding/providers/onboarding_provider.dart)):**
  - Added `isIntroCompleted` state variable (defaulting to `false`).
  - Added `startQuiz()`: sets `isIntroCompleted = true`, resets indexing, and initializes the answers list with empty placeholder values.
  - Added `skipQuiz()`: sets `isIntroCompleted = true`, clears selections, and calls `submitQuiz()` to assign the default archetype.
  - Added `previousQuestion()` and `goBackToIntro()` to enable navigating back to previous questions or the welcome screen, preserving selected answers at each index.
- **Client Quiz View & Custom Answer Input ([quiz_screen.dart](file:///c:/Users/soumya/.gemini/antigravity/scratch/Lumina/client/lib/features/onboarding/screens/quiz_screen.dart)):**
  - Overhauled state machine to display a warm Intro welcome card asking *"I want to know you before we talk."* with action buttons **"I'm not ready"** (skips quiz completely) and **"Bring it on"** (starts quiz) if `isIntroCompleted` is false.
  - Rendered a custom text input field below the preset option buttons. Typing select/registers custom input, while tapping a preset option button clears the custom text field.
  - Pre-populates the custom text input field with the user's previously typed custom answer when navigating back or forward to a question.
  - Wrapped the main question body card in a `GestureDetector` that detects horizontal drag swipes: swipe right navigates to the previous question (or back to the intro welcome screen if on the first question), while swipe left moves to the next question (if answered).

### 2.9 Cozy Space-Theme, Premium UX & Circular Adaptive App Icon (`/client`)
- **Cozy Space-Theme Styling**: Updated dark theme color scheme across all screens (`login_screen.dart`, `chat_screen.dart`, `naming_screen.dart`, `settings_screen.dart`) using cozy charcoal (`#0B0C14`), dark indigo (`#1A1530`), and warm gold glows.
- **Glassmorphism Overlay ([shared/widgets/glass_container.dart](file:///c:/Users/soumya/.gemini/antigravity/scratch/Lumina/client/lib/shared/widgets/glass_container.dart))**: Frosted blur and bevel overlays applied on input bars, settings tiles, and app bar surfaces.
- **Ambient Canvas ([shared/widgets/ambient_particles.dart](file:///c:/Users/soumya/.gemini/antigravity/scratch/Lumina/client/lib/shared/widgets/ambient_particles.dart))**: Floating stellar particle stream running at 60 FPS behind chat and login backdrops.
- **Ambient Soundscapes ([core/soundscape_service.dart](file:///c:/Users/soumya/.gemini/antigravity/scratch/Lumina/client/lib/core/soundscape_service.dart))**: Streams loopable relaxing tracks (Cozy Rain, Fireplace, Cozy Lo-Fi) utilizing the `audioplayers` package.
- **Entrance Animations ([features/chat/widgets/entrance_transition.dart](file:///c:/Users/soumya/.gemini/antigravity/scratch/Lumina/client/lib/features/chat/widgets/entrance_transition.dart))**: Message bubbles smoothly fade and slide upwards when rendered.
- **Circular Adaptive Launcher Icon**:
  - Implemented [crop_logo_circular.py](file:///c:/Users/soumya/.gemini/antigravity/scratch/Lumina/client/crop_logo_circular.py) to crop, mask, and save the app icon as a circle with transparent corners.
  - Added Android adaptive icon configs (`adaptive_icon_background: "#0B0C14"`, `adaptive_icon_foreground: "assets/lumina_logo.png"`) in [pubspec.yaml](file:///c:/Users/soumya/.gemini/antigravity/scratch/Lumina/client/pubspec.yaml).
  - Linked `android:roundIcon` in [AndroidManifest.xml](file:///c:/Users/soumya/.gemini/antigravity/scratch/Lumina/client/android/app/src/main/AndroidManifest.xml).
  - Re-generated all native assets utilizing `flutter_launcher_icons` and uninstalled old versions to refresh OS caches.

### 2.10 Native App Updater & Git/Deployment Readiness (Secrets Protection & Render Config)
- **Native App Updater**: Integrated `open_filex` and `package_info_plus` in the client to support seamless, in-app updates directly from GitHub Releases with live download progress.
- **Git Ignore Security**: Created a root-level `.gitignore` and updated `client/.gitignore` to ignore `.env` files (protecting sensitive credentials like `SUPABASE_SERVICE_KEY` and `GEMINI_API_KEY` from public exposure) and local build environments (`venv`, `.dart_tool/`, `build/`).
- **Templates**: Created `backend/.env.example` and `client/assets/.env.example` templates to guide production deployment setups.

---

## 3. Verification & How to Run

### 3.1 Client
Run static analysis checks:
```bash
cd client
flutter pub get
flutter analyze
```
*Current Status:* **`No issues found!`** (Zero warnings, errors, or info notes).

### 3.2 Backend
Start development server:
```bash
cd backend
.\venv\Scripts\uvicorn main:app --reload
```
Test health status:
```powershell
Invoke-RestMethod -Uri "http://127.0.0.1:8000/ping"
```
*Current Status:* Returns `{"status": "ok", "message": "Lumina is awake."}`.
All routes compile and run cleanly.
