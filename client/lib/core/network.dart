import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final dioProvider = Provider<Dio>((ref) {
  final baseUrl = dotenv.env['BACKEND_BASE_URL'] ?? 'http://10.0.2.2:8000';
  
  // Clean trailing dot if present
  final cleanBaseUrl = baseUrl.endsWith('/') 
      ? baseUrl.substring(0, baseUrl.length - 1) 
      : baseUrl;

  final dio = Dio(BaseOptions(
    baseUrl: cleanBaseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 15),
    headers: {
      'Content-Type': 'application/json',
    },
  ));

  // Auto-inject Supabase Access Token JWT on all requests
  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) async {
      var session = Supabase.instance.client.auth.currentSession;
      if (session != null) {
        if (session.isExpired) {
          try {
            final response = await Supabase.instance.client.auth.refreshSession();
            session = response.session;
          } catch (e) {
            // Ignore refresh errors and proceed with the expired session/token
            // so the backend can handle the authorization failure properly
          }
        }
        if (session != null) {
          options.headers['Authorization'] = 'Bearer ${session.accessToken}';
        }
      }
      return handler.next(options);
    },
  ));

  return dio;
});
