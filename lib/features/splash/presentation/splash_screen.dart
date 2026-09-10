import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter/services.dart';
import 'package:khao_piyo_pos/shared/providers/global_providers.dart';
import 'package:khao_piyo_pos/features/auth/providers/staff_role_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});
  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  String? _businessId;
  String? _role;
  bool _isInitComplete = false;
  bool _transitioned = false;

  late final VideoPlayerController _videoController;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    
    _videoController = VideoPlayerController.asset('assets/videos/final.mp4')
      ..initialize().then((_) {
        if (mounted) {
          setState(() {});
          _videoController.play();
        }
      });

    _videoController.addListener(() {
      if (_videoController.value.isInitialized && 
          !_videoController.value.isPlaying && 
          _videoController.value.position >= _videoController.value.duration) {
         
         if (_isInitComplete && !_transitioned) {
            _transitioned = true;
            _transitionToApp();
         }
      }
    });

    _performBackgroundInit();
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _videoController.dispose();
    super.dispose();
  }

  Future<void> _performBackgroundInit() async {
    ref.read(syncRegistryProvider);
    final prefs = ref.read(sharedPreferencesProvider);
    _businessId = prefs.getString('business_id');

    if (_businessId != null && Supabase.instance.client.auth.currentSession == null) {
      await prefs.remove('business_id');
      await prefs.remove('staff_role');
      _businessId = null;
    }

    if (_businessId != null) {
      _role = prefs.getString('staff_role');
      ref.read(currentBusinessIdProvider.notifier).state = _businessId;
      ref.read(currentStaffRoleProvider.notifier).state = _role;
      ref.read(syncServiceProvider).start(_businessId!);
    }
    
    _isInitComplete = true;
  }

  void _transitionToApp() {
    if (!mounted) return;
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    
    if (_businessId != null && _role != null) {
      switch (_role!.toUpperCase()) {
        case 'ADMIN':
          context.go('/');
          break;
        case 'WAITER':
          context.go('/new-order');
          break;
        case 'KITCHEN':
          context.go('/kitchen');
          break;
        default:
          context.go('/');
      }
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000), // Pure black
      body: SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.fill, // Fill screen completely on all devices, ignore aspect ratio if needed
          child: SizedBox(
            width: _videoController.value.isInitialized 
                ? _videoController.value.size.width 
                : 1080,
            height: _videoController.value.isInitialized 
                ? _videoController.value.size.height 
                : 2400,
            child: _videoController.value.isInitialized
                ? VideoPlayer(_videoController)
                : Image.asset(
                    'assets/images/splash_first_frame.jpg',
                    fit: BoxFit.fill, // Must match FittedBox to be exact
                  ),
          ),
        ),
      ),
    );
  }
}
