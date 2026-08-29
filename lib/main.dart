import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:khao_piyo_pos/core/config/app_router.dart';
import 'package:khao_piyo_pos/core/theme/app_theme.dart';
import 'package:khao_piyo_pos/core/sync/sync_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:khao_piyo_pos/shared/providers/global_providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Supabase.initialize(
      url: const String.fromEnvironment('SUPABASE_URL', defaultValue: 'http://127.0.0.1:54321'),
      publishableKey: const String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRlZmF1bHQiLCJyb2xlIjoiYW5vbiIsImlhdCI6MTcyNDgzMjc3NiwiZXhwIjoyMDQwMDMyNzc2fQ.y2p-r7o_vU6O1-C8g7BwB8F2ZkX7X7G4Yx1x-3U7aDk'), // Default local anon key
    );
  } catch (e) {
    debugPrint('Supabase initialization failed: $e');
  }

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
    // Start the sync service
    ref.read(syncServiceProvider).start();
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
