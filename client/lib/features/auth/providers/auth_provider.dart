import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../../../core/network.dart';
import '../services/auth_service.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final supabase.User? user;
  final String? errorMessage;

  AuthState({
    required this.isAuthenticated,
    this.isLoading = false,
    this.user,
    this.errorMessage,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    supabase.User? user,
    String? errorMessage,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      user: user ?? this.user,
      errorMessage: errorMessage,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;
  final Ref _ref;

  AuthNotifier(this._authService, this._ref) : super(AuthState(isAuthenticated: false)) {
    _init();
  }

  void _init() async {
    // Check if there is already an active session at startup
    final session = _authService.currentSession;
    if (session != null) {
      final user = session.user;
      if (user.isAnonymous) {
        // It's a guest session from previous run. Clean it up and sign out!
        try {
          final dio = _ref.read(dioProvider);
          await dio.delete('/account');
        } catch (e) {
          debugPrint("Failed to delete old guest account on startup: $e");
        } finally {
          await _authService.signOut();
          state = AuthState(isAuthenticated: false);
        }
      } else {
        state = AuthState(
          isAuthenticated: true,
          user: user,
        );
      }
    }
  }

  Future<void> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final response = await _authService.signInWithGoogle();
      state = AuthState(
        isAuthenticated: response.session != null,
        user: response.user,
      );
    } catch (e) {
      state = AuthState(
        isAuthenticated: false,
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }

  Future<void> signInAsGuest() async {
    debugPrint("signInAsGuest: Start");
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      debugPrint("signInAsGuest: Calling _authService.signOut()");
      await _authService.signOut();
      debugPrint("signInAsGuest: _authService.signOut() completed");
      
      debugPrint("signInAsGuest: Calling _authService.signInAnonymously()");
      final response = await _authService.signInAnonymously();
      debugPrint("signInAsGuest: _authService.signInAnonymously() completed. Session: ${response.session != null}");
      state = AuthState(
        isAuthenticated: response.session != null,
        user: response.user,
      );
    } catch (e, stack) {
      debugPrint("signInAsGuest: Exception occurred: $e");
      debugPrint(stack.toString());
      state = AuthState(
        isAuthenticated: false,
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }

  Future<void> signOut() async {
    state = state.copyWith(isLoading: true);
    try {
      final user = _authService.currentUser;
      if (user != null && user.isAnonymous) {
        try {
          final dio = _ref.read(dioProvider);
          await dio.delete('/account');
        } catch (e) {
          debugPrint("Failed to delete guest account during signout: $e");
        }
      }
      await _authService.signOut();
      state = AuthState(isAuthenticated: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  void trySilentLogin() {
    final session = _authService.currentSession;
    if (session != null) {
      final user = session.user;
      if (user.isAnonymous) {
        // Do not auto-login guest users on launch
        state = AuthState(isAuthenticated: false);
      } else {
        state = AuthState(
          isAuthenticated: true,
          user: user,
        );
      }
    } else {
      state = AuthState(isAuthenticated: false);
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthNotifier(authService, ref);
});
