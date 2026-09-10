import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: AvenApp(prefs: prefs),
    ),
  );
}

class AvenApp extends ConsumerStatefulWidget {
  final SharedPreferences prefs;
  const AvenApp({super.key, required this.prefs});

  @override
  ConsumerState<AvenApp> createState() => _AvenAppState();
}

class _AvenAppState extends ConsumerState<AvenApp> {
  // Built once (not per-build) using the SharedPreferences instance main()
  // already loaded, so the router's redirect can read it synchronously --
  // see the comment on buildAppRouter for why that matters.
  late final GoRouter _router = buildAppRouter(widget.prefs);

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
      title: 'Aven POS',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}
