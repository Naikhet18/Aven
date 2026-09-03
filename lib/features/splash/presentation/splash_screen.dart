import 'dart:math' as math;

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
/// way. Every effect here (the drawn ring, the shimmer sweep, the loading
/// dots) is a plain Flutter AnimationController/CustomPainter -- no Lottie,
/// no Rive, no extra asset weight, in keeping with the app staying light.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with TickerProviderStateMixin {
  late final AnimationController _entrance;
  late final AnimationController _loop;
  late final Animation<double> _ringProgress;
  late final Animation<double> _logoFade;
  late final Animation<double> _logoScale;
  late final Animation<double> _textSlide;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));
    _ringProgress = CurvedAnimation(parent: _entrance, curve: const Interval(0, 0.55, curve: Curves.easeOutCubic));
    _logoFade = CurvedAnimation(parent: _entrance, curve: const Interval(0.15, 0.6, curve: Curves.easeOut));
    _logoScale = Tween<double>(begin: 0.7, end: 1.0).animate(CurvedAnimation(parent: _entrance, curve: const Interval(0.15, 0.65, curve: Curves.easeOutBack)));
    _textSlide = CurvedAnimation(parent: _entrance, curve: const Interval(0.45, 0.85, curve: Curves.easeOut));

    // A slow, continuous loop drives the shimmer sweep and dot pulse for as
    // long as boot takes.
    _loop = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..repeat();

    _entrance.forward();
    _boot();
  }

  @override
  void dispose() {
    _entrance.dispose();
    _loop.dispose();
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
    const floor = Duration(milliseconds: 1000);
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
            colors: [AppTheme.primaryColor, Color.lerp(AppTheme.primaryColor, Colors.black, 0.4)!],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: Listenable.merge([_entrance, _loop]),
                builder: (context, _) {
                  return FadeTransition(
                    opacity: _logoFade,
                    child: ScaleTransition(
                      scale: _logoScale,
                      child: SizedBox(
                        width: 108,
                        height: 108,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CustomPaint(
                              size: const Size(108, 108),
                              painter: _RingPainter(progress: _ringProgress.value, color: Colors.white),
                            ),
                            Container(
                              width: 76,
                              height: 76,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                              ),
                              child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 38),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 28),
              SlideTransition(
                position: Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(_textSlide),
                child: FadeTransition(
                  opacity: _textSlide,
                  child: AnimatedBuilder(
                    animation: _loop,
                    builder: (context, _) => _ShimmerText(
                      text: 'KhaoPiyo',
                      sweep: _loop.value,
                      style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              FadeTransition(
                opacity: _textSlide,
                child: Text(
                  'Loading your restaurant…',
                  style: GoogleFonts.outfit(color: Colors.white.withValues(alpha: 0.7), fontSize: 14),
                ),
              ),
              const SizedBox(height: 36),
              FadeTransition(
                opacity: _textSlide,
                child: _LoadingDots(controller: _loop),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Draws a ring that sweeps in clockwise from the top, like a progress
/// indicator that resolves into the logo's frame.
class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  const _RingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()
      ..color = color.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect.deflate(1.5), -math.pi / 2, progress * 2 * math.pi, false, paint);
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) => oldDelegate.progress != progress;
}

/// A light sweep across the wordmark, the same trick used for skeleton
/// shimmer -- a ShaderMask with an animated gradient, no extra package.
class _ShimmerText extends StatelessWidget {
  final String text;
  final double sweep;
  final TextStyle style;
  const _ShimmerText({required this.text, required this.sweep, required this.style});

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) {
        final dx = bounds.width * (sweep * 2.4 - 0.7);
        return LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: const [Colors.white, Colors.white70, Colors.white],
          stops: const [0.35, 0.5, 0.65],
          transform: _SlideGradient(dx),
        ).createShader(bounds);
      },
      child: Text(text, style: style.copyWith(color: Colors.white)),
    );
  }
}

class _SlideGradient extends GradientTransform {
  final double dx;
  const _SlideGradient(this.dx);
  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) => Matrix4.translationValues(dx, 0, 0);
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
            final t = (controller.value - i * 0.18) % 1.0;
            final opacity = (0.3 + 0.7 * (0.5 + 0.5 * (t < 0.5 ? t * 2 : (1 - t) * 2))).clamp(0.3, 1.0);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Opacity(
                opacity: opacity,
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
