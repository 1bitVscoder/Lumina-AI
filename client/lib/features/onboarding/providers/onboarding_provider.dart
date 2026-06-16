import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../../../core/network.dart';
import '../../../shared/models/user_profile.dart';

class QuizQuestion {
  final String question;
  final List<String> options;

  QuizQuestion({required this.question, required this.options});
}

final quizQuestions = [
  QuizQuestion(
    question: "When something bothers you, you usually...",
    options: ["Vent immediately", "Think quietly", "Joke it off", "Ask for advice"],
  ),
  QuizQuestion(
    question: "Your ideal Friday night is...",
    options: ["Loud hangout", "Netflix solo", "Deep talk with one person", "Spontaneous plans"],
  ),
  QuizQuestion(
    question: "How do you prefer people to talk to you?",
    options: ["Straight up honest", "Gentle and soft", "Funny and light", "Mix it up"],
  ),
  QuizQuestion(
    question: "You're stressed. What helps most?",
    options: ["Distraction", "Being heard", "Logical solutions", "Just silence"],
  ),
];

class OnboardingState {
  final int currentQuestionIndex;
  final List<String> selectedAnswers;
  final String? selectedAnswerForCurrentQuestion;
  final String companionName;
  final bool isLoading;
  final String? errorMessage;
  final String? archetype;
  final bool isIntroCompleted;

  OnboardingState({
    this.currentQuestionIndex = 0,
    this.selectedAnswers = const [],
    this.selectedAnswerForCurrentQuestion,
    this.companionName = '',
    this.isLoading = false,
    this.errorMessage,
    this.archetype,
    this.isIntroCompleted = false,
  });

  OnboardingState copyWith({
    int? currentQuestionIndex,
    List<String>? selectedAnswers,
    Object? selectedAnswerForCurrentQuestion = const Object(),
    String? companionName,
    bool? isLoading,
    String? errorMessage,
    String? archetype,
    bool? isIntroCompleted,
  }) {
    return OnboardingState(
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      selectedAnswers: selectedAnswers ?? this.selectedAnswers,
      selectedAnswerForCurrentQuestion: selectedAnswerForCurrentQuestion == const Object()
          ? this.selectedAnswerForCurrentQuestion
          : (selectedAnswerForCurrentQuestion as String?),
      companionName: companionName ?? this.companionName,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      archetype: archetype ?? this.archetype,
      isIntroCompleted: isIntroCompleted ?? this.isIntroCompleted,
    );
  }
}

class OnboardingNotifier extends StateNotifier<OnboardingState> {
  final Ref _ref;

  OnboardingNotifier(this._ref) : super(OnboardingState());

  void startQuiz() {
    state = state.copyWith(
      isIntroCompleted: true,
      currentQuestionIndex: 0,
      selectedAnswers: List.filled(quizQuestions.length, ''),
      selectedAnswerForCurrentQuestion: null,
    );
  }

  Future<void> skipQuiz() async {
    state = state.copyWith(
      selectedAnswers: [],
      selectedAnswerForCurrentQuestion: null,
    );
    await submitQuiz();
  }

  void selectOption(String option) {
    final updatedAnswers = List<String>.from(state.selectedAnswers);
    if (state.currentQuestionIndex < updatedAnswers.length) {
      updatedAnswers[state.currentQuestionIndex] = option;
    }
    state = state.copyWith(
      selectedAnswers: updatedAnswers,
      selectedAnswerForCurrentQuestion: option.isEmpty ? null : option,
    );
  }

  void nextQuestion() {
    if (state.selectedAnswerForCurrentQuestion == null || 
        state.selectedAnswerForCurrentQuestion!.trim().isEmpty) {
      return;
    }

    final updatedAnswers = List<String>.from(state.selectedAnswers);
    if (state.currentQuestionIndex < updatedAnswers.length) {
      updatedAnswers[state.currentQuestionIndex] = state.selectedAnswerForCurrentQuestion!;
    }

    if (state.currentQuestionIndex < quizQuestions.length - 1) {
      final nextIndex = state.currentQuestionIndex + 1;
      final nextAnswer = updatedAnswers[nextIndex];
      state = state.copyWith(
        currentQuestionIndex: nextIndex,
        selectedAnswers: updatedAnswers,
        selectedAnswerForCurrentQuestion: nextAnswer.isEmpty ? null : nextAnswer,
      );
    } else {
      // Last question completed, submit responses
      state = state.copyWith(
        selectedAnswers: updatedAnswers,
      );
      submitQuiz();
    }
  }

