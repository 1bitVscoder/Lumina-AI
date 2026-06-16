import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/router.dart';
import 'core/theme.dart';
import 'features/settings/providers/settings_provider.dart';
import 'core/providers/update_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  try {
    await dotenv.load(fileName: "assets/.env");
  } catch (e) {
    debugPrint("Warning: Could not load .env file: $e");
  }

  // Initialize Supabase
  final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';
  
  // Strip trailing dot from Supabase URL if present (prevents handshake errors)
  final cleanUrl = supabaseUrl.endsWith('.') 
      ? supabaseUrl.substring(0, supabaseUrl.length - 1) 
      : supabaseUrl;

  if (cleanUrl.isNotEmpty && supabaseAnonKey.isNotEmpty) {
    try {
      await Supabase.initialize(
        url: cleanUrl,
        anonKey: supabaseAnonKey, // ignore: deprecated_member_use
      );
    } catch (e) {
      debugPrint("Error initializing Supabase: $e");
    }
  } else {
    debugPrint("Warning: Supabase credentials are missing or empty in .env");
  }

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(updateProvider.notifier).checkForUpdates();
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final settings = ref.watch(settingsProvider);

    return MaterialApp.router(
      title: 'Lumina',
      theme: getLuminaTheme(context, false),
      darkTheme: getLuminaTheme(context, true),
      themeMode: settings.themeMode,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
