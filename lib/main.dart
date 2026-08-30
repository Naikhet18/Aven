import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:khao_piyo_pos/core/config/app_router.dart';
import 'package:khao_piyo_pos/core/config/env.dart';
import 'package:khao_piyo_pos/core/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:khao_piyo_pos/shared/providers/global_providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Env.assertConfigured();

  await Supabase.initialize(
    url: Env.supabaseUrl,
    publishableKey: Env.supabaseAnonKey,
  );

  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const KhaoPiyoApp(),
    ),
  );
}

class KhaoPiyoApp extends ConsumerStatefulWidget {
  const KhaoPiyoApp({super.key});

  @override
  ConsumerState<KhaoPiyoApp> createState() => _KhaoPiyoAppState();
}

class _KhaoPiyoAppState extends ConsumerState<KhaoPiyoApp> {
  @override
  void initState() {
    super.initState();
    // The initial boot sequence (registering sync handlers, starting the
    // engine if a session already exists) lives in SplashScreen, the app's
    // first screen. This listener only handles *later* changes for the rest
    // of the app's lifetime -- logging in, joining a business, logging out.
    ref.listenManual<String?>(currentBusinessIdProvider, (previous, next) {
      final syncService = ref.read(syncServiceProvider);
      if (next != null) {
        syncService.start(next);
      } else {
        syncService.stop();
      }
    });
  }

  @override
  void dispose() {
    ref.read(syncServiceProvider).stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'KhaoPiyo POS',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