  void previousQuestion() {
    if (state.currentQuestionIndex > 0) {
      final updatedAnswers = List<String>.from(state.selectedAnswers);
      if (state.currentQuestionIndex < updatedAnswers.length && 
          state.selectedAnswerForCurrentQuestion != null) {
        updatedAnswers[state.currentQuestionIndex] = state.selectedAnswerForCurrentQuestion!;
      }
      
      final prevIndex = state.currentQuestionIndex - 1;
      final prevAnswer = updatedAnswers[prevIndex];
      state = state.copyWith(
        currentQuestionIndex: prevIndex,
        selectedAnswers: updatedAnswers,
        selectedAnswerForCurrentQuestion: prevAnswer.isEmpty ? null : prevAnswer,
      );
    }
  }

  void goBackToIntro() {
    state = state.copyWith(isIntroCompleted: false);
  }

  Future<void> submitQuiz() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final user = supabase.Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception("User is not authenticated");

      final dio = _ref.read(dioProvider);
      debugPrint("ONBOARDING SUBMIT: Requesting ${dio.options.baseUrl}/onboarding");
      final response = await dio.post('/onboarding', data: {
        'user_id': user.id,
        'answers': state.selectedAnswers,
      });

      final archetype = response.data['archetype'] as String;
      
      state = state.copyWith(
        isLoading: false,
        archetype: archetype,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: "Onboarding quiz submission failed: ${e.toString()}",
      );
    }
  }

  void updateCompanionName(String name) {
    state = state.copyWith(companionName: name);
  }

  Future<void> finalizeOnboarding() async {
    if (state.companionName.trim().isEmpty) {
      state = state.copyWith(errorMessage: "Name cannot be empty");
      return;
    }
    if (state.companionName.length < 3 || state.companionName.length > 20) {
      state = state.copyWith(errorMessage: "Name must be between 3 and 20 characters");
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final client = supabase.Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user == null) throw Exception("User is not authenticated");

      // Save chosen companion name and set onboarded = true in Supabase users table
      await client.from('users').update({
        'ai_name': state.companionName.trim(),
        'onboarded': true,
      }).eq('google_uid', user.id);

      // Hydrate profile provider
      _ref.read(userProfileProvider.notifier).updateProfile(
        UserProfile(
          id: user.id,
          email: user.email ?? '',
          displayName: user.userMetadata?['full_name'] ?? '',
          avatarUrl: user.userMetadata?['avatar_url'] ?? '',
          aiName: state.companionName.trim(),
          archetype: state.archetype ?? '',
          onboarded: true,
        ),
      );
      
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: "Saving profile failed: ${e.toString()}",
      );
      rethrow;
    }
  }
}

final onboardingProvider = StateNotifierProvider<OnboardingNotifier, OnboardingState>((ref) {
  return OnboardingNotifier(ref);
});

// Manage user profile globally
class UserProfileNotifier extends StateNotifier<UserProfile> {
  UserProfileNotifier() : super(UserProfile(
    id: '',
    email: '',
    displayName: '',
    avatarUrl: '',
    aiName: 'Lumina',
    archetype: '',
    onboarded: false,
  )) {
    _loadProfileFromSession();
  }

  void _loadProfileFromSession() async {
    final client = supabase.Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user != null) {
      try {
        final data = await client.from('users').select().eq('google_uid', user.id).maybeSingle();
        if (data != null) {
          state = UserProfile.fromJson(data);
        }
      } catch (e) {
        debugPrint("Error fetching user profile: $e");
      }
    }
  }

  void updateProfile(UserProfile profile) {
    state = profile;
  }
}

final userProfileProvider = StateNotifierProvider<UserProfileNotifier, UserProfile>((ref) {
  return UserProfileNotifier();
});
