import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final _supabase = Supabase.instance.client;

  Future<AuthResponse> signInWithGoogle() async {
    final clientId = dotenv.env['GOOGLE_CLIENT_ID'];
    if (clientId == null || clientId.isEmpty) {
      throw Exception('GOOGLE_CLIENT_ID is not configured in .env file');
    }
    
    final GoogleSignIn googleSignIn = GoogleSignIn(
      clientId: kIsWeb ? clientId : null,
      serverClientId: clientId,
      scopes: ['email', 'profile'],
    );

    final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
    if (googleUser == null) {
      throw Exception('Google Sign-In was cancelled by user');
    }

    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    final idToken = googleAuth.idToken;
    final accessToken = googleAuth.accessToken;

    if (idToken == null) {
      throw Exception('No ID Token found from Google Sign-In.');
    }

    return await _supabase.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: accessToken,
    );
  }

  Future<AuthResponse> signInAnonymously() async {
    return await _supabase.auth.signInAnonymously();
  }

  Future<void> signOut() async {
    final clientId = dotenv.env['GOOGLE_CLIENT_ID'];
    final GoogleSignIn googleSignIn = GoogleSignIn(
      clientId: kIsWeb ? clientId : null,
      serverClientId: clientId,
    );
    
    try {
      if (await googleSignIn.isSignedIn()) {
        await googleSignIn.signOut();
      }
    } catch (e) {
      debugPrint('Error signing out from Google: $e');
    }
    
    await _supabase.auth.signOut();
  }

  Session? get currentSession => _supabase.auth.currentSession;
  User? get currentUser => _supabase.auth.currentUser;
}
