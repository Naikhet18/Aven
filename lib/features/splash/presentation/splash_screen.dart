import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:khao_piyo_pos/core/theme/app_theme.dart';
import 'package:khao_piyo_pos/features/auth/providers/staff_role_provider.dart';
import 'package:khao_piyo_pos/shared/providers/global_providers.dart';

/// The app's boot screen. Does real work (checks the session, warms the
/// sync registry) rather than just being a timed animation -- if everything
/// is already cached, it moves on quickly; a floor display time keeps it
/// from feeling like a blink-and-you-miss-it flash on a fast device either
/// way, and the loading dots keep it feeling alive if boot takes longer
/// (e.g. a slow network for the session check).
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
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat();
    _fade = CurvedAnimation(parent: _controller, curve: const Interval(0, 0.35, curve: Curves.easeOut));
    _scale = Tween<double>(begin: 0.85, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: const Interval(0, 0.45, curve: Curves.easeOutBack)));
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

    String? role;
    if (businessId != null) {
      role = prefs.getString('staff_role');
      ref.read(currentBusinessIdProvider.notifier).state = businessId;
      ref.read(currentStaffRoleProvider.notifier).state = role;
      ref.read(syncServiceProvider).start(businessId);
    }

    // Long enough to read as a deliberate, premium beat rather than a
    // flicker, short enough not to feel slow.
    const floor = Duration(milliseconds: 800);
    final elapsed = stopwatch.elapsed;
    if (elapsed < floor) {
      await Future.delayed(floor - elapsed);
    }

    if (!mounted) return;
    context.go(businessId != null ? homeRouteForRole(role) : '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.primaryColor, Color.lerp(AppTheme.primaryColor, Colors.black, 0.35)!],
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fade,
            child: ScaleTransition(
              scale: _scale,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                    ),
                    child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 46),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'KhaoPiyo',
                    style: GoogleFonts.outfit(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Loading your restaurant…',
                    style: GoogleFonts.outfit(color: Colors.white.withValues(alpha: 0.75), fontSize: 14),
                  ),
                  const SizedBox(height: 32),
                  _LoadingDots(controller: _controller),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoadingDots extends StatelessWidget {
  final Animation<double> controller;
  const _LoadingDots({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final t = (controller.value - i * 0.2) % 1.0;
            final opacity = 0.3 + 0.7 * (0.5 + 0.5 * (t < 0.5 ? t * 2 : (1 - t) * 2));
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Opacity(
                opacity: opacity.clamp(0.3, 1.0),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
