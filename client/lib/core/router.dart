import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/providers/auth_provider.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/onboarding/providers/onboarding_provider.dart';
import '../features/onboarding/screens/naming_screen.dart';
import '../features/onboarding/screens/quiz_screen.dart';
import '../features/chat/screens/chat_screen.dart';
import '../features/settings/screens/settings_screen.dart';
import '../features/wakeup/screens/wakeup_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  // Listen to auth changes and profile changes to trigger redirect
  final authState = ref.watch(authProvider);
  final profileState = ref.watch(userProfileProvider);

  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const WakeupScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/onboarding/quiz',
        builder: (context, state) => const QuizScreen(),
      ),
      GoRoute(
        path: '/onboarding/name',
        builder: (context, state) => const NamingScreen(),
      ),
      GoRoute(
        path: '/chat',
        builder: (context, state) => const ChatScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
    redirect: (context, state) {
      final isAuthed = authState.isAuthenticated;
      final onboarded = profileState.onboarded;

      final isGoingToLogin = state.matchedLocation == '/login';
      final isGoingToWakeup = state.matchedLocation == '/';

      // If not authenticated and not going to login or wakeup, send to login
      if (!isAuthed && !isGoingToLogin && !isGoingToWakeup) {
        return '/login';
      }

      // If authenticated but not onboarded, redirect to onboarding quiz
      if (isAuthed && !onboarded) {
        if (!state.matchedLocation.startsWith('/onboarding')) {
          return '/onboarding/quiz';
        }
      }

      // If authenticated and onboarded, but still on login, go to chat
      if (isAuthed && onboarded && isGoingToLogin) {
        return '/chat';
      }

      return null;
    },
  );
});
