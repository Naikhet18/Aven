import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:khao_piyo_pos/core/theme/app_theme.dart';
import 'package:khao_piyo_pos/shared/providers/global_providers.dart';

/// The app's boot screen. Does real work (checks the session, warms the
/// sync registry) rather than just being a timed animation -- if everything
/// is already cached, it moves on quickly; a floor display time keeps it
/// from feeling like a flash on a fast device either way.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _scale = Tween<double>(begin: 0.85, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _controller.forward();
    _boot();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _boot() async {
    final stopwatch = Stopwatch()..start();

    // Wires every repository's pull-merge handler into the sync engine --
    // must happen before the engine is ever started (see main.dart, which
    // used to do this; the splash screen is now the single place app boot
    // logic lives).
    ref.read(syncRegistryProvider);

    final prefs = ref.read(sharedPreferencesProvider);
    var businessId = prefs.getString('business_id');

    if (businessId != null && Supabase.instance.client.auth.currentSession == null) {
      await prefs.remove('business_id');
      await prefs.remove('staff_role');
      businessId = null;
    }

    if (businessId != null) {
      ref.read(currentBusinessIdProvider.notifier).state = businessId;
      ref.read(syncServiceProvider).start(businessId);
    }

    const floor = Duration(milliseconds: 450);
    final elapsed = stopwatch.elapsed;
    if (elapsed < floor) {
      await Future.delayed(floor - elapsed);
    }

    if (!mounted) return;
    context.go(businessId != null ? '/' : '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: Center(
        child: FadeTransition(
          opacity: _fade,
          child: ScaleTransition(
            scale: _scale,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 44),
                ),
                const SizedBox(height: 20),
                const Text(
                  'KhaoPiyo',
                  style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Loading your restaurant…',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
